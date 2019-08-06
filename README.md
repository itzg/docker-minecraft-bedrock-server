[![Docker Pulls](https://img.shields.io/docker/pulls/itzg/minecraft-bedrock-server.svg)](https://hub.docker.com/r/itzg/minecraft-bedrock-server/)
[![GitHub Issues](https://img.shields.io/github/issues-raw/itzg/docker-minecraft-bedrock-server.svg)](https://github.com/itzg/docker-minecraft-bedrock-server/issues)
[![](https://img.shields.io/gitter/room/itzg/dockerfiles.svg?style=flat)](https://gitter.im/itzg/dockerfiles)
[![](https://img.shields.io/badge/Donate-Buy%20me%20a%20coffee-orange.svg)](https://www.buymeacoffee.com/itzg)

## Quickstart

The following starts a Bedrock Dedicated Server running a default version and
exposing the default UDP port: 

```bash
docker run -d -e EULA=TRUE -p 19132:19132/udp itzg/minecraft-bedrock-server
```

## Looking for a Java Edition Server

For Minecraft Java Edition you'll need to use this image instead:

[itzg/minecraft-server](https://hub.docker.com/r/itzg/minecraft-server)

## Environment Variables

- `EULA` (no default) : must be set to `TRUE` to 
  accept the [Minecraft End User License Agreement](https://minecraft.net/terms)
- `VERSION` (1.12) : can be set to a specific server version or just 1.11 or 1.12 to pick
  the latest known version of each
- `UID` (default derived from `/data` owner) : can be set to a specific user ID to run the
  bedrock server process
- `GID` (default derived from `/data` owner) : can be set to a specific group ID to run the
  bedrock server process

## Exposed Ports

- **UDP** 19132 : the Bedrock server port. 
  **NOTE** that you must append `/udp` when exposing the port, such as `-p 19132:19132/udp`
  
## Volumes

- `/data` : the location where the downloaded server is expanded and ran. Also contains the
  configuration properties file `server.properties`
  
## Connecting

When running the container on your LAN, you can find and connect to the dedicated server
in the "LAN Games" part of the "Friends" tab, such as:

![](docs/example-client.jpg)
