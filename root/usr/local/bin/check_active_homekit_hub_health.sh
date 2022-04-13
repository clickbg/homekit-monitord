#!/bin/bash
# Author: Daniel Zhelev @ https://zhelev.biz

source /etc/environment

TIME_AGO="${1:-10min}"
DATE=$(date --iso-8601=seconds -d "$TIME_AGO ago")


cat $LOGFILE | jq -re --arg date "$DATE" 'select ((.time_iso8601 >= $date))' > /dev/null
if [[ $? -eq 0 ]]; then
 LAST_HUB_JSON=$(tail -1 $LOGFILE | jq -rec '({remote_addr, time_iso8601})')
 ACTIVE_HUB_IP=$(echo $LAST_HUB_JSON | jq -re '.remote_addr')
 LAST_EXPORTED_STATE=$(echo $LAST_HUB_JSON | jq -re '.time_iso8601')
 echo "$(date +%Y-%m-%d\ %H:%M:%S) [SUCCESS] HomeKit Active Hub [$ACTIVE_HUB_IP] successfully reported state on [$LAST_EXPORTED_STATE] which is less than [$TIME_AGO] ago"
 exit 0
else
 LAST_HUB_JSON=$(tail -1 $LOGFILE | jq -rec '({remote_addr, time_iso8601})')
 ACTIVE_HUB_IP=$(echo $LAST_HUB_JSON | jq -re '.remote_addr')
 LAST_EXPORTED_STATE=$(echo $LAST_HUB_JSON | jq -re '.time_iso8601')
 echo "$(date +%Y-%m-%d\ %H:%M:%S) [FAILED] HomeKit Active Hub [$ACTIVE_HUB_IP] last reported state on [$LAST_EXPORTED_STATE] which is more than [$TIME_AGO] ago"
 exit 1
fi
