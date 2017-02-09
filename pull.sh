#!/bin/bash

git push origin master

asciidoctor mysql-notes.adoc

temp_folder="/tmp/mysql-notes-`date  "+%Y%m%d%H%M%S"`"

mkdir $temp_folder

mv mysql-notes.html $temp_folder/index.html
cp -R ./images $temp_folder

git checkout gh-pages

rm -rf *

mv $temp_folder/* .

git add .

git commit -am "update pages"

git push origin gh-pages

rm -rf $temp_folder

git checkout master
