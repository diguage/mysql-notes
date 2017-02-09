#!/bin/bash

git push origin master

asciidoctor mysql-notes.adoc

temp_folder="/tmp/mysql-notes-`date  "+%Y%m%d%H%M%S"`"

mkdir $temp_folder

mv mysql-notes.html $temp_folder/index.html
cp -R ./images $temp_folder

git checkout deploy

rm -rf *

mv $temp_folder/* .

git add .

git commit -am "ready to deploy"

git push origin deploy

rsync -avz . deployer@120.92.74.139:/home/deployer/diguage.com/notes/mysql

rm -rf $temp_folder

git checkout master
