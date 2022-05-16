#!/bin/bash

set -e

trap 'catch' ERR

catch() {
  echo "error: killing child processes"
  pkill -kill  -P $$
}

function usage {
  echo -e "usage: 

--clone: clone projects
--proto: compile protocol and copy it everywhere
--link: link libraries to kernel
--nats: start nats-server
-b --build: run npm run build on each project
-i --install: run npm ci on each project 
-s --start: run npm run start on each project 
-m --multitail: run multitail for the started projects
"
}

KERNEL_PATH=${KERNEL_PATH:-"../kernel"}
STARTABLE_PROJECTS="archipelago-service explorer-bff"
ALL_PROJECTS="$STARTABLE_PROJECTS comms3-livekit-transport"

if [ $# -eq 0 ]; then
  usage 
  exit 1
fi

INSTALL=0
BUILD=0
START=0
GIT_STATUS=0
MULTITAIL=0

for arg in "$@"; do
  case $arg in
    --clone )
      git clone git@github.com:decentraland/archipelago-service.git || echo "archipelago-service already cloned"
      git clone git@github.com:decentraland/explorer-bff.git || echo "explorer-bff already cloned"
      git clone git@github.com:decentraland/lighthouse.git || echo "lighthouse already cloned"
      git clone git@github.com:decentraland/catalyst-comms-peer.git || echo "catalys-comms-peer already cloned"
      git clone git@github.com:decentraland/comms3-livekit-transport.git  || echo "comms3-livekit-transport  already cloned"
      shift
      ;;
    --proto)
      pushd proto > /dev/null
      protoc --plugin=../$KERNEL_PATH/node_modules/.bin/protoc-gen-ts --js_out="import_style=commonjs,binary:." --ts_out="." comms.proto
      protoc --plugin=../$KERNEL_PATH/node_modules/.bin/protoc-gen-ts --js_out="import_style=commonjs,binary:." --ts_out="." ws.proto
      protoc --plugin=../$KERNEL_PATH/node_modules/.bin/protoc-gen-ts --js_out="import_style=commonjs,binary:." --ts_out="." bff.proto
      protoc --plugin=../$KERNEL_PATH/node_modules/.bin/protoc-gen-ts --js_out="import_style=commonjs,binary:." --ts_out="." archipelago.proto
      protoc --plugin=../$KERNEL_PATH/node_modules/.bin/protoc-gen-ts --js_out="import_style=commonjs,binary:." --ts_out="." p2p.proto
      popd > /dev/null

      # kernel
      cp proto/* $KERNEL_PATH/packages/shared/comms/v4/proto

      # bff
      cp proto/bff* explorer-bff/src/controllers/proto/
      cp proto/ws* explorer-bff/src/controllers/proto/

      # archipelago
      cp proto/archipelago* archipelago-service/src/controllers/proto/

      shift 
      ;;
    --link)
      pushd catalyst-comms-peer > /dev/null
      npm link
      popd > /dev/null

      pushd comms3-livekit-transport > /dev/null
      npm link
      popd > /dev/null

      pushd $KERNEL_PATH > /dev/null
      npm link @dcl/comms3-livekit-transport
      popd > /dev/null

      shift 
      ;;
    -n | --nats)
      nats-server &
      shift 
      ;;
    -i | --install)
      INSTALL=1
      shift
      ;;
    -b | --build)
      BUILD=1
      shift 
      ;;
    -s | --start)
      START=1
      shift 
      ;;
    -m | --multitail)
      MULTITAIL=1
      shift 
      ;;
    --status)
      GIT_STATUS=1
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
R=$(echo "$@" | xargs)
if [ -n  "$R"  ]; then
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

  if [ $GIT_STATUS -eq 1 ]; then
    printf "\e[33;1m$project:\n\e[0m"
    git status
    echo ""
  fi

  popd > /dev/null
done

if [ $START -eq 1 ]; then
  mkdir -p var/log

  PROJECTS_TO_START=$STARTABLE_PROJECTS
  if [ -n "$R" ]; then
    PROJECTS_TO_START=$@
  fi

  for project in $PROJECTS_TO_START; do
    pushd $project > /dev/null
    npm run start &> "../var/log/$project.log"  &
    popd > /dev/null
  done

  if [ $MULTITAIL -eq 1 ]; then
    multitail var/log/*.log
  fi
  wait
fi
