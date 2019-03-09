#!/usr/bin/env bash

# if sourse data is null, means that the sourse is localhost.
SOURSE_USER=""
SOURSE_HOST=""
SOURSE="$2"

# remote host data.
REMOTE_USER=""
REMOTE_HOST=""
DESTINATION="$3"

if [ "$1" == "-s" ]
then
	if [ "$SOURSE_USER" == "" ]
	then
		scp -r "${SOURSE}" "${REMOTE_USER}"@"${REMOTE_HOST}":"${DESTINATION}"
	else
		scp -r "${SOURSE_USER}":"${SOURSE_HOST}":"${SOURSE}" "${REMOTE_USER}"@"${REMOTE_HOST}":"${DESTINATION}"
	fi

elif [ "$1" == "-g" ]
then
	scp -r "${REMOTE_USER}"@"${REMOTE_HOST}":"${SOURSE}" "${DESTINATION}" 
else
	echo "ecp <-s|-g> sourse destination."
fi

