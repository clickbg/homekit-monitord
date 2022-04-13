ARG ARCH=
FROM ${ARCH}nginx:latest
MAINTAINER daniel@rsync.eu

RUN ln -s /usr/bin/dpkg-split /usr/sbin/dpkg-split
RUN ln -s /usr/bin/dpkg-deb /usr/sbin/dpkg-deb
RUN ln -s /bin/rm /usr/sbin/rm
RUN ln -s /bin/tar /usr/sbin/tar

RUN apt-get update \
    && apt-get install -y monit \
    && apt-get install -y libcoap2-bin \
    && apt-get install -y jq \
    && apt-get install -y procps \
    && apt-get clean \
    && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*
    
COPY root /
