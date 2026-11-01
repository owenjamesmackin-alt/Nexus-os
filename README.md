# NEXUS OS — bootable image kit (v0.1)

This kit builds a **real, bootable UEFI disk image** of NEXUS OS that you can import into UTM, VirtualBox, Hyper-V, VMware or QEMU.

**What NEXUS OS is, honestly:** a custom Linux distribution built on top of Alpine Linux (Linux kernel, OpenRC, musl, apk) with its own branding, `nexus` command and package front-end, themes, and a themed Openbox/Xorg desktop. It is *not* a from-scratch kernel and desktop environment — that's a multi-year effort. This is the practical foundation the rest of the blueprint can grow on.

> **Status:** the scripts were written and syntax-checked but I could not boot the finished image where this was authored. Expect to fix small things on your first build (package names, desktop quirks). The `NEXUS_DESKTOP=0` console build is the most reliable fallback.

---

## 1. Build the image

You need **Docker** (Docker Desktop on Mac/Windows) and ~6 GB free disk plus a network connection.

```sh
cd nexus-os
./build.sh                  # Mac / Linux / WSL
.\build.ps1                 # Windows PowerShell
```

The build produces images for **your CPU**: arm64 on Apple Silicon, x86_64 on Intel/AMD. Output lands in `out/`:

| File | Use with |
|---|---|
| `nexus-os-<arch>.qcow2` | **UTM**, QEMU/KVM, Proxmox |
| `nexus-os-<arch>.vhdx` | Hyper-V (Generation 2) |
| `nexus-os-<arch>.vhd` | Hyper-V / Azure-style tools |
| `nexus-os-<arch>.vdi` | VirtualBox |
| `nexus-os-<arch>.vmdk` | VMware Workstation / Fusion |
| `SHA256SUMS-<arch>.txt` | integrity check |

Build options (environment variables):

```sh
NEXUS_DESKTOP=0 ./build.sh                 # console only (smallest, safest)
DISK_MB=16384 ./build.sh                   # bigger virtual disk (default 6144)
FORMATS="qcow2 raw" ./build.sh             # choose formats
NEXUS_USER=owen NEXUS_PASSWORD=secret ./build.sh
NEXUS_KEYMAP=gb NEXUS_TZ=Europe/London ./build.sh
NEXUS_AUTOLOGIN=0 ./build.sh               # show a login prompt instead of auto-login
ARCH=x86_64 ./build.sh                     # force the other architecture (slow emulation on Apple Silicon)
```

Default login: **nexus / nexus** (root has the same password). Change it on first boot — the setup wizard offers to.

---

## 2. Boot it

### UTM (Mac) — recommended
1. Build on your Mac so you get the native `nexus-os-arm64.qcow2` (Apple Silicon) or `x86_64` (Intel).
2. UTM → **Create a New Virtual Machine** → **Virtualize** (Apple Silicon + arm64 image) or **Emulate** (different architecture) → **Other**.
3. Tick **Skip ISO boot**. Give it 4 GB RAM and 2–4 cores.
4. Storage: finish the wizard with any size, then in the VM's settings **delete the default drive** and **New Drive → Import…** → choose the `.qcow2`.
5. System / QEMU settings: make sure **UEFI Boot** is enabled.
6. Display: **virtio-gpu-pci** (arm64) or **virtio-vga** (x86_64).
7. Start it. GRUB shows a NEXUS menu, then the desktop appears.

### VirtualBox
New VM → Linux / Other 64-bit → use existing disk `…vdi`. Settings → System → **Enable EFI**. Graphics controller: VMSVGA. (VirtualBox on Apple Silicon needs the arm64 image.)

### Hyper-V
Create **Generation 2** VM → use existing virtual hard disk `…vhdx`. Settings → Security → **disable Secure Boot** (GRUB here is unsigned). 

### VMware Workstation / Fusion
New VM → custom → Linux → use existing disk `…vmdk`. Edit the `.vmx`/VM options to use **UEFI firmware**.

### Plain QEMU
`./run-qemu.sh` (finds UEFI firmware automatically; best effort).

> A virtual disk is not automatically bootable on real hardware. This image is UEFI/GPT, so it *can* be written to a USB/SSD (`dd` the `.raw` export), but a proper physical installer isn't built yet.

---


## 2b. Installer ISO

```sh
./build.sh          # first: makes out/nexus-os-<arch>.qcow2
./build-iso.sh      # then: makes out/nexus-os-<arch>-installer.iso
```

