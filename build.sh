#!/bin/bash
set -euo pipefail

original_root_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
final_iso_path="$original_root_dir/GameXOSTR.iso"
root_dir="$original_root_dir"

if [[ "$(id -u)" -ne 0 ]]; then
	echo "Run this script as root: sudo bash build.sh" >&2
	exit 1
fi

scratch_dir=""
cleanup() {
	if [[ -n "$scratch_dir" && -d "$scratch_dir" ]]; then
		rm -rf "$scratch_dir"
	fi
}
trap cleanup EXIT

if command -v findmnt >/dev/null 2>&1; then
	mount_opts="$(findmnt -T "$root_dir" -no OPTIONS 2>/dev/null || true)"
	if [[ -n "$mount_opts" && ( "$mount_opts" == *noexec* || "$mount_opts" == *nodev* ) ]]; then
		scratch_dir="$(mktemp -d /tmp/gamexostr-build.XXXXXX)"
		cp -a "$original_root_dir/." "$scratch_dir/"
		root_dir="$scratch_dir"
		echo "Repo is on a noexec/nodev mount; building in $root_dir"
	fi
fi

live_build_dir="$root_dir/live-build"

if ! chroot / /bin/true >/dev/null 2>&1; then
	echo "This environment cannot use chroot (missing CAP_SYS_CHROOT or privileged container support)." >&2
	echo "Run the build on a Debian/Ubuntu host or a privileged container/VM." >&2
	exit 1
fi

for tool in lb debootstrap mksquashfs xorriso grub-mkrescue mcopy isohybrid; do
	if ! command -v "$tool" >/dev/null 2>&1; then
		echo "Required build tool not found: $tool" >&2
		exit 1
	fi
done

cd "$live_build_dir"
lb clean --purge
sh auto/config
lb build

iso_path="$(find "$live_build_dir" -maxdepth 1 -type f -name '*.iso' -print -quit)"
if [[ -z "$iso_path" ]]; then
	echo "live-build completed without producing an ISO image" >&2
	exit 1
fi

install -m 0644 "$iso_path" "$final_iso_path"
echo "GameXOSTR ISO created: $final_iso_path"
