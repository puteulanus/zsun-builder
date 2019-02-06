FROM ubuntu:18.04 as BUILD

ENV OPENWRT_VERSION='lede-17.01'

RUN apt-get update && \
    apt-get install -y build-essential subversion libncurses5-dev zlib1g-dev gawk gcc-multilib \
        flex git-core gettext libssl-dev unzip python wget
        
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

RUN make -j"$(nproc)" FORCE_UNSAFE_CONFIGURE=1


FROM alpine

COPY --from=BUILD /usr/src/openwrt /root/openwrt

RUN apk --no-cache add python
WORKDIR /root/openwrt
EXPOSE 80
CMD python -m SimpleHTTPServer 80
