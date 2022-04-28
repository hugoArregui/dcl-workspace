# Requeriments

- Ensure nats-server is installed
- Install protoc if you want to be able to compile the protobuf protocols

# Usage

```
./build.sh usage:

--clone: clone projects
-b --build: run npm run build on each project
-i --install: run npm ci on each project
-s --start: run npm run start on each project
-p --protocol: compile protocol and copy it everywhere
```

## Example

Build only archipelago-service, but start archipelago-service and explorer-bff

```
PROJECTS="archipelago-service" ./build.sh --build && PROJECTS="archipelago-service explorer-bff" ./build.sh --start
```
