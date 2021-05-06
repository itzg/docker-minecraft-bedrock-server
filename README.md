[![Docker Pulls](https://img.shields.io/docker/pulls/itzg/minecraft-bedrock-server.svg)](https://hub.docker.com/r/itzg/minecraft-bedrock-server/)
[![GitHub Issues](https://img.shields.io/github/issues-raw/itzg/docker-minecraft-bedrock-server.svg)](https://github.com/itzg/docker-minecraft-bedrock-server/issues)
[![Build](https://github.com/itzg/docker-minecraft-bedrock-server/workflows/Build/badge.svg)](https://github.com/itzg/docker-minecraft-bedrock-server/actions?query=workflow%3ABuild)
[![Discord](https://img.shields.io/discord/660567679458869252?label=Discord&logo=discord)](https://discord.gg/ScbTrAw)
[![](https://img.shields.io/badge/Donate-Buy%20me%20a%20coffee-orange.svg)](https://www.buymeacoffee.com/itzg)

## Quickstart

The following starts a Bedrock Dedicated Server running a default version and
exposing the default UDP port: 

```bash
docker run -d -it -e EULA=TRUE -p 19132:19132/udp itzg/minecraft-bedrock-server
```

## Looking for a Java Edition Server

For Minecraft Java Edition you'll need to use this image instead:

[itzg/minecraft-server](https://hub.docker.com/r/itzg/minecraft-server)

## Environment Variables

### Container Specific

- `EULA` (no default) : must be set to `TRUE` to 
  accept the [Minecraft End User License Agreement](https://minecraft.net/terms)
- `VERSION` (`LATEST`) : can be set to a specific server version or the following special values can be used:
  - `LATEST` : determines the latest version and can be used to auto-upgrade on container start
  - `PREVIOUS` : uses the previously maintained major version. Useful when the mobile app is gradually being upgraded across devices
  - `1.11` : the latest version of 1.11
  - `1.12` : the latest version of 1.12
  - `1.13` : the latest version of 1.13
  - `1.14` : the latest version of 1.14
  - `1.16` : the latest version of 1.16
  - otherwise any specific server version can be provided to allow for temporary bug avoidance, etc
- `UID` (default derived from `/data` owner) : can be set to a specific user ID to run the
  bedrock server process
- `GID` (default derived from `/data` owner) : can be set to a specific group ID to run the
  bedrock server process
- `PACKAGE_BACKUP_KEEP` (`2`) : how many package backups to keep

### Server Properties

The following environment variables will set the equivalent property in `server.properties`, where each [is described here](https://minecraft.gamepedia.com/Server.properties#Bedrock_Edition_3).

- `SERVER_NAME`
- `SERVER_PORT`
- `SERVER_PORT_V6`
- `GAMEMODE`
- `DIFFICULTY`
- `LEVEL_TYPE`
- `ALLOW_CHEATS`
- `MAX_PLAYERS`
- `ONLINE_MODE`
- `WHITE_LIST`
- `VIEW_DISTANCE`
- `TICK_DISTANCE`
- `PLAYER_IDLE_TIMEOUT`
- `MAX_THREADS`
- `LEVEL_NAME`
- `LEVEL_SEED`
- `DEFAULT_PLAYER_PERMISSION_LEVEL`
- `TEXTUREPACK_REQUIRED`
- `SERVER_AUTHORITATIVE_MOVEMENT`
- `PLAYER_MOVEMENT_SCORE_THRESHOLD`
- `PLAYER_MOVEMENT_DISTANCE_THRESHOLD`
- `PLAYER_MOVEMENT_DURATION_THRESHOLD_IN_MS`
- `CORRECT_PLAYER_MOVEMENT`

For example, to configure a flat, creative server instead of the default use:

```bash
docker run -d -it --name bds-flat-creative \
  -e EULA=TRUE -e LEVEL_TYPE=flat -e GAMEMODE=creative \
  -p 19132:19132/udp itzg/minecraft-bedrock-server
```

## Exposed Ports

- **UDP** 19132 : the Bedrock server port. 
  **NOTE** that you must append `/udp` when exposing the port, such as `-p 19132:19132/udp`
  
## Volumes

- `/data` : the location where the downloaded server is expanded and ran. Also contains the
  configuration properties file `server.properties`

You can create a `named volume` and use it as:

```shell
docker volume create mc-volume
docker run -d -it --name mc-server -e EULA=TRUE -p 19132:19132/udp -v mc-volume:/data itzg/minecraft-bedrock-server
```

If you're using a named volume and want the bedrock process to run as a non-root user then you will need to pre-create the volume and `chown` it to the desired user.

For example, if you want the bedrock server to run with user ID 1000 and group ID 1000, then create and chown the volume named "bedrock" using:

```shell script
docker run --rm -v bedrock:/data alpine chown 1000:1000 /data
```

If using `docker run` then simply reference that volume "bedrock" in the `-v` argument. If using a compose file, declare the volume as an external using this type of declaration:

```yaml
volumes:
  bedrock:
    external:
      name: bedrock
```

## Connecting

When running the container on your LAN, you can find and connect to the dedicated server
in the "LAN Games" part of the "Friends" tab, such as:

![](docs/example-client.jpg)

## Permissions

The Bedrock Dedicated Server requires permissions be defined with XUIDs. There are various tools to look these up online and they
are also printed to the log when a player joins. There are 3 levels of permissions and 3 options to configure each group:

- `OPS` is used to define operators on the server.  
```shell
-e OPS "1234567890,0987654321"
```
- `MEMBERS` is used to define the members on the server.
```shell
-e MEMBERS "1234567890,0987654321"
```
- `VISITORS` is used to define visitors on the server.
```shell
-e VISITORS "1234567890,0987654321"
```

## Whitelist

There are two ways to handle a whitelist. The first is to set the `WHITE_LIST` environment variable to true and map in [a whitelist.json](https://minecraft.gamepedia.com/Whitelist.json) that is custom-crafted to the container. The other is to use the `WHITE_LIST_USERS` environment variable to list users that should be whitelisted. This list is player names. The server will look up the names and add in the XUID to match the player.

```shell
-e WHITE_LIST_USERS="player1,player2,player3"
```

> Starting with 1.16.230.50, `ALLOW_LIST`, `ALLOW_LIST_USERS`, and the file `allowlist.json` will be used instead.

## More information

For more information about managing Bedrock Dedicated Servers in general, [check out this Reddit post](https://old.reddit.com/user/ProfessorValko/comments/9f438p/bedrock_dedicated_server_tutorial/).

## Executing server commands

Assuming you started container with stdin and tty enabled (such as using `-it`), you can attach to the container's console by its name or ID using:

```shell script
docker attach CONTAINER_NAME_OR_ID
``` 

While attached, you can execute any server-side commands, such as op'ing your player to be admin:

```
op YOUR_XBOX_USERNAME
```

When finished, detach from the server console using Ctrl-p, Ctrl-q

## Deploying with Docker Compose

The [examples](examples) directory contains [an example Docker compose file](examples/docker-compose.yml) that declares:
- a service running the bedrock server container and exposing UDP port 19132
- a volume to be attached to the service

The service configuration includes some examples of configuring the server properties via environment variables:
```yaml
environment:
  EULA: "TRUE"
  GAMEMODE: survival
  DIFFICULTY: normal
```

From with in the `examples` directory, you can deploy the composition by using:

```bash
docker-compose up -d
```

You can follow the logs using:
```bash
docker-compose logs -f bds
```

## Deploying with Kubernetes

The [examples](examples) directory contains [an example Kubernetes manifest file](examples/kubernetes.yml) that declares:
- a peristent volume claim (using default storage class)
- a pod deployment that uses the declared PVC
- a service of type LoadBalancer

The pod deployment includes some examples of configuring the server properties via environment variables:
```yaml
env:
- name: EULA
  value: "TRUE"
- name: GAMEMODE
  value: survival
- name: DIFFICULTY
  value: normal
```

The file is deploy-able as-is on most clusters, but has been confirmed on [Docker for Desktop](https://docs.docker.com/docker-for-windows/kubernetes/) and [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/docs/):

```bash
kubectl apply -f examples/kubernetes.yml
```

You can follow the logs of the deployment using:

```bash
kubectl logs -f deployment/bds
```

## Solutions for backing up data

- [kaiede/minecraft-bedrock-backup image](https://hub.docker.com/r/kaiede/minecraft-bedrock-backup) provided by @Kaiede