#!/bin/bash

set -e

source .env

for ip in $TEST_RUNNERS; do
  ssh root@$ip pkill -kill node &
done

wait
