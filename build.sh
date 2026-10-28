#!/bin/bash
# Запускается внутри контейнера debian:bookworm (см. .github/workflows/build-iso.yml)
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y live-build xorriso isolinux syslinux-common mtools dosfstools \
    grub-pc-bin grub-efi-amd64-bin debootstrap squashfs-tools ca-certificates
chmod +x auto/* config/hooks/live/* || true
lb config
lb build
mv -f live-image-*.iso MiniOS.iso
sha256sum MiniOS.iso > MiniOS.iso.sha256
ls -lh MiniOS.iso
SIZE=$(stat -c %s MiniOS.iso)
if [ "$SIZE" -gt 1600000000 ]; then echo "ВНИМАНИЕ: образ больше 1.6 ГБ, на флешку 2 ГБ может не влезть"; fi
