FROM ubuntu:18.04

ENV OPENWRT_VERSION='v18.06.1'

RUN apt-get update && \
    apt-get install -y build-essential subversion libncurses5-dev zlib1g-dev gawk gcc-multilib \
        flex git-core gettext libssl-dev unzip python wget time
    
ADD 0001-Zsun.patch /usr/src/0001-Zsun.patch
    
RUN cd /usr/src && \
    git clone -b "$OPENWRT_VERSION" https://github.com/openwrt/openwrt openwrt && \
    cd openwrt && \
    patch -p1 < ../0001-Zsun.patch && \
    ./scripts/feeds update -a && \
    ./scripts/feeds install -a

ADD config.txt /usr/src/openwrt/.config

WORKDIR /usr/src/openwrt

RUN make defconfig && \
    make download

RUN make -j"$(nproc)" V=s FORCE_UNSAFE_CONFIGURE=1

EXPOSE 80

CMD python -m SimpleHTTPServer 80
