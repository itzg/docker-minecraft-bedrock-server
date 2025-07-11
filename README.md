[![Docker Pulls](https://img.shields.io/docker/pulls/itzg/minecraft-bedrock-server.svg)](https://hub.docker.com/r/itzg/minecraft-bedrock-server/)
[![GitHub Issues](https://img.shields.io/github/issues-raw/itzg/docker-minecraft-bedrock-server.svg)](https://github.com/itzg/docker-minecraft-bedrock-server/issues)
[![Build](https://github.com/itzg/docker-minecraft-bedrock-server/workflows/CI/badge.svg)](https://github.com/itzg/docker-minecraft-bedrock-server/actions?query=workflow%3ACI)
[![Discord](https://img.shields.io/discord/660567679458869252?label=Discord&logo=discord)](https://discord.gg/ScbTrAw)
[![](https://img.shields.io/badge/Donate-Buy%20me%20a%20coffee-orange.svg)](https://www.buymeacoffee.com/itzg)

## Quickstart

The following starts a Bedrock Dedicated Server running a default version and
exposing the default UDP port:

```bash
docker run -d -it -e EULA=TRUE -p 19132:19132/udp -v mc-bedrock-data:/data itzg/minecraft-bedrock-server
```

> **NOTE**: if you plan on running a server for a longer amount of time it is highly recommended using a management layer such as [Docker Compose](#deploying-with-docker-compose) or [Kubernetes](#deploying-with-kubernetes) to allow for incremental reconfiguration and image upgrades.

## Upgrading to the latest Bedrock server version

With the `VERSION` variable set to "LATEST", which is the default, then the Bedrock server can be upgraded by restarting the container. At every startup, the container checks for the latest version and upgrades, if needed.

The latest preview version can be requested by setting `VERSION` to "PREVIEW".

**NOTE** the Bedrock server software is not bundled into this image. Instead, it is downloaded/upgraded from Mojang only during container startup. As such, releases of this image are independent of releases of Mojang's software. 

## Looking for a Java Edition Server

For Minecraft Java Edition you'll need to use this image instead:

[itzg/minecraft-server](https://hub.docker.com/r/itzg/minecraft-server)

## Environment Variables

### Container Specific

- `EULA` (no default) : must be set to `TRUE` to
  accept the [Minecraft End User License Agreement](https://minecraft.net/terms)
- `VERSION` (default is `LATEST`) : can be set to a specific server version or the following special values can be used:
  - `LATEST` : determines the latest (non-preview) version and can be used to auto-upgrade on container start
  - `PREVIEW` : determines the latest preview version and will auto-upgrade
  - otherwise any specific server version can be provided. If it is a preview version, also set `PREVIEW` to "true"
- `UID` (default derived from `/data` owner) : can be set to a specific user ID to run the
  bedrock server process
- `GID` (default derived from `/data` owner) : can be set to a specific group ID to run the
  bedrock server process
- `TZ` (no default): can be set to a specific timezone like `America/New_York`. This will set the timezone for the Docker container and therefore their logs. Addtionally, if you want to sync the time with the host, you can mount the `/etc/localtime` file from the host to the container like `/etc/localtime:/etc/localtime:ro`.
- `PACKAGE_BACKUP_KEEP` (`2`) : how many package backups to keep
- `DIRECT_DOWNLOAD_URL` (no default): This environment variable can be used to provide a **direct download URL** for the Minecraft Bedrock server `.zip` file. When set, this URL will be used instead of attempting to automatically look up the download link from `minecraft.net`. This is particularly useful for CI/CD environments or when the automatic version lookup is temporarily broken due to website changes. Ensure the URL points directly to the `bedrock-server-VERSION.zip` file.


### Server Properties

The following environment variables will set the equivalent property in `server.properties`, where each [is described here](https://minecraft.wiki/w/Server.properties#Option_keys).
Typically, each property is configured instead by the UPPER_SNAKE_CASE equivalent.

- `SERVER_NAME`
- `GAMEMODE`
- `FORCE_GAMEMODE`
- `DIFFICULTY`
- `ALLOW_CHEATS`
- `MAX_PLAYERS`
- `ONLINE_MODE`
- `WHITE_LIST`
- `ALLOW_LIST`
- `SERVER_PORT`
- `SERVER_PORT_V6`
- `ENABLE_LAN_VISIBILITY`
- `VIEW_DISTANCE`
- `TICK_DISTANCE`
- `PLAYER_IDLE_TIMEOUT`
- `MAX_THREADS`
- `LEVEL_NAME`
- `LEVEL_SEED`
- `LEVEL_TYPE`
- `DEFAULT_PLAYER_PERMISSION_LEVEL`
- `TEXTUREPACK_REQUIRED`
- `CONTENT_LOG_FILE_ENABLED`
- `CONTENT_LOG_LEVEL`
- `CONTENT_LOG_CONSOLE_OUTPUT_ENABLED`
- `COMPRESSION_THRESHOLD`
- `COMPRESSION_ALGORITHM`
- `SERVER_AUTHORITATIVE_MOVEMENT`
- `PLAYER_POSITION_ACCEPTANCE_THRESHOLD`
- `PLAYER_MOVEMENT_SCORE_THRESHOLD`
- `PLAYER_MOVEMENT_ACTION_DIRECTION_THRESHOLD`
- `PLAYER_MOVEMENT_DISTANCE_THRESHOLD`
- `PLAYER_MOVEMENT_DURATION_THRESHOLD_IN_MS`
- `CORRECT_PLAYER_MOVEMENT`
- `SERVER_AUTHORITATIVE_BLOCK_BREAKING`
- `SERVER_AUTHORITATIVE_BLOCK_BREAKING_PICK_RANGE_SCALAR`
- `CHAT_RESTRICTION`
- `DISABLE_PLAYER_INTERACTION`
- `CLIENT_SIDE_CHUNK_GENERATION_ENABLED`
- `BLOCK_NETWORK_IDS_ARE_HASHES`
- `DISABLE_PERSONA`
- `DISABLE_CUSTOM_SKINS`
- `SERVER_BUILD_RADIUS_RATIO`
- `ALLOW_OUTBOUND_SCRIPT_DEBUGGING`
- `ALLOW_INBOUND_SCRIPT_DEBUGGING`
- `FORCE_INBOUND_DEBUG_PORT`
- `SCRIPT_DEBUGGER_AUTO_ATTACH`
- `SCRIPT_DEBUGGER_AUTO_ATTACH_CONNECT_ADDRESS`
- `SCRIPT_WATCHDOG_ENABLE`
- `SCRIPT_WATCHDOG_ENABLE_EXCEPTION_HANDLING`
- `SCRIPT_WATCHDOG_ENABLE_SHUTDOWN`
- `SCRIPT_WATCHDOG_HANG_EXCEPTION`
- `SCRIPT_WATCHDOG_HANG_THRESHOLD`
- `SCRIPT_WATCHDOG_SPIKE_THRESHOLD`
- `SCRIPT_WATCHDOG_SLOW_THRESHOLD`
- `SCRIPT_WATCHDOG_MEMORY_WARNING`
- `SCRIPT_WATCHDOG_MEMORY_LIMIT`
- `OP_PERMISSION_LEVEL`
- `EMIT_SERVER_TELEMETRY`
- `MSA_GAMERTAGS_ONLY`
- `ITEM_TRANSACTION_LOGGING_ENABLED`
- `VARIABLES`

For example, to configure a flat, creative server instead of the default use:

```bash
docker run -d -it --name bds-flat-creative \
  -e EULA=TRUE -e LEVEL_TYPE=flat -e GAMEMODE=creative \
  -p 19132:19132/udp itzg/minecraft-bedrock-server
```

## Exposed Ports

- **UDP** 19132 : the Bedrock server port on IPv4 set by `SERVER_PORT`. The IPv6 port is not exposed by default.
  **NOTE** that you must append `/udp` when exposing the port, such as `-p 19132:19132/udp` and both IPv4 and IPv6 must be enabled on your host machine.

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

The Bedrock Dedicated Server requires permissions be defined with XUIDs. There are various tools to look these up online, such as [MCProfile](https://mcprofile.io/). A player's XUID is also printed to the log when a player joins.

There are 3 levels of permissions and 3 options to configure each group:

- `OPS` is used to define operators on the server.
```shell
-e OPS="1234567890,0987654321"
```
- `MEMBERS` is used to define the members on the server.
```shell
-e MEMBERS="1234567890,0987654321"
```
- `VISITORS` is used to define visitors on the server.
```shell
-e VISITORS="1234567890,0987654321"
```

## Allowlist

There are two ways to handle a whitelist:

The first is to set the `ALLOW_LIST` environment variable to true and map in an [allowlist.json](https://minecraft.wiki/w/Whitelist.json) file (previously known as "whitelist.json") that is custom-crafted to the container.

The other is to set the `ALLOW_LIST_USERS` environment variable to a comma-separated list of gamer tag usernames and their corresponding XUIDs. Each username should be followed by its XUID, separated by a colon. The server will use these details to match the player.

There are various tools to look XUIDs up online and they are also printed to the log when a player joins the server.

```shell
-e ALLOW_LIST_USERS="player1:1234567890,player2:0987654321"
```

## Variables

Custom server variables are supported by Bedrock. Details and usage instructions can be found on the official bedrock documentation, located here:

- [Variables & Secrets - Minecraft Creator Docs](https://learn.microsoft.com/en-us/minecraft/creator/documents/scriptingservers?view=minecraft-bedrock-stable#variables-and-secrets)
- [Variables & Secrets - minecraft/server-admin example](https://learn.microsoft.com/en-us/minecraft/creator/scriptapi/minecraft/server-admin/serversecrets?view=minecraft-bedrock-experimental#getplayerprofilets-1)

Custom server variables are passed in as comma-separated simple key-value pairs or as a full JSON string.

Server variables are parsed into their most likely type (number-like turn into numbers, all other inputs are treated as string) using [jq's `fromjson` command](https://jqlang.github.io/jq/manual/#convert-to-from-json). In the example below, `var1` is a string, `var2` is a number, and `var3` is a string. 

For greater control on types, users can provide a full string JSON representation that is used as-is.

All variables are written to the variables file located at `config/default/variables.json`. There is no support for Module-specific variable handling at this time.

```shell
# passing in simple expressions
-e VARIABLES="var1=customStringValue,var2=1234,var3=true"

# pass in a full json object:
-e VARIABLES='{"mobSpawnRate":22,"enableCheats":true,"worldArray":["My World", "Abc", 123]}'
```

## Mods Addons

Also known as behavior or resource packs, in order to add mods into your server you can follow these steps, tested with [OPS (One Player Sleep)](https://foxynotail.com/addons/ops/) and [bedrocktweaks](https://bedrocktweaks.net/resource-packs/)

1. Install the mcpack or mcaddon on the client side first, just to make it easier to copy the files to the server, for Windows 10 files should be located on `C:\Users\USER\AppData\Local\Packages\Microsoft.MinecraftUWP_*\LocalState\games\com.mojang`.
2. Copy over the folders of the mods from either behavior_packs or resource_packs into the server's volume.
> If you want to install them without using a client you should be able to unzip the mods directly into the server's volume, .mcaddon should go into behavior_packs and .mcpack into resource_packs. Both .mcaddon and .mcpack are actually renamed .zip files.
3. Lastly create on the server's volume `worlds/$level-name/world_behavior_packs.json`, you'll need to add an entry for each mod like on the previous manifest.json, we only need the uuid now called pack_id and the version replacing dots with commas and double quotes with [ ].
> You can also create a `worlds/$level-name/world_resource_packs.json` but I have seen that putting both resource and behavior packs inside the same json works just fine
```
[
	{
		"pack_id" : "5f51f7b7-85dc-44da-a3ef-a48d8414e4d5",
		"version" : [ 3, 0, 0 ]
	}
]
```
4. Restart the server and the mods should be enabled now! when connecting you will get a prompt asking if you want to "Download & Join" or just "Join", You need to Download & Join if you want to actually see the new resource pack added to the server.
This prompt is exclusive to resource packs as these alter how minecraft looks while behavior packs alter how minecraft functions and don't need to be downloaded or installed on the client side.
> If you want to force the resource pack on all clients, there's an option `texturepack-required=false` in `server.properties` that should be changed to `true`.
> Resource packs can be deleted by going into Settings > Storage > Cached Data, then selecting the pack and clicking on the trash can.

For more information [FoxyNoTail](https://www.youtube.com/watch?v=nWBM4UFm0rQ&t=1380s) did a video explaining the same on a server running on Windows.

## More information

For more information about managing Bedrock Dedicated Servers in general, [check out this Reddit post](https://old.reddit.com/user/ProfessorValko/comments/9f438p/bedrock_dedicated_server_tutorial/).

## Executing server commands

This image comes bundled with a script called `send-command` that will send a Bedrock command and argument to the Bedrock server console. The output of the command only be visible in the container logs.

For example:

```
docker exec CONTAINER_NAME_OR_ID send-command gamerule dofiretick false
```

Alternatively, with stdin and tty enabled (such as using `-it`), attach to the container's console by its name or ID using:

```shell script
docker attach CONTAINER_NAME_OR_ID
```

While attached, you can execute any server-side commands, such as op'ing your player to be admin:

```
gamerule dofiretick false
```

When finished, detach from the server console using Ctrl-p, Ctrl-q

## Deploying with Docker Compose

The [examples](examples) directory contains [an example Docker compose file](examples/docker-compose.yml) that declares:
- a service running the bedrock server container and exposing UDP port 19132. In the example is named "bds", short for "Bedrock Dedicated Server", but you can name the service whatever you want
- a volume attached to the service at the container path `/data`

```yaml
services:
  bds:
    image: itzg/minecraft-bedrock-server
    environment:
      EULA: "TRUE"
    ports:
      - "19132:19132/udp"
    volumes:
      - ./data:/data
    stdin_open: true
    tty: true
```

Start the server and run in the background using:

```bash
docker compose up -d
```

You can follow the logs at any time using:

```bash
docker compose logs -f
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

## Community Solutions

- [kaiede/minecraft-bedrock-backup image](https://hub.docker.com/r/kaiede/minecraft-bedrock-backup) by @Kaiede
- [ghcr.io/edward3h/mc-webhook](https://github.com/edward3h/minecraft-webhook) by @edward3h
- [Minecraft Bedrock Server Bridge](https://github.com/macchie/minecraft-bedrock-server-bridge) by @macchie
- [Admincraft](https://github.com/joanroig/Admincraft) by @joanroig

## Tutorials
[@TheTinkerDad]([url](https://github.com/TheTinkerDad)) provides an excellent tutorial on how to host multiple instances on a single port (19132) so that it's discoverable: https://www.youtube.com/watch?v=ds0_ESzjbfs

## Contributing

> When trying to build this Docker Image, ensure that all `.sh` files have a end of line sequence of `LF` not `CLRF` or the build will fail.