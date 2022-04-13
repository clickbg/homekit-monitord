#!/bin/bash
#
# Monit EXEC handler that sends monit notifications via Telegram
#
/usr/local/bin/sendtelegram.sh -c /etc/telegramrc -m "Monit $MONIT_SERVICE - $MONIT_EVENT at $MONIT_DATE on $MONIT_HOST: $MONIT_ACTION $MONIT_DESCRIPTION."
