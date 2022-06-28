#!/bin/bash

set -e

source .env

tar zvcf comms-testing.tar.gz --exclude node_modules/ --exclude dist/ --exclude protoc3 --exclude-vcs  comms-testing

for ip in $TEST_RUNNERS; do
  scp -r comms-testing/bin/deploy.sh comms-testing.tar.gz root@$ip:/opt/ && ssh root@$ip sh /opt/deploy.sh &
done

wait
