# Init

- Ensure nats-server is installed
- `git submodule init`

# Usage

```
./build.sh usage:

-b --build: build projects
-i --install: install projects
-s --start: start projects
-p --protocol: compile protocol and copy it everywhere
```

## Example

Build only archipelago-service, but start archipelago-service and explorer-bff

```
PROJECTS="archipelago-service" ./build.sh --build && PROJECTS="archipelago-service explorer-bff" ./build.sh --start
```
