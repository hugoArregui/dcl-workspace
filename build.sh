#!/bin/bash

set -e

trap 'catch' ERR

. $NVM_DIR/nvm.sh 

catch() {
  echo "error: killing child processes"
  pkill -kill  -P $$
}

function usage {
  echo -e "usage: 

--clone: clone projects
--proto: compile protocol and copy it everywhere
--link-transports: link comms3-transports
--nats: start nats-server
--status: git status on each project
-b --build: run npm run build on each project
-i --install: run npm ci on each project 
-s --start: run npm run start on each project 
-m --multitail: run multitail for the started projects
"
}


VERBOSE=1

function logDebug {
  if [ $VERBOSE -eq 1 ]; then
    echo $*
  fi
}

KERNEL_PATH=${KERNEL_PATH:-"$PWD/kernel"}
STARTABLE_PROJECTS="archipelago-service explorer-bff ws-room-service"
ALL_PROJECTS="$STARTABLE_PROJECTS comms3-transports"

if [ $# -eq 0 ]; then
  usage 
  exit 1
fi

FLAG_PROVIDED=0

INSTALL=0
BUILD=0
START=0
GIT_STATUS=0
MULTITAIL=0

for arg in "$@"; do
  case $arg in
    --clone )
      FLAG_PROVIDED=1
      git clone git@github.com:decentraland/archipelago-service.git || true
      git clone git@github.com:decentraland/explorer-bff.git || true
      git clone git@github.com:decentraland/rpc.git  || true
      git clone git@github.com:decentraland/comms3-transports.git || true
      git clone git@github.com:decentraland/comms-testing.git || true
      git clone git@github.com:decentraland/ws-room-service.git || true
      shift
      ;;
    --proto)
      FLAG_PROVIDED=1
      # kernel
      mkdir -p $KERNEL_PATH/packages/shared/comms/v4/proto/bff
      cp proto/bff/*.proto $KERNEL_PATH/packages/shared/comms/v4/proto/bff
      cp proto/archipelago.proto  $KERNEL_PATH/packages/shared/comms/v4/proto

      # comms3-transports
      cp proto/ws.proto  comms3-transports/src/proto
      cp proto/p2p.proto  comms3-transports/src/proto
      cp proto/archipelago.proto  comms3-transports/src/proto

      # bff
      cp proto/bff/*.proto explorer-bff/src/controllers/bff-proto/

      # ws-room-service
      cp proto/ws.proto ws-room-service/src/proto/

      # archipelago
      cp proto/archipelago.proto archipelago-service/src/controllers/proto/

      # comms-testing
      cp proto/bff/*.proto comms-testing/src/proto/bff/
      cp proto/archipelago.proto  comms-testing/src/proto
      shift 
      ;;
    --link-transports)
      FLAG_PROVIDED=1
      pushd comms3-transports > /dev/null
      npm link
      nvm exec 14 npm link
      popd > /dev/null

      pushd comms-testing > /dev/null
      nvm exec 14 npm link @dcl/comms3-transports
      popd > /dev/null

      pushd $KERNEL_PATH > /dev/null
      npm link @dcl/comms3-transports
      popd > /dev/null

      shift
      ;;
    --upgrade-transports)
      FLAG_PROVIDED=1
      pushd comms-testing > /dev/null
      nvm exec 14 npm i --save @dcl/comms3-transports@next
      popd > /dev/null

      pushd $KERNEL_PATH > /dev/null
      npm i --save @dcl/comms3-transports@next
      popd > /dev/null

      shift
      ;;
    -n | --nats)
      FLAG_PROVIDED=1
      nats-server &
      shift 
      ;;
    -i | --install)
      FLAG_PROVIDED=1
      INSTALL=1
      shift
      ;;
    -b | --build)
      FLAG_PROVIDED=1
      BUILD=1
      shift 
      ;;
    -s | --start)
      FLAG_PROVIDED=1
      START=1
      shift 
      ;;
    -m | --multitail)
      FLAG_PROVIDED=1
      MULTITAIL=1
      shift 
      ;;
    --status)
      FLAG_PROVIDED=1
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

if [ $FLAG_PROVIDED -eq 0 ]; then
  usage
  exit 1
fi

PROJECTS=$ALL_PROJECTS
R=$(echo "$@" | xargs)
if [ -n  "$R"  ]; then
  PROJECTS=$@
fi

for project in $PROJECTS; do
  pushd $project > /dev/null
  if [ $INSTALL -eq 1 ]; then
    logDebug "install $project"
    if [ -f "Makefile" ]; then
      make install
    elif [ -f "package-lock.json" ]; then
      npm ci
    elif  [ -f "yarn.lock" ]; then
      npx yarn install --frozen-lockfile
    else
      npm i
    fi
  fi

  if [ $BUILD -eq 1 ]; then
    logDebug "build $project"
    if [ -f "Makefile" ]; then
      make build
    else
      npm run build
     fi
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

  LOG_FILES=""

  for project in $PROJECTS_TO_START; do
    pushd $project > /dev/null
    touch ../var/log/$project.log
    LOG_FILES="$LOG_FILES var/log/$project.log"
    npm run start &> "../var/log/$project.log"  &
    popd > /dev/null
  done

  if [ $MULTITAIL -eq 1 ]; then
    multitail $LOG_FILES
  fi
  wait
fi
