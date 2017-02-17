#!/bin/bash

html_file_name=mysql-notes.html
style_file_name=styles.css

gsed=`which sed`
if [[ `uname` == Darwin* ]]
then
    gsed=`which gsed`
fi

rm -rf $style_file_name
touch  $style_file_name

## 声明一个数字变量，可以带引号
declare -a start_lines=(`awk '/<style>/{print NR}' $html_file_name`)
declare -a end_lines=(`awk '/<\/style>/{print NR}' mysql-notes.html`)

# 获取数组长度
arraylength=${#start_lines[@]}

# 遍历数组，获取下标以及各个元素
for (( i=0; i<${arraylength}; i++ ));
do
  cat $html_file_name | head -n ${end_lines[$i]} | tail -n +${start_lines[$i]} | grep -v "style>" | grep -v "/\*" 1>> $style_file_name
done

# 遍历数组，获取下标以及各个元素
for (( i=${arraylength}-1; i>=0; i-- ));
do
  $gsed -i "${start_lines[$i]}, ${end_lines[$i]}d" $html_file_name
done

# 将样式文件添加到 HTML 中
$gsed -i "s/\(<\/head>\)/<link rel=\"stylesheet\" href=\".\/${style_file_name}\">\n\1/" $html_file_name

# 替换 Font Awesome
$gsed -i "s/https:\/\/cdnjs.cloudflare.com\/ajax\/libs/http:\/\/cdn.bootcss.com/" $html_file_name

# 替换 Google Fonts
$gsed -i "s/https:\/\/fonts.googleapis.com/http:\/\/fonts.proxy.ustclug.org/" $html_file_name
