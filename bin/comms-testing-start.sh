#!/bin/bash

set -e

source .env

for ip in $TEST_RUNNERS; do
  touch "var/log/testing-$ip.log"
  ssh root@$ip '\. /root/.nvm/nvm.sh && nvm use 14 && cd /opt/comms-testing && npm run start-runner' &> "var/log/testing-$ip.log" &
done

multitail var/log/testing-*.log
