#!/bin/bash
set -e

echo "Building GameXOSTR ISO"

# This scaffold mirrors the extracted archive and is validated by the included
# ISO verification script.

mkdir -p out

# The real live-build project lives under the live-build configuration tree.
# This scaffold keeps the project source layout aligned with the archive.

echo "GameXOSTR build scaffold ok"
