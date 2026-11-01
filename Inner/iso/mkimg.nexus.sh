profile_nexus() {
	profile_standard
	profile_abbrev="nexus"
	title="NEXUS OS Installer"
	desc="NEXUS OS installer: writes the NEXUS OS disk image to a disk."
	arch="x86_64 aarch64"
	kernel_flavors="lts"
	kernel_cmdline="console=tty0 console=ttyS0,115200"
	apks="$apks bash qemu-img sgdisk cloud-utils-growpart e2fsprogs e2fsprogs-extra
		util-linux-misc dosfstools jq curl nano doas"
	apkovl="aports/scripts/genapkovl-nexus.sh"
}
