#!/bin/bash
COAP_CLIENT=$(which coap-client-gnutls)
JQ=$(which jq)

#####################
# Error exit function
function die()
{
   echo -e "$@" >&2
   exit 1
}

# Setup and get token
setup()
{
read -p "Hub Security Code (Bottom of the device): " SECURITY_CODE
read -p "Choose access username: " USER_NAME
read -p "Hub IP Address: " IKEA_HUB_ADDR
echo "Username: $USER_NAME"
echo "Token: $($COAP_CLIENT -m post -u "Client_identity" -k "$SECURITY_CODE" -e "{\"9090\":\"$USER_NAME\"}" "coaps://$IKEA_HUB_ADDR/15011/9063" | $JQ -re '.[]')"
}

# Discover IDs and names
discover()
{
read -p "Hub IP Address: " IKEA_HUB_ADDR
read -p "Hub Username: " IKEA_USER
read -p "Hub Token: " IKEA_TOKEN
for ID in $($COAP_CLIENT -m get -u "$IKEA_USER" -k "$IKEA_TOKEN" "coaps://$IKEA_HUB_ADDR:5684/15001" | $JQ -re '.[]')
do
 $COAP_CLIENT -m get -u "$IKEA_USER" -k "$IKEA_TOKEN" "coaps://$IKEA_HUB_ADDR:5684/15001/$ID" | $JQ -re
 sleep 1
done
}


case "$1" in
  setup)
   setup
   exit $?
   ;;
  discover)
   discover
   exit $?
   ;;
  *)
   echo "Unrecognized input. Supported options: setup, discover"
   exit 1
   ;;
esac
