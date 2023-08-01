########## Builder intermediate image ##########
FROM alpine:latest AS builder

ARG GETDNS_VERSION
ARG DNSMASQ_VERSION

# Builder dependencies
RUN apk add --no-cache --update build-base check-dev curl gnupg \
  cmake libidn2-dev openssl-dev libev-dev libuv-dev yaml-dev \
  coreutils dbus-dev linux-headers nettle-dev net-tools


##### Get dns section #####
ADD https://getdnsapi.net/dist/getdns-${GETDNS_VERSION}.tar.gz /tmp/
ADD https://getdnsapi.net/dist/getdns-${GETDNS_VERSION}.tar.gz.asc /tmp/

# Import GetDNS's key (Willem Toorop <willem@nlnetlabs.nl>)
RUN gpg --recv-keys 0xE5F8F8212F77A498

# Verify the download (exit if it fails)
RUN gpg --status-fd 1 --verify /tmp/getdns-${GETDNS_VERSION}.tar.gz.asc /tmp/getdns-${GETDNS_VERSION}.tar.gz 2>/dev/null | grep -q "GOODSIG E5F8F8212F77A498" \
  || exit 1

WORKDIR /src
RUN tar xzf /tmp/getdns-${GETDNS_VERSION}.tar.gz -C ./

WORKDIR /src/getdns-${GETDNS_VERSION}/build

RUN cmake -DBUILD_STUBBY=ON \
  -DENABLE_STUB_ONLY=ON \
  .. && make && make install && ldconfig /


##### Dnsmasq section #####
ADD https://thekelleys.org.uk/dnsmasq/dnsmasq-${DNSMASQ_VERSION}.tar.gz /tmp/
ADD https://thekelleys.org.uk/dnsmasq/dnsmasq-${DNSMASQ_VERSION}.tar.gz.asc /tmp/

# Import Dnsmasq's key from keyring.debian.org (Simon Kelley <simon@thekelleys.org.uk>)
RUN gpg --keyserver keyring.debian.org --recv-keys 0x15CDDA6AE19135A2

# Verify the download (exit if it fails)
RUN gpg --status-fd 1 --verify /tmp/dnsmasq-${DNSMASQ_VERSION}.tar.gz.asc /tmp/dnsmasq-${DNSMASQ_VERSION}.tar.gz 2>/dev/null | grep -q "GOODSIG 15CDDA6AE19135A2" \
  || exit 1

WORKDIR /src
RUN tar xzf /tmp/dnsmasq-${DNSMASQ_VERSION}.tar.gz -C ./

WORKDIR /src/dnsmasq-${DNSMASQ_VERSION}

RUN make && make install && ldconfig /



########## Final image ##########
FROM alpine:latest

RUN apk add --no-cache --update ca-certificates tzdata libidn2 yaml drill tini && \
  rm -rf /var/cache/apk/*

RUN mkdir -p /var/cache/stubby

RUN mkdir -p /var/lib/dhcp && \
  touch /var/lib/dhcp/dhcpd.leases && \
  mkdir -p /var/log/dnsmasq && \
  touch /var/log/dnsmasq/dnsmasq.log

COPY --from=builder /usr/local/ /usr/local

COPY dnsmasq.conf /etc/dnsmasq.conf

COPY startup.sh startup.sh
RUN chmod +x ./startup.sh

HEALTHCHECK --interval=60s --timeout=5s --start-period=5s \
  CMD drill @127.0.0.1 -p 53 google.com || exit 1

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["./startup.sh"]
