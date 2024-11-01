
# HomeKit Active Hub Monitoring

[![CICD](https://github.com/clickbg/homekit-monitord/workflows/CICD/badge.svg?branch=main)](https://github.com/clickbg/homekit-monitord/actions/workflows/cicd.yaml)
[![UPDATE](https://github.com/clickbg/homekit-monitord/workflows/UPDATE/badge.svg?branch=main)](https://github.com/clickbg/homekit-monitord/actions/workflows/update.yaml)
[![PUBLISH](https://github.com/clickbg/homekit-monitord/workflows/PUBLISH/badge.svg)](https://github.com/clickbg/homekit-monitord/actions/workflows/publish.yaml)

<img src="https://www.docker.com/wp-content/uploads/2022/03/vertical-logo-monochromatic.png" width="20" height="20"> [Avaliable on DockerHub](https://hub.docker.com/r/clickbg/homekit-monitord)

This project aims to provide monitoring and optionally restart of your HomeKit Hubs - Apple TV, HomePod (mini, OG).  
Monitoring is done by configuring an advanced automation in HomeKit which will report the state to the Docker container.
In case the currently active Hub crashes/hangs or otherwise stops running this automation the container will notify you about the issue and optionally (if you have your Hubs plugged into smart outlets) restart the last known active HomeKit hub.

**Supported notification methods**
 - E-mail
 - Telegram
 
 **Supported smart outlets**
 - [IKEA Tradfri Wireless Outlet](https://www.ikea.com/us/en/p/tradfri-wireless-control-outlet-30356169/) + [IKEA Tradfri Hub](https://www.ikea.com/us/en/p/tradfri-gateway-white-00337813/)
 - Any [Zigbee2MQTT](https://www.zigbee2mqtt.io/) compatible outlet

**Requirements**

 - Docker host running on amd64, armv7 or arm64 - Raspberry Pi or any modern Intel/AMD powered computer or VM
 - (Optional) IKEA Tradfri Wireless Outlets + [IKEA Tradfri Hub](https://www.ikea.com/us/en/p/tradfri-gateway-white-00337813/) or a [Zigbee2MQTT](https://www.zigbee2mqtt.io/) outlet

**Usage**
--
Command Line:

    docker run --name homekit-monitord -e IKEA_USER=ikea_hub_user -e IKEA_HUB_ADDR=ikea_hub_ip -e IKEA_TOKEN=ikea_hub_token -e HOMEKIT_HUBS="10.10.10.20:200 10.10.10.30:200 10.10.10.40:200" -e NOTIFY_EMAIL="me@example.com" -e EMAIL_SENDER="bot@example.com" -e EMAIL_SERVER="smtp.gmail.com" -e EMAIL_PORT="587" -e EMAIL_PASSWORD="secret" -e RESTART_HUB=1 -e TELEGRAM_TOKEN=secret -e TELEGRAM_CHATID=chatid -d -p 8080:80 clickbg/homekit-monitord:latest
  
 Using [Docker Compose](https://docs.docker.com/compose/) (recommended):

    services:
    
      homekit-monitord:
        container_name: homekit-monitord
        restart: always
        image: clickbg/homekit-monitord:latest
        ports:
          - "8080:80"
        environment:
          - PUID=1000
          - PGID=1000
          - TZ=Bulgaria/Sofia
          - RESTART_HUB=0
          - NOTIFY_EMAIL=me@example.com
          - EMAIL_SENDER=bot@example.com
          - EMAIL_PASSWORD=secret
          - EMAIL_SERVER=smtp.gmail.com
          - EMAIL_PORT=587
          - TELEGRAM_TOKEN=secret
          - TELEGRAM_CHATID=chatid
        healthcheck:
          test: curl --fail http://localhost/nginx_status || exit 1
          interval: 10s
          retries: 5
          start_period: 5s
          timeout: 10s

**Parameters**
--
***Required parameters***  
 `-p 8080:80` - On which port should the container listen for Hub connections  

***Optional parameters***  
          `-e PUID=1000` - uid for the nginx process, leave at 1000 if unsure  
          `-e PGID=1000` - guid for the nginx process, leave at 1000 if unsure  
          `-e TZ=Bulgaria/Sofia` - [Timezone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)  

**Zigbee2MQTT Smart Outlets** 
`-e RESTART_HUB=1` - Binary value 1/0, dictates whether or not the container will try to restart the Hubs  
`-e HOMEKIT_HUBS=10.10.10.20:0xb4e3f9fffe22f3d2 10.10.10.30:0xb4e3f9fffe66f3d9` - List of the HomeKit Hubs in the format IP:IEEE_Address  
`-e MQTT_ADDR=mqtt://10.1.1.1/zigbee2mqtt` - Support for SSL and auth avaliable as well, format is: `mqtt(s)://[username[:password]@]host[:port]/topic` 

**IKEA Smart Outlets** 
`-e RESTART_HUB=1` - Binary value 1/0, dictates whether or not the container will try to restart the Hubs  
`-e HOMEKIT_HUBS=10.10.10.20:65609 10.10.10.30:65610` - List of the HomeKit Hubs in the format IP:IKEA_TRADFRI_ID  
`-e IKEA_USER=ikea_hub_user` - IKEA hub user  
`-e IKEA_HUB_ADDR=ikea_hub_ip` - IKEA hub IP  
`-e IKEA_TOKEN=ikea_hub_token` - IKEA hub token  

**E-mail Notifications** 
The container doesn't ship with e-mail server so please use your own or Gmail:  
`-e NOTIFY_EMAIL=me@example.com` - The e-mail address of the person who will receive alerts  
`-e EMAIL_SENDER=bot@example.com` - The username of the e-mail from which the alerts will be sent  
`-e EMAIL_PASSWORD=secret` - The password of the e-mail from which the alerts will be sent  
`-e EMAIL_SERVER=smtp.gmail.com` - The e-mail server from which the alerts will be sent  
`-e EMAIL_PORT=587` - The e-mail server port - common options 25, 465, 487  

**Telegram Notifications** 
You can use both e-mail and Telegram, read below for detailed instructions:  
`-e TELEGRAM_TOKEN=secret` - Telegram token  
`-e TELEGRAM_CHATID=chatid` - Telegram chatid  

**Installation**
--
**Configuring advanced automation in HomeKit**

First we need to schedule an automation to run every 5 minutes.
Unfortunately that is not possible in the Home app, so we are going to use a 3rd party app.
You can do that with either [Controller for HomeKit](https://apps.apple.com/us/app/controller-for-homekit/id1198176727) (the free version supports that), [Home+](https://apps.apple.com/us/app/home-5/id995994352) (paid), [Eve for HomeKit](https://apps.apple.com/us/app/eve-for-homekit/id917695792) (also free)

1. Open your app of choice and create a new automation - navigate to `Automations > New Automation > In recurring time intervals > Minute` in Controller, `Automation > Timers` in Eve 
3. Set the automation to execute any scene that you have - which one doesn't matter we will change it later
4. Set it to `Repeat` every `5 minutes`

   **Controller**  
   ![enter image description here](https://github.com/clickbg/homekit-monitord/blob/main/.pics/controller.png?raw=true)
   
   **Eve**
   
   ![enter image description here](https://github.com/clickbg/homekit-monitord/blob/main/.pics/eve.png?raw=true)

 5. Next open the built-in [Home](https://apps.apple.com/us/app/home/id1110145103) app
 6. Select the previously created automation 
 7. Click `Select Accessories and Scenes...`
 8. Scroll down to the end of the list and click `Convert To Shortcut`
 9. Click `Add action` and select `URL`
 10. Click on the `URL` action and input your Docker container IP followed by `/active-hub-report-health/`  Example: `http://10.10.200.200:8080/active-hub-report-health/`

 11. Click `Add action` and select `Get Contents Of URL`
 12. Make sure the `Get Contents Of URL` action uses the `URL` variable
      Result:
      ![enter image description here](https://github.com/clickbg/homekit-monitord/blob/main/.pics/shortcut-example.png?raw=true)
5. Click `Next` and set a `Name` for the automation

**Zigbee2MQTT Smart Outlet setup**  
--
Zigbee2MQTT can be controlled outside of HomeKit and has open, well documented API.  

***Getting access***  
If you are using Eclipse Mosquitto check out your mosquitto.conf for user/password/port/encryption.  
Apart from that the configuration format is: `mqtt(s)://[username[:password]@]host[:port]/topic`.  
The default topic for Zigbee2MQTT is zigbee2mqtt:  
Example:  
   `MQTT_ADDR=mqtt://10.1.1.1/zigbee2mqtt`  

***Getting the Zigbee2MQTT ID of your outlets***  
1. Navigate to Zigbee2MQTT Web UI  
2. Find the outlet and click on it  
3. Copy the IEEE Address  


**IKEA Tradfri Smart Outlet setup**  
--
IKEA Tradfri smart outlet is ideal for us since it can be controlled outside of HomeKit and doesn't require internet.  

***Getting access token***   
In the container there is a helper script which you can use to register and discover devices on your IKEA Tradfri Hub:  
1. Enter the container  
    `docker exec -it homekit-monitord /bin/bash`  
 2. Run the interactive script, be prepared to enter the IKEA Hub IP and Registration Code (Found on the bottom of the Hub)  
     `root@588e501a6cf1:/# /usr/local/bin/setup_tradfri.sh setup`  
     `Hub Security Code (Bottom of the device): CODE_FROM_THE_BOTTOM_OF_THE_HUB`  
     `Choose access username: CHOOSE_COOL_USER_NAME`  
     `Hub IP Address: ikea_hub_ip`  

     Output:  
     `Username: test2`  
     `Token: TOKEN`  
     `1.17.0033`  

2. Discover the smart outlet/s ID:  
    `root@588e501a6cf1:/# /usr/local/bin/setup_tradfri.sh discover`  
`Hub IP Address: ikea_hub_ip`  
`Hub Username: ikea_hub_user`  
`Hub Token: ikea_hub_token`  

      Output:  

     `  {`  
  `"9001": "Office HomePod Outlet",`  
`  "9003": 65609,`  
`  "9002": 1649486154,`  
`  "9020": 1649832083,`  
`  "9054": 0,`  
`  "9019": 1,`  
`  "3": {`
`    "0": "IKEA of Sweden",`  
`    "1": "TRADFRI control outlet",`  
`    "2": "",`  
`    "3": "2.3.089",`  
`    "6": 1,`  
 `   "7": 4353,`  
`    "8": 0`  
`  },`  

The ID is stored in property 9003, in our case the ID is **65609**.   
Now we can setup our container to restart this HomePod by entering the following properties in compose:  
`- RESTART_HUB=1`  
`- HOMEKIT_HUBS=10.10.10.20:65609 10.10.10.30:65610`  
`- IKEA_USER=ikea_hub_user`  
`- IKEA_HUB_ADDR=ikea_hub_ip`  
`- IKEA_TOKEN=ikea_hub_token`   



