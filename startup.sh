#!/bin/sh
/usr/local/bin/stubby -C /usr/local/etc/stubby/stubby.yml &
dnsmasq -k &

wait -n

exit $?
