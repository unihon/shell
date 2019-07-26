#!/bin/bash

check(){
	expr $1 + 0 &> /dev/null
	if [ $? != 0 ]; then
		echo "please input a number."
		exit
	fi
}

echo  -n "input a number: "
read a
check $a

tmp=0
for((i=1;i<=$a;i++));do
	tmp=$(( tmp + i ))
done;

if [ $a -eq 1 ]; then
	echo "$a = $tmp"
else
	echo "1+..+$a = $tmp"
fi
