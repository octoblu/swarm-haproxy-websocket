#!/bin/bash

dns_ip="$1"; shift
servers=( $@ )

echo """
global
  stats socket /tmp/haproxy.sock
  maxconn 80000

resolvers dns
  nameserver dns1 ${dns_ip}:53
  hold valid 2m

defaults
  log    global
  mode   http
  timeout client 60s            # Client and server timeout must match the longest
  timeout server 300s           # time we may wait for a response from the server.
  timeout queue  120s           # Don't queue requests too long if saturated.
  timeout connect 10s           # There's no reason to change this one.
  timeout http-request 300s     # A complete request may never take that long.
  timeout tunnel 2h
  retries         3
  option redispatch
  option httplog
  option dontlognull
  option http-server-close      # enable HTTP connection closing on the server side
  option abortonclose           # enable early dropping of aborted requests from pending queue
  option httpchk                # enable HTTP protocol to check on servers health
  stats auth opsworks:opsworks
  stats uri /haproxy?stats

backend meshblu-websocket
  balance roundrobin
  timeout queue 5000
  timeout server 86400000
  timeout connect 86400000
  timeout check 1s
  option forwardfor
  no option httpclose
  option http-server-close
  option forceclose
  # this must be the partial url
  option httpchk GET /healthcheck
"""


for server in ${servers[@]}; do
  echo "  server $server $server:80 resolvers dns resolve-prefer ipv4 check inter 1m"
done

echo """
frontend http-in
  bind :80
  default_backend meshblu-websocket
"""
