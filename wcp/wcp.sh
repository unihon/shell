#!/bin/bash

#===================================
#	Describe:
#	Easy to copy files to wsl
#------------------------------------
#	Usage:
#	./wcp.sh "C:\xx\xx"
#	./wcp.sh "C:\xx\x x"
#------------------------------------
#	Author:
#	https://unihon.github.io/
#------------------------------------
#	Date:
#	2018-12-27
#	Update:
#	2019-02-18
#===================================

if [ "$1" ==  "" ];then
	echo "No path."
	exit
fi

uri=$(echo $1|sed -e 's/\\/\//g' -e 's/\ /\\ /g' -e 's/^\(.\):\(.*\)$/\/mnt\/\l\1\2/g')

echo $uri|xargs -i cp -r {} .
echo "Finish."
