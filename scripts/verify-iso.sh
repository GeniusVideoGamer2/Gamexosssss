#!/usr/bin/env bash
# Read-only structural verification of the GameXOSTR live ISO using xorriso.
#
# Usage: scripts/verify-iso.sh [path/to/GameXOSTR.iso]
#
# Exits 0 only if every check passes. The ISO is only ever opened for reading
# (xorriso -indev); nothing is written to it. Optional environment overrides:
#   EXPECTED_VOLUME_ID  expected ISO volume id (default: GAMEXOSTR)
#   MIN_ISO_MIB         minimum plausible ISO size in MiB (default: 700)
set -euo pipefail

iso="${1:-GameXOSTR.iso}"
expected_volume="${EXPECTED_VOLUME_ID:-GAMEXOSTR}"
min_mib="${MIN_ISO_MIB:-700}"

problems=0
ok()   { printf 'ok:   %s\n' "$*"; }
fail() { printf 'FAIL: %s\n' "$*" >&2; problems=$((problems + 1)); }
die()  { printf 'ISO verification FAILED: %s\n' "$*" >&2; exit 1; }

for tool in xorriso unsquashfs dd od; do
	command -v "$tool" >/dev/null 2>&1 || die "required tool not found: $tool"
done
[[ -f "$iso" ]] || die "$iso does not exist"

size_bytes="$(stat -c '%s' "$iso")"
echo "Verifying $iso ($size_bytes bytes)"

workdir="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/verify-iso.XXXXXX")"
trap 'rm -rf "$workdir"' EXIT
xorriso_err="$workdir/xorriso.stderr"
: > "$xorriso_err"

# Every xorriso call opens the image read-only (-indev).
xo() { xorriso -indev "$iso" "$@" 2>>"$xorriso_err"; }

show_xorriso_stderr() {
	if [[ -s "$xorriso_err" ]]; then
		echo "--- xorriso messages ---" >&2
		cat "$xorriso_err" >&2
		echo "------------------------" >&2
	fi
}

# 1. Size sanity: a desktop live image is far larger than a stub file.
if (( size_bytes >= min_mib * 1024 * 1024 )); then
	ok "size is plausible for a desktop live image (>= ${min_mib} MiB)"
else
	fail "size is only $size_bytes bytes (< ${min_mib} MiB); not a complete live image"
fi

# 2. xorriso must read it as ISO 9660 with the volume id from auto/config.
if ! toc="$(xo -toc)"; then
	show_xorriso_stderr
	die "xorriso failed to open $iso"
fi
printf '%s\n' "$toc"
if grep -Fq "$expected_volume" <<<"$toc"; then
	ok "readable ISO 9660 image with volume id $expected_volume"
else
	show_xorriso_stderr
	die "no ISO 9660 image with volume id '$expected_volume' found in $iso"
fi

# 3. Live system payload written by live-build.
iso_has() {
	local out
	out="$(xo -find "$1" -type f -name "$2")" || return 1
	[[ -n "$out" ]]
}
for spec in "/live|filesystem.squashfs" "/live|vmlinuz*" "/live|initrd.img*"; do
	dir="${spec%%|*}"
	pattern="${spec#*|}"
	if iso_has "$dir" "$pattern"; then
		ok "found $dir/$pattern"
	else
		fail "missing $dir/$pattern"
	fi
done

# 4. El Torito boot catalog must offer both BIOS and UEFI entries.
if et="$(xo -report_el_torito plain)"; then
	printf '%s\n' "$et"
	if grep -Eq '^El Torito boot img[[:space:]]*:.*[[:space:]]BIOS([[:space:]]|$)' <<<"$et"; then
		ok "El Torito BIOS boot entry present"
	else
		fail "no El Torito BIOS boot entry"
	fi
	if grep -Eq '^El Torito boot img[[:space:]]*:.*[[:space:]]UEFI([[:space:]]|$)' <<<"$et"; then
		ok "El Torito UEFI boot entry present"
	else
		fail "no El Torito UEFI boot entry"
	fi
else
	fail "xorriso could not report the El Torito boot catalog"
fi

# 5. Hybrid image: MBR boot signature so it also boots when written to USB.
sig="$(dd if="$iso" bs=1 skip=510 count=2 status=none | od -An -tx1 | tr -d ' \n')"
if [[ "$sig" == "55aa" ]]; then
	ok "MBR boot signature present (isohybrid)"
else
	fail "no MBR boot signature (got '${sig:-none}')"
fi

# 6. The SquashFS root filesystem must be a real Debian 12 live system.
squashfs="$workdir/filesystem.squashfs"
if xorriso -osirrox on -indev "$iso" -extract /live/filesystem.squashfs "$squashfs" 2>>"$xorriso_err" \
	&& [[ -s "$squashfs" ]]; then
	if unsquashfs -s "$squashfs" >/dev/null 2>"$workdir/unsquashfs.stderr"; then
		ok "filesystem.squashfs is a valid SquashFS image"
	else
		cat "$workdir/unsquashfs.stderr" >&2
		fail "filesystem.squashfs is not a valid SquashFS image"
	fi

	if debian_version="$(unsquashfs -cat "$squashfs" etc/debian_version 2>/dev/null)" \
		&& [[ "$debian_version" =~ ^12(\.|$) ]]; then
		ok "root filesystem is Debian 12 (etc/debian_version: $debian_version)"
	else
		fail "root filesystem is not Debian 12 (etc/debian_version: ${debian_version:-unreadable})"
	fi

	if dpkg_status="$(unsquashfs -cat "$squashfs" var/lib/dpkg/status 2>/dev/null)"; then
		for pkg in linux-image-amd64 live-boot; do
			if grep -qx "Package: $pkg" <<<"$dpkg_status"; then
				ok "package $pkg is installed in the root filesystem"
			else
				fail "package $pkg is missing from the root filesystem"
			fi
		done
	else
		fail "cannot read var/lib/dpkg/status from the root filesystem"
	fi
	rm -f "$squashfs"
else
	fail "could not extract /live/filesystem.squashfs from the ISO"
fi

if (( problems > 0 )); then
	show_xorriso_stderr
	die "$problems check(s) failed"
fi
echo "ISO verification PASSED: $iso"
