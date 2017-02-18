#!/bin/bash

html_file_name=mysql-notes.html
style_file_name=styles.css

# 解决 Mac 与 Linux 中 sed 处理不统一的问题
gsed=`which sed`
if [[ `uname` == Darwin* ]]
then
  gsed=`which gsed`
fi

# 确保 cssnano 命令被安装
cssnano=`which cssnano`
if [ ! -n `which cssnano` ]; then
  npm install cssnano-cli --g --registry=https://registry.npm.taobao.org
  cssnano=`which cssnano`
fi

# 确保 html-minifier 命令被安装
htmlminifier=`which html-minifier`
if [ ! -n `which html-minifier` ]; then
  npm install html-minifier -g --registry=https://registry.npm.taobao.org
  htmlminifier=`which html-minifier`
fi

git push origin master

asciidoctor mysql-notes.adoc -o $html_file_name

temp_folder="/tmp/mysql-notes-`date  "+%Y%m%d%H%M%S"`"

mkdir $temp_folder

mv $html_file_name $temp_folder
cp -R ./images $temp_folder
cp html-minifier.config.json $temp_folder

git checkout deploy

rm -rf *

mv $temp_folder/* .

rm -rf $style_file_name
touch  $style_file_name

## 声明一个数字变量，可以带引号
declare -a start_lines=(`awk '/<style>/{print NR}' $html_file_name`)
declare -a end_lines=(`awk '/<\/style>/{print NR}' $html_file_name`)

# 获取数组长度
arraylength=${#start_lines[@]}

# 遍历数组，获取下标以及各个元素
for (( i=0; i<${arraylength}; i++ ));
do
  $gsed -n "${start_lines[$i]}, ${end_lines[$i]}p" $html_file_name | grep -v "style>" | grep -v "/\*" 1>> $style_file_name
  # cat $html_file_name | head -n ${end_lines[$i]} | tail -n +${start_lines[$i]} | grep -v "style>" | grep -v "/\*" 1>> $style_file_name
done

# 遍历数组，删除样式
for (( i=${arraylength}-1; i>=0; i-- ));
do
  $gsed -i "${start_lines[$i]}, ${end_lines[$i]}d" $html_file_name
done

# 压缩 CSS
$cssnano $style_file_name $style_file_name

# 将样式文件添加到 HTML 中
$gsed -i "s/\(<\/head>\)/<link rel=\"stylesheet\" href=\".\/${style_file_name}\">\n\1/" $html_file_name

# 替换 Font Awesome
$gsed -i "s/https:\/\/cdnjs.cloudflare.com\/ajax\/libs/http:\/\/cdn.bootcss.com/" $html_file_name

# 替换 Google Fonts
$gsed -i "s/https:\/\/fonts.googleapis.com/http:\/\/fonts.proxy.ustclug.org/" $html_file_name

$htmlminifier -c html-minifier.config.json $html_file_name -o index.html

git add .

git commit -am "ready to deploy"

git push origin deploy

rsync -avz . deployer@120.92.74.139:/home/deployer/diguage.com/notes/mysql

rm -rf $temp_folder

git checkout master
