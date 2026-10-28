#!/bin/bash
# Собирает MiniOS. Запускается внутри контейнера debian:bookworm.
# Вся конфигурация live-build создаётся здесь же, поэтому в репозитории
# достаточно файлов: build.sh, miniguard, guard.py и .github/workflows/build-iso.yml
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

ARCH="${ARCH:-amd64}"
case "$ARCH" in
  amd64) KERNEL_FLAVOUR=amd64 ;;
  i386) KERNEL_FLAVOUR=686-pae ;;
  *) echo "ОШИБКА: ARCH должен быть amd64 или i386"; exit 2 ;;
esac

for f in miniguard guard.py; do
  [ -f "$f" ] || { echo "ОШИБКА: в репозитории нет файла $f"; exit 1; }
done

rm -rf auto config
mkdir -p auto config/package-lists config/hooks/live
INC=config/includes.chroot_after_packages
mkdir -p $INC/usr/local/bin $INC/usr/local/lib/miniguard $INC/etc/skel/Desktop
cp miniguard $INC/usr/local/bin/miniguard
cp guard.py $INC/usr/local/lib/miniguard/guard.py

cat > auto/config <<EOF
#!/bin/sh
set -e
lb config noauto \
	--distribution bookworm \
	--architectures "$ARCH" \
	--archive-areas "main contrib non-free non-free-firmware" \
	--binary-images iso-hybrid \
	--debian-installer none \
	--memtest none \
	--apt-recommends false \
	--apt-indices false \
	--firmware-chroot true \
	--linux-flavours "$KERNEL_FLAVOUR" \
	--chroot-squashfs-compression-type xz \
	--iso-volume MINIOS \
	--iso-application "MiniOS" \
	--bootappend-live "boot=live components quiet locales=ru_RU.UTF-8 keyboard-layouts=us,ru keyboard-options=grp:alt_shift_toggle hostname=minios" \
	"${@}"
EOF

cat > config/package-lists/minios.list.chroot <<'EOF'
xorg
xfce4
xfce4-terminal
lightdm
lightdm-gtk-greeter
policykit-1-gnome
dbus-x11
adwaita-icon-theme
fonts-dejavu
thunar-volman
gvfs
gvfs-backends
udisks2
mousepad
ristretto
file-roller
network-manager
network-manager-gnome
wpasupplicant
ca-certificates
firefox-esr
firefox-esr-l10n-ru
firmware-iwlwifi
firmware-realtek
firmware-atheros
firmware-misc-nonfree
gparted
parted
ntfs-3g
exfatprogs
dosfstools
e2fsprogs
smartmontools
testdisk
gddrescue
hdparm
nvme-cli
chntpw
clamav
clamav-freshclam
python3
locales
console-setup
keyboard-configuration
sudo
htop
pciutils
usbutils
lshw
curl
wget
rsync
nano
iputils-ping
EOF

cat > config/hooks/live/0100-setup.hook.chroot <<'EOF'
#!/bin/sh
set -e
printf 'ru_RU.UTF-8 UTF-8\nen_US.UTF-8 UTF-8\n' > /etc/locale.gen
locale-gen
chmod +x /usr/local/bin/miniguard
chmod +x /etc/skel/Desktop/*.desktop || true
systemctl disable clamav-freshclam.service || true
freshclam --quiet || echo "freshclam: база не обновлена при сборке; на ПК выполните: sudo freshclam"
EOF

cat > $INC/etc/skel/Desktop/miniguard.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=MiniGuard: проверить диски Windows
Comment=Быстрая офлайн-проверка на вирусы (диски только для чтения)
Exec=xfce4-terminal --hold -T MiniGuard -e "miniguard --clam"
Icon=security-high
Terminal=false
EOF

cat > $INC/etc/skel/Desktop/update-clamav.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Обновить базу ClamAV (нужен интернет)
Exec=xfce4-terminal --hold -T ClamAV -e "sudo freshclam"
Icon=view-refresh
Terminal=false
EOF

chmod +x auto/config config/hooks/live/* $INC/usr/local/bin/miniguard
[ "${PREPARE_ONLY:-0}" = "1" ] && { echo "Конфигурация создана (PREPARE_ONLY)"; exit 0; }

apt-get update
apt-get install -y live-build xorriso isolinux syslinux-common mtools dosfstools \
    grub-pc-bin debootstrap squashfs-tools ca-certificates
if [ "$ARCH" = "amd64" ]; then
  apt-get install -y grub-efi-amd64-bin
else
  apt-get install -y grub-efi-ia32-bin
fi

lb config
grep -q "bookworm" config/bootstrap || { echo "ОШИБКА: lb config не взял bookworm (auto/config не сработал)"; cat config/bootstrap; exit 1; }
lb build

ISO_FILE="$(find . -maxdepth 1 -type f -name "live-image-*.iso" -print -quit)"
[ -n "$ISO_FILE" ] || { echo "ОШИБКА: live-build не создал ISO"; exit 1; }
mv -f "$ISO_FILE" "MiniOS-${ARCH}.iso"
sha256sum "MiniOS-${ARCH}.iso" > "MiniOS-${ARCH}.iso.sha256"
ls -lh "MiniOS-${ARCH}.iso"
SIZE=$(stat -c %s "MiniOS-${ARCH}.iso")
if [ "$SIZE" -gt 1600000000 ]; then echo "ВНИМАНИЕ: образ больше 1.6 ГБ, на флешку 2 ГБ может не влезть"; fi
