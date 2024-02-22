#!/bin/sh

cat /etc/privoxy/privoxy.conf > /etc/privoxy/config

privoxy --user privoxy --no-daemon /etc/privoxy/config