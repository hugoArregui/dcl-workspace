#!/bin/bash

set -e

source .env

for ip in $TEST_RUNNERS; do
  touch "var/log/testing-$ip.log"
  ssh root@$ip 'sh /opt/comms-testing/bin/start.sh' &> "var/log/testing-$ip.log" &
done

multitail var/log/testing-*.log
