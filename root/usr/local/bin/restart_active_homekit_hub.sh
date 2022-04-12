#!/usr/bin/env bash
# Author: Daniel Zhelev @ https://zhelev.biz

#################################### Begin config

# Tools that we need
COAP_CLIENT=$(which coap-client-gnutls)
JQ=$(which jq)

#################################### End config

#################################### Get Docker config
source /etc/environment
#################################### End get Docker config

#################################### Begin func definition
# Error exit function
die()
{
   echo -e "$@" >&2
   exit 1
}

get_last_active_hub()
{
 jq -re '.remote_addr' $LOGFILE | tail -1
 [[ $? -ne 0 ]] && die "$(date +%Y-%m-%d\ %H:%M:%S) Failed to retrive the currently active HomeKit hub from log file: $LOGFILE"
}

restart_last_active_hub()
{
 local CUR_ACTIVE_HUB=$1
 local IKEA_ID_ACTIVE_HUB=$2
 local EXIT=0
 # Stop the power via our smart outlet
  OUT=$($COAP_CLIENT -m put -u "$IKEA_USER" -k "$IKEA_TOKEN" -e '{ "3312": [{ "5850": 0 }] }' "coaps://$IKEA_HUB_ADDR:5684/15001/$IKEA_ID_ACTIVE_HUB" 2>&1 >/dev/null)
  [[ $? -ne 0 ]] && let "EXIT++"
  [[ ! -z $OUT ]] && let "EXIT++"
  # Wait 120s to be sure all components are properly restarted
  sleep 120
  # Start the power to the smart outlet
  OUT=$($COAP_CLIENT -m put -u "$IKEA_USER" -k "$IKEA_TOKEN" -e '{ "3312": [{ "5850": 1 }] }' "coaps://$IKEA_HUB_ADDR:5684/15001/$IKEA_ID_ACTIVE_HUB" 2>&1 >/dev/null)
  [[ $? -ne 0 ]] && let "EXIT++"
  [[ ! -z $OUT ]] && let "EXIT++"
  # Check if the restart was successful. If it failed, terminate the execution and produce error.
   if [[ $EXIT -eq 0 ]]
    then
     echo "$(date +%Y-%m-%d\ %H:%M:%S) Active HomeKit Hub $CUR_ACTIVE_HUB : RESTARTED"
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
          echo "$(date +%Y-%m-%d\ %H:%M:%S) New Active HomeKit Hub Elected: $NEW_ACTIVE_HUB"
          return 0
         fi
        done
    else
     echo "$(date +%Y-%m-%d\ %H:%M:%S) Active HomeKit Hub $CUR_ACTIVE_HUB : RESTART FAILED"
     return 1
    fi
}

#################################### End func definition

#################################### Begin execution

[[ ! -f $LOGFILE ]] && die "$(date +%Y-%m-%d\ %H:%M:%S) Log file $LOGFILE not found." 
[[ -z $COAP_CLIENT ]] && die "$(date +%Y-%m-%d\ %H:%M:%S) libcoap2 not found."
[[ -z $JQ ]] && die "$(date +%Y-%m-%d\ %H:%M:%S) jq not found."
# Match the hubs to their smart plug IDs
ACTIVE_HUB=$(get_last_active_hub)
echo $HOMEKIT_HUBS | grep -q "$ACTIVE_HUB" || die "$(date +%Y-%m-%d\ %H:%M:%S) Hub: $ACTIVE_HUB not defined in the script. Known hubs: $HOMEKIT_HUBS"
for HUB in $HOMEKIT_HUBS
 do
     HUB_IP="$(echo $HUB | cut -d ":" -f1)"
     HUB_ID="$(echo $HUB | cut -d ":" -f2)"
     if [[ "$ACTIVE_HUB" == "$HUB_IP" ]]
     then
         restart_last_active_hub $HUB_IP $HUB_ID
         exit $?
     fi
 done
exit 1

#################################### End execution
