#!/bin/bash
# Author: Daniel Zhelev @ https://zhelev.biz

source /etc/environment

TIME_AGO=$1
DATE=$(date --iso-8601=seconds -d "$TIME_AGO ago")

jq -re --arg date "$DATE" 'select ((.time_iso8601 >= $date))' $LOGFILE
exit $?