The ISO boots a small live system (Alpine's official `mkimage`) with the NEXUS disk image on it. Boot it, log in as `root` (no password) and run `nexus-install`. It asks which disk to erase, writes the image, and grows it to fill the disk. UEFI only.

- **UTM / VM:** create a VM, attach the ISO as a CD/DVD, add a blank disk (8 GB or more), boot the ISO and run `nexus-install`. For plain VMs the ready-made `.qcow2` is simpler.
- **USB for a real PC:** write the ISO with Balena Etcher, Rufus (DD mode) or `dd`, then boot it in UEFI mode.
- The ISO is built from your own image, so rebuild it after every `./build.sh`. It was not boot-tested where it was written.

## 3. Using NEXUS OS

**Desktop shortcuts** (Super = Windows/Command key): `Super+Enter` terminal · `Super+Space` or `Super+D` launcher · `Super+F` files · `Super+C` control centre · `Super+1-4` workspaces · `Super+Q` close window.

**NEXUS CMD**
```sh
nexus install firefox git python     # NEXUS PKG (apk underneath: signed packages, dependency solving)
nexus remove firefox
nexus update && nexus upgrade
nexus search browser
nexus list  |  nexus info firefox  |  nexus history
nexus repo list|add URL|remove URL
nexus repair  |  nexus clean  |  nexus check
nexus control                        # control centre (CPU/RAM/storage/services/network/security)
nexus theme list | apply ember | apply aurora | export neon
nexus resize-disk                    # after enlarging the virtual disk in your hypervisor
nexus ai "how do I find large files?"   # needs ANTHROPIC_API_KEY; asks before running anything
```

**Making the disk bigger:** enlarge it in the hypervisor (e.g. `qemu-img resize nexus-os-arm64.qcow2 +20G`), boot, run `nexus resize-disk`.

**Snapshots / clones / backups:** use your hypervisor (UTM/VirtualBox/Hyper-V/VMware snapshots, or copy the image file).

---

## 4. Blueprint status

| Blueprint item | Status in v0.1 |
|---|---|
| Custom visual identity (dark, neon blue/purple) | ✅ 3 themes (Neon, Ember, Aurora), wallpapers, terminal colours, boot menu, MOTD |
| Custom window manager / shell / taskbar / launcher | 🟡 themed Openbox + tint2 + dmenu launcher (configured, not written from scratch) |
| Workspaces, shortcuts, context menu, system tray | ✅ 4 workspaces, key bindings, right-click menu, tray |
| Theme editor / import / export | 🟡 `nexus theme` (CLI), theme files are 6 colour values |
| Custom icons, fonts, sounds, animations, widgets | ❌ stock icons/fonts for now |
| Custom login/lock/shutdown screens | ❌ auto-login + text console login |
| Control Centre | 🟡 text-mode `nexus control` |
| NEXUS CMD + package manager | ✅ `nexus` command on a signed, dependency-solving backend (apk) |
| App Store GUI sharing the same backend | ❌ not built (backend is ready for it) |
| Rollback of updates | ❌ use VM snapshots |
| VHD/VHDX/QCOW2/RAW image support | ✅ plus VDI and VMDK |
| VHD Builder (GUI) | 🟡 `build.sh` / `build.ps1` command-line builder |
| Disk expand / integrity | ✅ `nexus resize-disk`, SHA-256 sums |
| System installer (physical, partitioning, wizard) | ❌ image-based only; first-boot wizard exists |
| Dev tools (Builder, Image Creator, …) | 🟡 the build scripts are the Builder + Image Creator |
| AI assistant | 🟡 `nexus ai` CLI, confirms before running commands |
| Cybersecurity environment | ❌ install tools yourself (`nexus install nmap wireshark …`) |

## 5. Troubleshooting

- **Black screen after GRUB:** pick *verbose boot* or *console only* in the GRUB menu and read the messages.
- **Desktop doesn't start:** log in on the console, run `startx`, then check `~/.xsession-errors`. `nexus desktop off` disables auto-start.
- **No network:** the image uses DHCP on `eth0`; use "NAT/Shared" networking in your hypervisor.
- **Build fails downloading packages:** re-run; if Alpine renamed a package, tell me the error text and I'll fix the script.
- **Windows:** line endings are normalised automatically, but run the build from PowerShell or WSL.
