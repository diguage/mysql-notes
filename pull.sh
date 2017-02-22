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
mv ./styles $temp_folder
cp -R ./images $temp_folder
cp html-minifier.config.json $temp_folder

git checkout deploy

rm -rf *

mv $temp_folder/* .

cd ./styles

for f in `ls .`
do
  # 压缩 CSS
  $cssnano $f $f
done

cd ..

# 替换 Font Awesome，使用内置功能，不需要手动搞了。
# $gsed -i "s/https:\/\/cdnjs.cloudflare.com\/ajax\/libs/http:\/\/cdn.bootcss.com/" $html_file_name

# 替换 Google Fonts
$gsed -i "s/https:\/\/fonts.googleapis.com/\/\/fonts.proxy.ustclug.org/" $html_file_name

$htmlminifier -c html-minifier.config.json $html_file_name -o index.html

rm -rf $html_file_name

git add .

git commit -am "ready to deploy"

git push origin deploy

rsync -avz . deployer@120.92.74.139:/home/deployer/diguage.com/notes/mysql

rm -rf $temp_folder

git checkout master
