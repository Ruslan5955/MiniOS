# Gloria OS

Gloria OS is an experimental Debian 12 live system with an XFCE desktop styled to feel familiar to Windows 11 users.

## Build ISO
The GitHub Actions workflow **Build Gloria OS ISO** builds a bootable 64-bit ISO and publishes it as a workflow artifact.

1. Open the repository's **Actions** tab.
2. Select **Build Gloria OS ISO**.
3. Click **Run workflow** (or wait for the workflow triggered by this commit).
4. Open the completed run and download the `Gloria-OS-amd64` artifact.
5. Extract the downloaded ZIP to get the ISO.

The ISO is intended for x86_64 Intel and AMD computers. The final size depends on package versions and may not be exactly 2 GB.

## Write to USB
Use Rufus or balenaEtcher to write the ISO to a USB drive (8 GB or larger recommended). Writing erases the selected USB drive. Choose the USB device from the computer's boot menu to try Gloria OS.

This is a live Linux system, not Microsoft Windows. Back up important files before testing; hardware support varies.
