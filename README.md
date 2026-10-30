# GameXOSTR

GameXOSTR is being built as a Debian Live-based desktop system. This provides a
real Linux kernel, standard PC hardware support, keyboard and touchpad input,
and a live environment that can be installed to a selected drive.

The current image foundation uses XFCE, Calamares, Wine, Firefox ESR, and
Plymouth. The existing bare-metal kernel files are kept as a small research
target; they are not the kernel used by the desktop ISO.

## Build

On Debian or Ubuntu, install `live-build`, `debootstrap`, `squashfs-tools`,
`xorriso`, `grub-pc-bin`, `grub-efi-amd64-bin`, and `mtools`, then run:

```sh
sudo bash build.sh
```

The build produces `GameXOSTR.iso` in the repository root. GitHub Actions builds
the same image and publishes it as the `GameXOSTR-ISO` artifact.

This is an early system foundation, not a finished desktop release. The custom
startup animation, recovery UI, Liquid Glass styling, and GameXOS application
shell still need implementation. Windows application compatibility is provided
through Wine and is not guaranteed for every `.exe` application.
