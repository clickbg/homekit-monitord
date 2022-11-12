#!/usr/bin/env bash
# Author: Daniel Zhelev @ https://zhelev.biz

#################################### Begin config

# Tools that we need
MQTT_CLIENT=$(which mosquitto_pub)
JQ=$(which jq)
LOG_OUT="/proc/1/fd/1"

#################################### End config

#################################### Get Docker config
source /etc/environment
#################################### End get Docker config

#################################### Begin func definition
# Error exit function
die()
{
   echo -e "$@" | tee $LOG_OUT
   exit 1
}

log()
{
   echo -e "$@" | tee $LOG_OUT
}

check_mqtt_connection()
{
 $MQTT_CLIENT --insecure -L $MQTT_ADDR/test-$RANDOM -m 'ping'
 return $?
}

get_last_active_hub()
{
 $JQ -re '.remote_addr' $LOGFILE | tail -1
}

restart_last_active_hub()
{
 local CUR_ACTIVE_HUB=$1
 local MQTT_ID_ACTIVE_HUB=$2
 local EXIT=0
 # Stop the power via our smart outlet
  OUT=$($MQTT_CLIENT --insecure -L $MQTT_ADDR/$MQTT_ID_ACTIVE_HUB/set -m '{ "state": "OFF" }' 2>&1)
  [[ $? -ne 0 ]] && let "EXIT++"
  [[ ! -z $OUT ]] && let "EXIT++"
  # Wait 120s to be sure all components are properly restarted
  sleep 120
  # Start the power to the smart outlet
  OUT=$($MQTT_CLIENT --insecure -L $MQTT_ADDR/$MQTT_ID_ACTIVE_HUB/set -m '{ "state": "ON" }' 2>&1)
  [[ $? -ne 0 ]] && let "EXIT++"
  [[ ! -z $OUT ]] && let "EXIT++"
  # Check if the restart was successful. If it failed, terminate the execution and produce error.
   if [[ $EXIT -eq 0 ]]
    then
     log "$(date +%Y-%m-%d\ %H:%M:%S) [SUCCESS] Active HomeKit Hub $CUR_ACTIVE_HUB : RESTARTED"
     # Wait for new active hub to be elected. We are waiting 10*60s (10mins) since our HC are every 5mins.
     COUNT=0
      while [ "$COUNT" -le 10 ]
       do
        sleep 60
        # Check if the hub was elected, if not loop again
        NEW_ACTIVE_HUB=$(get_last_active_hub)
        if [[ "$CUR_ACTIVE_HUB" == "$NEW_ACTIVE_HUB" ]]
         then
          let "COUNT++"
          continue
         else
          log "$(date +%Y-%m-%d\ %H:%M:%S) [SUCCESS] New Active HomeKit Hub Elected: $NEW_ACTIVE_HUB"
          return 0
         fi
        done
    else
     log "$(date +%Y-%m-%d\ %H:%M:%S) [FAILED] Active HomeKit Hub $CUR_ACTIVE_HUB : RESTART FAILED"
     return 1
    fi
}

#################################### End func definition

#################################### Begin execution

# Check our tools are present
[[ ! -f $LOGFILE ]] && die "$(date +%Y-%m-%d\ %H:%M:%S) Log file $LOGFILE not found."
[[ -z $MQTT_CLIENT ]] && die "$(date +%Y-%m-%d\ %H:%M:%S) mosquitto-clients not found."
[[ -z $JQ ]] && die "$(date +%Y-%m-%d\ %H:%M:%S) jq not found."

# Verify that MQTT is active
check_mqtt_connection
[[ $? -ne 0 ]] && die "$(date +%Y-%m-%d\ %H:%M:%S) [FAILED] Failed to connect to MQTT server at [$MQTT_ADDR]"

# Match the hubs to their smart plug IDs
ACTIVE_HUB=$(get_last_active_hub)
[[ -z $ACTIVE_HUB ]] && die "$(date +%Y-%m-%d\ %H:%M:%S) [FAILED] Failed to retrive the currently active HomeKit hub from log file: $LOGFILE"
echo $HOMEKIT_HUBS | grep -q "$ACTIVE_HUB" || die "$(date +%Y-%m-%d\ %H:%M:%S) Hub: $ACTIVE_HUB not defined in the script. Known hubs: $HOMEKIT_HUBS"
for HUB in $HOMEKIT_HUBS
 do
     HUB_IP="$(echo $HUB | cut -d ":" -f1)"
     HUB_ID="$(echo $HUB | cut -d ":" -f2 -s)"
     if [[ "$ACTIVE_HUB" == "$HUB_IP" ]]
     then
         [[ -z "$HUB_ID" ]] && die "$(date +%Y-%m-%d\ %H:%M:%S) Hub: $ACTIVE_HUB no MQTT ID provided for this hub, failed to restart."
         restart_last_active_hub $HUB_IP $HUB_ID
         exit $?
     fi
 done
exit 1
