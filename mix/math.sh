#!/bin/bash

check(){
	expr $1 + 0 &> /dev/null
	if [ $? != 0 ]; then
		echo "please input a number."
		exit
	fi
}

echo  -n "input first number: "
read a
check $a

echo  -n "input second number: "
read b
check $b

echo "$a + $b = $(( a + b ))"
echo "$a - $b = $(( a - b ))"
echo "$a * $b = $(( a * b ))"
echo "$a / $b = $(( a / b ))"
