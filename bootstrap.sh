#!/usr/bin/env bash
#
# Single entry point for setting up a machine from this repo.
#
#   ./bootstrap.sh              detect platform, run its full setup
#   ./bootstrap.sh --stow-only  just decrypt + stow (already-provisioned box)
#   ./bootstrap.sh --dry-run    print what would run, change nothing
#
# This is a dispatcher, not an implementation. The real work lives in
# scripts/setup-{macos,linux,android}.sh, each of which calls
# scripts/stow_dotfiles.sh to decrypt *.gpg and stow common + $OS.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR="$REPO_DIR"

STOW_ONLY=0
DRY_RUN=0
for arg in "$@"; do
    case "$arg" in
        --stow-only) STOW_ONLY=1 ;;
        --dry-run)   DRY_RUN=1 ;;
        -h|--help)   sed -n '3,7p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'; exit 0 ;;
        *) echo "unknown option: $arg (try --help)" >&2; exit 2 ;;
    esac
done

# Termux reports uname -s = Linux, so check $PREFIX first — same discriminator
# android-env.fish and linux-env.fish use to guard themselves.
detect_platform() {
    if [ "${PREFIX:-}" = "/data/data/com.termux/files/usr" ]; then
        echo android
    elif [ "$(uname -s)" = "Darwin" ]; then
        echo macos
    elif [ "$(uname -s)" = "Linux" ]; then
        echo linux
    else
        echo "unsupported platform: $(uname -s)" >&2
        exit 1
    fi
}

PLATFORM="$(detect_platform)"

if [ "$STOW_ONLY" -eq 1 ]; then
    TARGET="$REPO_DIR/scripts/stow_dotfiles.sh"
else
    TARGET="$REPO_DIR/scripts/setup-${PLATFORM}.sh"
fi

if [ ! -f "$TARGET" ]; then
    echo "expected script not found: $TARGET" >&2
    exit 1
fi

echo "Platform: $PLATFORM"
echo "Running:  ${TARGET#"$REPO_DIR"/}"

if [ "$DRY_RUN" -eq 1 ]; then
    echo "(dry run — nothing executed)"
    exit 0
fi

# gpg is required by stow_dotfiles.sh to place ssh keys; warn early rather
# than failing halfway through a long provisioning run.
if ! command -v gpg >/dev/null 2>&1; then
    echo "warning: gpg not found — encrypted ssh keys will be skipped" >&2
fi

exec bash "$TARGET"
