#!/bin/sh



ulimit -c unlimited 
export ROOT=$(cd `dirname $0`; pwd)
export DAEMON=false


##查找skynet的根目录
if [ ! $SKYNET ]; then  
  echo "can't find skynet path!"
  SKYNET=/data/skynet
fi 

##生成 run目录
if [ ! -d "$ROOT/run" ]; then 
	mkdir "$ROOT/run"
fi 

while getopts "dk" arg
do
	case $arg in
		d)
			export DAEMON=true
			;;
		k)
			kill `cat $ROOT/run/skynet.pid`
			rm $ROOT/run/skynet.pid
			exit 0;
			;;
	esac
done

$SKYNET/skynet $ROOT/etc/config.lua
