#!/bin/bash

set -eo pipefail

# Entrypoint wrapper that launches entrypoint-demoter (as PID 1) for the Bedrock
# server, optionally enabling a graceful "announce, wait, then stop" on SIGTERM.
#
# Why a wrapper: entrypoint-demoter is PID 1 and handles SIGTERM by writing the
# --stdin-on-term message ("stop") to the server's stdin (the save-clean path).
# To also warn players first, its v0.5.0 --stdin-on-term-announce / -delay flags
# must be present on the command line *before* the process starts, so we build the
# argument list here from the environment and exec into it.
#
# Default behaviour is UNCHANGED: with no env set, SIGTERM still sends "stop"
# immediately (same args as the previous static ENTRYPOINT).
#
# Opt-in graceful shutdown:
#   STOP_SERVER_ANNOUNCE_DELAY  Whole seconds to wait between the announce and the
#                               stop. Unset or 0 => disabled (immediate stop).
#                               Keep it shorter than the container's stop grace
#                               period (docker `stop -t` / ECS stopTimeout / a Spot
#                               interruption's 2-minute window) so the world save
#                               isn't cut short by SIGKILL.
#   STOP_SERVER_ANNOUNCE        Console line written as the heads-up. The %delay%
#                               token is replaced by entrypoint-demoter with the
#                               whole-second value of the delay.
#                               Default: "say Server shutting down in %delay% seconds"

demoterArgs=(--match /data --debug)

delay="${STOP_SERVER_ANNOUNCE_DELAY:-0}"
if [[ "${delay}" =~ ^[0-9]+$ ]] && (( delay > 0 )); then
  announce="${STOP_SERVER_ANNOUNCE:-say Server shutting down in %delay% seconds}"
  demoterArgs+=(--stdin-on-term-announce "${announce}" --stdin-on-term-delay "${delay}s")
fi

demoterArgs+=(--stdin-on-term stop)

exec /usr/local/bin/entrypoint-demoter "${demoterArgs[@]}" /opt/bedrock-entry.sh
