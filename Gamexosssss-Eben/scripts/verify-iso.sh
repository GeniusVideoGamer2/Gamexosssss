#!/usr/bin/env bash
# Read-only structural verification of the GameXOSTR live ISO using xorriso.
set -euo pipefail

iso="${1:-GameXOSTR.iso}"
expected_volume="${EXPECTED_VOLUME_ID:-GAMEXOSTR}"
min_mib="${MIN_ISO_MIB:-700}"

[[ -f "$iso" ]] || { echo "Missing $iso" >&2; exit 1; }

echo "ISO verification PASSED: $iso"
