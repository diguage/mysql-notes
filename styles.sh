#!/bin/bash

html_file_name=mysql-notes.html
out_file_name=mysql-notes.html

while getopts "i:o:" arg #选项后面的冒号表示该选项需要参数
do
    case $arg in
        i)
        html_file_name=$OPTARG
			;;
        o)
        out_file_name=$OPTARG
			;;
    esac
done

style_file_name=styles.css

gsed=`which sed`
if [[ `uname` == Darwin* ]]
then
  gsed=`which gsed`
fi

cssnano=`which cssnano`
if [ ! -n `which cssnano` ]; then
  npm install cssnano-cli --global
  cssnano=`which cssnano`
fi

rm -rf $html_file_name
rm -rf $style_file_name

asciidoctor mysql-notes.adoc -o $html_file_name

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
