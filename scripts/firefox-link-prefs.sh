#!/usr/bin/env bash
# Link the repo's Firefox prefs (stowed to ~/.config/firefox/user.js) into every
# Firefox profile on this machine. Profiles get random dir names, so this can't
# be a stow target. Re-run after creating a new profile; Firefox must restart
# to pick it up.
set -euo pipefail

prefs="$HOME/.config/firefox/user.js"
[ -f "$prefs" ] || { echo "missing $prefs — run scripts/stow_dotfiles.sh first" >&2; exit 1; }

linked=0
for root in "$HOME/Library/Application Support/Firefox/Profiles" \
            "$HOME/.config/mozilla/firefox" \
            "$HOME/.mozilla/firefox"; do
    for profile in "$root"/*/; do
        # prefs.js marks a profile that has actually run (skips empty stubs)
        [ -f "$profile/prefs.js" ] || continue
        ln -sfn "$prefs" "$profile/user.js"
        echo "linked ${profile%/}"
        linked=$((linked + 1))
    done
done

[ "$linked" -gt 0 ] || { echo "no Firefox profiles found — launch Firefox once first" >&2; exit 1; }
