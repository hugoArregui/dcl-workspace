# Requeriments

- Ensure nats-server is installed

# Usage

```
./build.sh usage:

--clone: clone projects
--proto: compile protocol and copy it everywhere
--link: link libraries to kernel
--nats: start nats-server
-b --build: run npm run build on each project
-i --install: run npm ci on each project 
-s --start: run npm run start on each project 
```

## Example

Build only archipelago-service, but start nats, archipelago-service and explorer-bff

```
./build.sh -b archipelago-service && ./build.sh --nats -s archipelago-service explorer-bff 
```
