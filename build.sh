#!/bin/bash

set -e

function usage {
  echo -e "usage: 

-u --update: update projects
-b --build: build projects
-i --install: install projects
-s --start: start projects
-p --protocol: compile protocol and copy it everywhere
"
}


KERNEL_PATH=${PROJECTS:-"../kernel"}
PROJECTS=${PROJECTS:-"archipelago-service explorer-bff"}

if [ $# -eq 0 ]; then
    usage 
    exit 1
fi

for arg in "$@"; do
    case $arg in
    --init )
      git clone git@github.com:decentraland/archipelago-service.git || git clone git@github.com:decentraland/explorer-bff.git
      shift
      ;;
    -i | --install)
        for project in $PROJECTS; do
          pushd $project > /dev/null
          npm ci
          popd > /dev/null
        done

        shift
        ;;
    -b | --build)
        for project in $PROJECTS; do
          pushd $project > /dev/null
          npm run build
          popd > /dev/null
        done

        shift 
        ;;
    -s | --start)
        nats-server &

        for project in $PROJECTS; do
          pushd $project > /dev/null
          npm run start &
          popd > /dev/null
        done

        wait
        shift 
        ;;
    -p | --proto)
        pushd proto > /dev/null
        protoc --plugin=../$KERNEL_PATH/node_modules/ts-protoc-gen/bin/protoc-gen-ts --js_out="import_style=commonjs,binary:." --ts_out="." comms.proto
        protoc --plugin=../$KERNEL_PATH/node_modules/ts-protoc-gen/bin/protoc-gen-ts --js_out="import_style=commonjs,binary:." --ts_out="." ws.proto
        protoc --plugin=../$KERNEL_PATH/node_modules/ts-protoc-gen/bin/protoc-gen-ts --js_out="import_style=commonjs,binary:." --ts_out="." bff.proto
        protoc --plugin=../$KERNEL_PATH/node_modules/ts-protoc-gen/bin/protoc-gen-ts --js_out="import_style=commonjs,binary:." --ts_out="." nats.proto
        popd > /dev/null

        cp proto/* $KERNEL_PATH/packages/shared/comms/v4/proto
        cp proto/* explorer-bff/src/controllers/proto/
        cp proto/* archipelago-service/src/controllers/proto/

        shift 
        ;;
    -h | --help)
        usage # run usage function on help
        ;;
    *)
        usage # run usage function if wrong argument provided
        ;;
    esac
done
