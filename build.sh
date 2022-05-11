#!/bin/bash

set -e

function usage {
  echo -e "usage: 

--clone: clone projects
--proto: compile protocol and copy it everywhere
--link: link libraries to kernel
--nats: start nats-server
-b --build: run npm run build on each project
-i --install: run npm ci on each project 
-s --start: run npm run start on each project 
"
}

KERNEL_PATH=${KERNEL_PATH=:-"../kernel"}
STARTABLE_PROJECTS="archipelago-service explorer-bff lighthouse"
ALL_PROJECTS="$STARTTABLE_PROJECTS catalyst-comms-peer"

if [ $# -eq 0 ]; then
  usage 
  exit 1
fi

INSTALL=0
BUILD=0
START=0

for arg in "$@"; do
  case $arg in
    --clone )
      git clone git@github.com:decentraland/archipelago-service.git || echo "archipelago-service already cloned"
      git clone git@github.com:decentraland/explorer-bff.git || echo "explorer-bff already cloned"
      git clone git@github.com:decentraland/lighthouse.git || echo "lighthouse already cloned"
      git clone git@github.com:decentraland/catalyst-comms-peer.git || echo "catalys-comms-peer already cloned"
      shift
      ;;
    --proto)
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
    --link)
      shift 
      pushd catalyst-comms-peer > /dev/null
      npm link
      popd > /dev/null

      pushd $KERNEL_PATH > /dev/null
      npm link @dcl/catalyst-peer
      popd > /dev/null
      ;;
    -i | --install)
      INSTALL=1
      shift
      ;;
    -b | --build)
      BUILD=1
      shift 
      ;;
    -n | --nats)
      nats-server &
      shift 
      ;;
    -s | --start)
      START=1
      shift 
      ;;
    -*)
      usage
      exit 1
      ;;
    *)
      break
      ;;
  esac
done


PROJECTS=$ALL_PROJECTS
if [ "$@" ]; then
  PROJECTS=$@
fi

for project in $PROJECTS; do
  pushd $project > /dev/null
  if [ $INSTALL -eq 1 ]; then
    if [ -f "package-lock.json" ]; then
      npm ci
    elif  [ -f "yarn.lock" ]; then
      npx yarn install --frozen-lockfile
    else
      npm i
    fi
  fi
  if [ $BUILD -eq 1 ]; then
    npm run build
  fi
  popd > /dev/null
done

if [ $START -eq 1 ]; then
  mkdir -p var/log

  PROJECTS_TO_START=$STARTABLE_PROJECTS
  if [ "$@" ]; then
    PROJECTS_TO_START=$@
  fi

  for project in $PROJECTS_TO_START; do
    pushd $project > /dev/null
    npm run start &> "../var/log/$project.log"  &
    popd > /dev/null
  done
  wait
fi
