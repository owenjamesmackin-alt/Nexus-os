#!/bin/sh
# Runs inside an Alpine container. Uses Alpine's official mkimage to make a live ISO,
# then adds the prebuilt NEXUS disk image to it with xorriso.
set -eu
log() { printf '\n\033[1;38;5;39m>> %s\033[0m\n' "$*"; }

MIRROR=${MIRROR:-https://dl-cdn.alpinelinux.org/alpine}
. /etc/os-release
V=${VERSION_ID%.*}                      # e.g. 3.22
ARCH=$(uname -m)

log "Installing ISO tooling (Alpine $V)"
apk add --no-cache alpine-sdk build-base apk-tools alpine-conf busybox fakeroot xorriso \
  squashfs-tools mtools dosfstools grub-efi git sudo >/dev/null
[ "$ARCH" = x86_64 ] && apk add --no-cache syslinux >/dev/null

adduser -D builder
addgroup builder abuild
echo "builder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/builder
su builder -c 'abuild-keygen -i -a -n' >/dev/null

log "Fetching aports ($V-stable)"
su builder -c "git clone --depth=1 --branch $V-stable https://gitlab.alpinelinux.org/alpine/aports.git /home/builder/aports"

cp /work/inner/iso/mkimg.nexus.sh /work/inner/iso/genapkovl-nexus.sh /home/builder/aports/scripts/
mkdir -p /home/builder/nexus-iso-files
cp /work/inner/iso/nexus-install /work/inner/iso/motd /home/builder/nexus-iso-files/
find /home/builder/nexus-iso-files /home/builder/aports/scripts/*nexus* -type f -exec sed -i 's/\r$//' {} +
chown -R builder:builder /home/builder
mkdir -p /iso && chown builder:builder /iso

log "Running mkimage"
su builder -c "cd /home/builder && NEXUS_FILES=/home/builder/nexus-iso-files sh aports/scripts/mkimage.sh \
  --tag nexus --outdir /iso --arch $ARCH \
  --repository $MIRROR/v$V/main --repository $MIRROR/v$V/community \
  --profile nexus"

BASE=$(ls /iso/*.iso | head -n1)
FINAL="/work/out/nexus-os-$SHORT-installer.iso"
IMG="/work/out/nexus-os-$SHORT.qcow2"

log "Adding NEXUS disk image to the ISO"
xorriso -indev "$BASE" -outdev "$FINAL" -boot_image any replay \
  -map "$IMG" "/nexus/nexus-os-$SHORT.qcow2" -commit
( cd /work/out && sha256sum "$(basename "$FINAL")" > "SHA256SUMS-$SHORT-iso.txt" )
chown "${HOST_UID:-0}:${HOST_GID:-0}" "$FINAL" 2>/dev/null || true
log "Done: $FINAL"
