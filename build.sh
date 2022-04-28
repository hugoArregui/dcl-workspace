#!/bin/bash

set -e

function usage {
  echo -e "usage: 

--clone: clone projects
-b --build: run npm run build on each project
-i --install: run npm ci on each project 
-s --start: run npm run start on each project 
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
    --clone )
      git clone git@github.com:decentraland/archipelago-service.git || echo "archipelago-service already cloned"
      git clone git@github.com:decentraland/explorer-bff.git || echo "explorer-bff already cloned"
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
    *)
        usage # run usage function if wrong argument provided
        exit 1
        ;;
    esac
done
