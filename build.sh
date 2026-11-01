#!/bin/sh
# NEXUS OS image builder (host side).
# Needs Docker (Docker Desktop on Mac/Windows, or docker on Linux).
#
#   ./build.sh                       build for your CPU (arm64 on Apple Silicon, x86_64 elsewhere)
#   ARCH=x86_64 ./build.sh           force x86_64 (slow under emulation on Apple Silicon)
#   NEXUS_DESKTOP=0 ./build.sh       console only: smallest, most reliable
#   DISK_MB=16384 ./build.sh         bigger virtual disk (default 6144)
#   FORMATS="qcow2 vhdx" ./build.sh  choose output formats (qcow2 vhdx vhd vdi vmdk raw)
#   NEXUS_KEYMAP=gb NEXUS_TZ=Europe/London ./build.sh
set -eu
cd "$(dirname "$0")"

command -v docker >/dev/null 2>&1 || { echo "Docker is required: https://docs.docker.com/get-docker/"; exit 1; }

HOST=$(uname -m)
case "${ARCH:-$HOST}" in
  arm64|aarch64) PLATFORM=linux/arm64 ;;
  x86_64|amd64)  PLATFORM=linux/amd64 ;;
  *) echo "Unsupported ARCH '${ARCH:-$HOST}' (use arm64 or x86_64)"; exit 1 ;;
esac

mkdir -p out

# forward only the settings you actually set
ENVS=""
for v in DISK_MB NEXUS_DESKTOP NEXUS_USER NEXUS_PASSWORD NEXUS_AUTOLOGIN NEXUS_KEYMAP \
         NEXUS_TZ NEXUS_HOSTNAME ALPINE_BRANCH FORMATS; do
  ENVS="$ENVS -e $v"
done

echo ">> Building NEXUS OS for $PLATFORM ..."
# shellcheck disable=SC2086
docker run --rm --privileged --platform "$PLATFORM" \
  -v "$PWD":/work \
  -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
  $ENVS \
  alpine:latest sh /work/inner/build-image.sh

echo ">> Done. Images are in ./out"
ls -lh out
