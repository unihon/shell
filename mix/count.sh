#!/bin/bash

check(){
	expr $1 + 0 &> /dev/null
	if [ $? != 0 ]; then
		echo "please input a number."
		exit
	fi
}

echo  -n "input first number[ > 10 and < 500]: "
read a
check $a
if [ $a -lt 10 -o $a -gt 500 ]; then
	echo "$a is less then 10 or great then 10."
	exit
fi

echo  -n "input second number[ > 10 and < 500]: "
read b
check $b
if [ $b -lt 10 -o $b -gt 500 ]; then
	echo "$b is less then 10 or great then 10."
	exit
fi

echo "$a + $b = $(( a + b ))"
