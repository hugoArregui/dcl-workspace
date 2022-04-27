#!/bin/bash

function usage {
  echo -e "usage: 

-b --build: build projects
-i --install: install projects
"
}


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
        pushd archipelago-service
        npm ci
        popd

        pushd explorer-bff
        npm ci
        popd

        shift
        ;;
    -b | --build)
        pushd archipelago-service
        npm run build
        popd

        pushd explorer-bff
        npm run build
        popd

        shift 
        ;;
    -s | --start)
        nats-server &

        pushd archipelago-service
        npm run start &
        popd

        pushd explorer-bff
        npm run start &
        popd

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
