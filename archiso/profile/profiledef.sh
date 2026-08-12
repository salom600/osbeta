#!/usr/bin/env bash
# shellcheck disable=SC2034
#
# NexoraOS — archiso profile definition
# Builds a hybrid BIOS+UEFI live ISO with NexoraDE preinstalled.
#

# ISO info
iso_name="nexora"
iso_label="NEXORA_$(date +%Y%m)"
iso_publisher="NexoraOS Project <https://github.com/salom600/osbeta>"
iso_application="NexoraOS Live/Install ISO"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"

# Build mode — only ISO for now (netboot could be added later)
buildmodes=('iso')

# Bootloaders — we want both BIOS (syslinux/isolinux) and UEFI (systemd-boot)
# and we also produce a USB-bootable hybrid ISO.
# Note: in archiso >= 67, bios.syslinux.mbr/.eltorito were merged into bios.syslinux,
# and the UEFI modes require the -x64 suffix.
bootmodes=('bios.syslinux'
           'uefi-x64.systemd-boot.esp'
           'uefi-x64.systemd-boot.eltorito')

# Arch — only x86_64 for now; can extend to aarch64 in a matrix later
arch="x86_64"

# pacman config to use inside the build chroot
pacman_conf="pacman.conf"

# airootfs (the live root filesystem) source directory
airootfs_dir="airootfs"

# squashfs compression — zstd for best speed+size balance
squashfs_comp="zstd"
squashfs_comp_opt="-Xcompression-level 15"

# GPG key — leave empty for now; CI can sign later
gpg_key=""

# File permissions — applied to the airootfs at build time.
# Format: ["/path"]="uid:gid:octal_mode"
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/root/customize_airootfs.sh"]="0:0:755"
  ["/usr/local/bin/nexora-panel"]="0:0:755"
  ["/usr/local/bin/nexora-launcher"]="0:0:755"
  ["/usr/local/bin/nexora-settings"]="0:0:755"
  ["/usr/local/bin/nexora-store"]="0:0:755"
  ["/usr/local/bin/nexora-welcome"]="0:0:755"
  ["/usr/local/bin/nexora-installer"]="0:0:755"
  ["/usr/local/bin/nexora-session"]="0:0:755"
  ["/usr/local/bin/nexora-logout"]="0:0:755"
)
