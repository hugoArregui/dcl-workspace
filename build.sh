#!/bin/bash

set -e

function usage {
  echo -e "usage: 

-b --build: build projects
-i --install: install projects
-s --start: start projects
"
}


PROJECTS=${PROJECTS:-"archipelago-service explorer-bff"}

if [ $# -eq 0 ]; then
    usage 
    exit 1
fi

for arg in "$@"; do
    case $arg in
    -u | --update)
        git submodule update --remote archipelago-service
        git submodule update --remote explorer-bff

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
    -h | --help)
        usage # run usage function on help
        ;;
    *)
        usage # run usage function if wrong argument provided
        ;;
    esac
done
