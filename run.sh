#!/bin/bash

assert_dns_ip() {
  local dns_ip="$1"

  if [ -z "$dns_ip" ]; then
    echo "Could not resolve nameserver, has this machine no /etc/hosts?"
    exit 1
  fi
}

assert_servers() {
  local arg1=( $1 )

  if [ ${#servers[@]} -eq 0 ]; then
    echo "No SERVERS given, afraid to do anything cause cowardice"
    exit 1
  fi
}

generate_haproxy() {
  local dns_ip="$1"; shift
  local servers=( $@ )

  ./haproxy.cfg.sh "$dns_ip" "${servers[@]}"
}

get_dns_ip() {
  grep 'nameserver' /etc/resolv.conf \
  | head -n 1 \
  | awk '{print $2}'
}

run_haproxy() {
  haproxy -f /usr/local/etc/haproxy/haproxy.cfg
}


write_haproxy() {
  local dns_ip="$1"; shift
  local servers=( $@ )

  generate_haproxy "$dns_ip" "${servers[@]}" > /usr/local/etc/haproxy/haproxy.cfg
}

main(){
  local dns_ip="$(get_dns_ip)"
  local servers=( $SERVERS )

  assert_dns_ip "$dns_ip"
  assert_servers "${servers[@]}"

  write_haproxy "$dns_ip" "${servers[@]}"
  run_haproxy
}

main $@
