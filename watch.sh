#!/bin/bash
#
# 编辑脚本，监控变化，编译

root_path=`pwd`

if [ ! -n `which fswatch` ]; then
  brew install fswatch
fi

# 不生效？
httpd 1>/dev/null 2>&1 &

fswatch -o ${root_path}/*.adoc | xargs -n1  ${root_path}/deploy.sh