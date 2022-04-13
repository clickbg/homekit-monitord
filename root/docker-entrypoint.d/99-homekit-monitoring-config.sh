#!/bin/bash
MONIT_PASSWORD=$(openssl rand -hex 20)
MONITRC="/etc/monit/monitrc"
NGINXRC="/etc/nginx/conf.d/default.conf"
TELEGRAMRC="/etc/telegramrc"
MONIT_LOG="/var/log/monit.log"
HK_LOGFILE="/var/log/nginx/homekit-health-reports.json"

# Setup our env
cat << EOF > /etc/environment
IKEA_USER="$IKEA_USER"
IKEA_HUB_ADDR="$IKEA_HUB_ADDR"
IKEA_TOKEN="$IKEA_TOKEN"
HOMEKIT_HUBS="$HOMEKIT_HUBS"
NOTIFY_EMAIL="$NOTIFY_EMAIL"
EMAIL_SENDER="$EMAIL_SENDER"
EMAIL_SERVER="$EMAIL_SERVER"
EMAIL_PORT="$EMAIL_PORT"
EMAIL_PASSWORD="$EMAIL_PASSWORD"
TELEGRAM_TOKEN="$TELEGRAM_TOKEN"
TELEGRAM_CHATID="$TELEGRAM_CHATID"
LOGFILE="$HK_LOGFILE"
EOF

# Configure nginx
SED_HK_LOGFILE=$(echo $HK_LOGFILE | sed 's_/_\\/_g')
sed -i "s/LOGFILE/$SED_HK_LOGFILE/g" $NGINXRC

# Configure monit
sed -i "s/PASSWORD/$MONIT_PASSWORD/g" $MONITRC

## Set Monit to send emails or not, depending on our config
if [[ -z $NOTIFY_EMAIL || -z $EMAIL_SENDER || -z $EMAIL_SERVER || -z $EMAIL_PORT ]]; then
 sed -i '/set mailserver/d' $MONITRC
 sed -i '/set alert/d' $MONITRC
else
 sed -i "s/EMAIL/$NOTIFY_EMAIL/g" $MONITRC
 sed -i "s/SERVER/$EMAIL_SERVER/g" $MONITRC
 sed -i "s/PORT/$EMAIL_PORT/g" $MONITRC
 sed -i "s/EUSER/$EMAIL_SENDER/g" $MONITRC
 sed -i "s/MAILPASS/$EMAIL_PASSWORD/g" $MONITRC
fi

## Set Monit to send Telegram msgs, depending on our config
if [[ -z $TELEGRAM_TOKEN || -z $TELEGRAM_CHATID ]]; then
 sed -i '/monit2telegram.sh/d' $MONITRC
else
 sed -i "s/TELEGRAM_TOKEN/$TELEGRAM_TOKEN/g" $TELEGRAMRC
 sed -i "s/TELEGRAM_CHATID/$TELEGRAM_CHATID/g" $TELEGRAMRC
fi

## Set Monit to restart HomeKit hubs, or not depending on our config
if [[ "$RESTART_HUB" -ne 1 ]]; then
 sed -i '/restart_active_homekit_hub.sh/d' $MONITRC
fi

rm -f $MONIT_LOG
ln -s /dev/stderr $MONIT_LOG
chmod 600 $MONITRC $TELEGRAMRC
chmod 700 /usr/local/bin/*.sh
/etc/init.d/monit restart
