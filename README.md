# Initializing repo


- Ensure nats-server is installed
```
git submodule init
```

# Usage

Example: Build only archipelago-service, but start archipelago-service and explorer-bff

```
PROJECTS="archipelago-service" ./build.sh --build && PROJECTS="archipelago-service explorer-bff" ./build.sh --start
```
