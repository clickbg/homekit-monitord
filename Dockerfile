FROM nginx:latest

RUN apt-get update \
    && apt-get install -y monit \
    && apt-get install -y libcoap2-bin \
    && apt-get install -y jq \
    && apt-get install -y procps \
    && apt-get clean \
    && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*
    
COPY root /
