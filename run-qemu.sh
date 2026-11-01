#!/bin/sh
# Quick-boot a built NEXUS OS image with QEMU (handy for testing before you set up UTM).
#   ./run-qemu.sh                     picks the image for your CPU in ./out
#   ./run-qemu.sh out/nexus-os-arm64.qcow2
# Needs QEMU with UEFI firmware (macOS: brew install qemu; Linux: qemu-system + ovmf/edk2).
set -eu
cd "$(dirname "$0")"

case "$(uname -m)" in arm64|aarch64) DEF=arm64 ;; *) DEF=x86_64 ;; esac
IMG="${1:-out/nexus-os-$DEF.qcow2}"
[ -f "$IMG" ] || { echo "Image not found: $IMG (run ./build.sh first)"; exit 1; }

case "$IMG" in *arm64*) TARGET=arm64 ;; *) TARGET=x86_64 ;; esac
HOSTARCH=$DEF
OS=$(uname -s)

find_fw() {
  for f in "$@"; do [ -f "$f" ] && { echo "$f"; return 0; }; done
  return 1
}

ACCEL="-accel tcg"; CPU="-cpu max"
if [ "$TARGET" = "$HOSTARCH" ]; then
  if [ "$OS" = Darwin ]; then ACCEL="-accel hvf"; CPU="-cpu host"
  elif [ -w /dev/kvm ]; then ACCEL="-accel kvm"; CPU="-cpu host"; fi
fi

if [ "$TARGET" = arm64 ]; then
  FW=$(find_fw /opt/homebrew/share/qemu/edk2-aarch64-code.fd /usr/local/share/qemu/edk2-aarch64-code.fd \
       /usr/share/AAVMF/AAVMF_CODE.fd /usr/share/qemu-efi-aarch64/QEMU_EFI.fd) \
       || { echo "No aarch64 UEFI firmware found (install qemu / qemu-efi-aarch64)"; exit 1; }
  exec qemu-system-aarch64 -machine virt $ACCEL $CPU -smp 4 -m 4096 \
    -bios "$FW" \
    -drive file="$IMG",if=virtio,format=qcow2 \
    -device virtio-gpu-pci -device qemu-xhci -device usb-kbd -device usb-tablet \
    -nic user,model=virtio-net-pci
else
  FW=$(find_fw /usr/share/OVMF/OVMF_CODE.fd /usr/share/edk2/ovmf/OVMF_CODE.fd /usr/share/qemu/OVMF.fd \
       /opt/homebrew/share/qemu/edk2-x86_64-code.fd /usr/share/ovmf/OVMF.fd) \
       || { echo "No x86_64 UEFI firmware found (install ovmf / edk2-ovmf)"; exit 1; }
  exec qemu-system-x86_64 -machine q35 $ACCEL $CPU -smp 4 -m 4096 \
    -bios "$FW" \
    -drive file="$IMG",if=virtio,format=qcow2 \
    -device virtio-vga -device qemu-xhci -device usb-kbd -device usb-tablet \
    -nic user,model=virtio-net-pci
fi
