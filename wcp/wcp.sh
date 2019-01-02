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
#	2019-01-02
#===================================

str=$1

tmp=${str//\\/\/}
row=${tmp//\ /\\ }

typeset -l partition=$(echo $row|cut -d ":" -f1)
uri=$(echo $row|cut -d ":" -f2)
uri_l="/mnt/"${partition}${uri}

echo $uri_l|xargs -i cp -r {} .
