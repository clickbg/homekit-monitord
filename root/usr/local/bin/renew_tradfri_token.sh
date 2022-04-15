#!/bin/bash
# Author: Daniel Zhelev @ https://zhelev.biz

source /etc/environment

# Tools that we need
COAP_CLIENT=$(which coap-client-gnutls)
JQ=$(which jq)
LOG_OUT="/proc/1/fd/1"

log()
{
   echo -e "$@" | tee $LOG_OUT
}

# Renew our token since it expires if not used for 6 weeks
$($COAP_CLIENT -B 30 -m get -u "$IKEA_USER" -k "$IKEA_TOKEN" "coaps://$IKEA_HUB_ADDR:5684/15001" | grep -q '^.*$')
if [[ $? -eq 0 ]]
 then
  log "$(date +%Y-%m-%d\ %H:%M:%S) [SUCCESS] Successfully renewed token [$IKEA_USER] with IKEA Hub: [$IKEA_HUB_ADDR]"
  exit 0
 else
  log "$(date +%Y-%m-%d\ %H:%M:%S) [FAILED] Failed to renewed token [$IKEA_USER] with IKEA Hub: [$IKEA_HUB_ADDR]"
  exit 0
fi
