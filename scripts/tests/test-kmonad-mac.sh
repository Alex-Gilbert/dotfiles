#!/bin/sh
# Run with sh scripts/tests/test-kmonad-mac.sh; parse-checks the Mac kmonad
# config without grabbing the keyboard (no root needed).
set -eu
cd "$(dirname "$0")/../.."
kmonad --dry-run common/.config/kmonad/voyager-mac.kbd
echo "PASS: voyager-mac.kbd parses"
