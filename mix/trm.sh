#!/bin/bash

# rm protection list

LIST=("\." "bin" "dev" "home" "mnt")

if [ "$1" == "/" ]; then
	echo "Can't rm '${1}'"	
	exit
fi

if [ $(pwd) == "/"  ]; then
	KEY="/?"
else
	KEY="/"
fi

for i in ${LIST[@]}
do
	if echo $1 | egrep -q "^${KEY}${i}" ; then
		echo ">trm: can't rm '${1}'"	
		exit
	fi
done

# rm -i $1

# test
if [ -e "$1" ]; then
	echo ">trm: you will rm '${1}'"
else
	echo ">trm: don't exist '${1}'"
fi
