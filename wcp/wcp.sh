#!/bin/bash

#===================================
#	Describe:
#	Easy to copy files to wsl
#------------------------------------
#	Usage:
#	./wcp.sh "C:/xx/xx"
#------------------------------------
#	Author:
#	https://unihon.github.io/
#------------------------------------
#	Update:
#	2018-12-27
#===================================

str=$1

row=${str//\\/\/}
typeset -l partition=$(echo $row|cut -d ":" -f1)
uri=$(echo $row|cut -d ":" -f2)
uri_l="/mnt/"${partition}${uri}

cp -r $uri_l .
