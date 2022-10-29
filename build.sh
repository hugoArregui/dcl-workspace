#!/bin/bash

set -e

trap 'catch' ERR

. $NVM_DIR/nvm.sh 

nvm use 16

catch() {
  echo "error: killing child processes"
  pkill -kill  -P $$
}

function usage {
  echo -e "usage: 
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
      nats-server &
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

R=$(echo "$@" | xargs)
if [ -n "$R"  ]; then
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

  for rawProject in $PROJECTS_TO_START; do
    project=${rawProject%"/"} # remove suffix "/"
    pushd $project > /dev/null

    if [ $MULTITAIL -eq 1 ]; then
      touch ../var/log/$project.log
      LOG_FILES="$LOG_FILES var/log/$project.log"

      if [ -f "package.json" ]; then
        npm run start &> "../var/log/$project.log"  &
      else
        make start &> "../var/log/$project.log"  &
      fi
    else
      if [ -f "package.json" ]; then
        npm run start &
      else
        make start &
      fi
    fi
    popd > /dev/null
  done

  if [ $MULTITAIL -eq 1 ]; then
    multitail $LOG_FILES
  fi
  wait
fi
