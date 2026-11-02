#!/bin/bash
set -euo pipefail

root_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
live_build_dir="$root_dir/live-build"

if [[ "$(id -u)" -ne 0 ]]; then
	echo "Run this script as root: sudo bash build.sh" >&2
	exit 1
fi

if [[ ! -d "$live_build_dir" ]]; then
	echo "Missing live-build directory: $live_build_dir" >&2
	exit 1
fi

for tool in lb debootstrap mksquashfs xorriso; do
	if ! command -v "$tool" >/dev/null 2>&1; then
		echo "Required build tool not found: $tool" >&2
		exit 1
	fi
done

cd "$live_build_dir"

# Clean any stale build artifacts before regenerating the config.
lb clean --purge || true

# The repo stores the live-build config in live-build/auto/config.
if [[ -x "./auto/config" ]]; then
	./auto/config
else
	sh ./auto/config
fi

lb build

# live-build may place the ISO under a nested images/ directory, not necessarily
# directly in the live-build root. Search the tree for the generated ISO.
iso_path="$(find "$live_build_dir" -type f -name '*.iso' -print -quit)"
if [[ -z "$iso_path" ]]; then
	echo "live-build completed without producing an ISO image" >&2
	exit 1
fi

install -m 0644 "$iso_path" "$root_dir/GameXOSTR.iso"
echo "GameXOSTR ISO created: $root_dir/GameXOSTR.iso"
