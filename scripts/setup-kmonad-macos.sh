#!/bin/sh
# Voyager layout on the MacBook built-in keyboard: build kmonad and run it as a
# root launchd daemon (the Mac counterpart of linux/.config/systemd/user/kmonad.service).
#
# Prereq: Karabiner-Elements installed; kmonad posts keys through its virtual
# keyboard driver. Asks for sudo.
#
# Re-run after editing voyager-mac.kbd. The daemon runs as root, so it reads a
# root-owned copy of the config and a root-owned binary: nothing a user process
# can rewrite ends up executed as root.
#
# After the first run: System Settings > Privacy & Security > Input Monitoring,
# add /usr/local/bin/kmonad. The daemon retries until that is granted.
# Stop/start afterwards with `kmonad-toggle`.
set -eu

REPO=$(cd "$(dirname "$0")/.." && pwd)
CFG=$REPO/common/.config/kmonad/voyager-mac.kbd
SRC=$HOME/.local/src/kmonad
DRIVER_DAEMON="/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app"
KARABINER_JSON=$HOME/.config/karabiner/karabiner.json
PLIST=/Library/LaunchDaemons/local.kmonad.plist

[ -d "$DRIVER_DAEMON" ] || { echo "Install Karabiner-Elements first (virtual keyboard driver missing)." >&2; exit 1; }

# No Homebrew formula and no macOS binaries upstream, so build from source.
# To rebuild (e.g. Karabiner updated its driver and kmonad logs
# driver_version_mismatched): sudo rm /usr/local/bin/kmonad, re-run, and
# re-grant Input Monitoring.
if [ ! -x /usr/local/bin/kmonad ]; then
  driver_version=$(defaults read "$DRIVER_DAEMON/Contents/Info" CFBundleShortVersionString)
  [ -d "$SRC" ] || git clone --recursive https://github.com/kmonad/kmonad.git "$SRC"
  git -C "$SRC" checkout -q 30b9705 # last commit verified on macOS 26 / driver 8.5.0
  # kmonad pins an older driver client; build against the headers of the
  # installed driver instead, or the client protocol will not match.
  dext=$SRC/c_src/mac/Karabiner-DriverKit-VirtualHIDDevice
  git -C "$dext" fetch -q --tags origin
  git -C "$dext" checkout -q "v$driver_version"
  git -C "$dext" submodule update -q --init --recursive
  # Driver headers from 8.x use std::to_underlying (C++23).
  sed -i '' 's/-std=c++2a/-std=c++2b/' "$SRC/kmonad.cabal"
  (cd "$SRC" && stack build --flag kmonad:dext)
  sudo install -m 755 "$(find "$SRC/.stack-work/install" -type f -name kmonad | head -1)" /usr/local/bin/kmonad
fi

/usr/local/bin/kmonad --dry-run "$CFG"
sudo mkdir -p /usr/local/etc/kmonad
sudo install -m 644 "$CFG" /usr/local/etc/kmonad/voyager-mac.kbd

# Karabiner-Elements seizes every keyboard exclusively; make it ignore the
# built-in one (vendor/product 0, i.e. bare is_keyboard) so kmonad can open it.
if [ -f "$KARABINER_JSON" ]; then
  python3 - "$KARABINER_JSON" <<'EOF'
import json, sys
path = sys.argv[1]
config = json.load(open(path))
for profile in config["profiles"]:
    devices = profile.setdefault("devices", [])
    if not any(d["identifiers"] == {"is_keyboard": True} for d in devices):
        devices.append({"identifiers": {"is_keyboard": True}, "ignore": True})
json.dump(config, open(path, "w"), indent=4)
EOF
fi

sudo tee "$PLIST" >/dev/null <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>local.kmonad</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/local/bin/kmonad</string>
    <string>/usr/local/etc/kmonad/voyager-mac.kbd</string>
  </array>
  <key>RunAtLoad</key><true/>
  <!-- restart if the Karabiner driver daemon is not up yet at boot -->
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>/var/log/kmonad.log</string>
  <key>StandardErrorPath</key><string>/var/log/kmonad.log</string>
</dict>
</plist>
EOF
sudo launchctl bootout system/local.kmonad 2>/dev/null || true
sudo launchctl bootstrap system "$PLIST"
echo "kmonad daemon loaded. If the layout is not active, grant Input Monitoring to /usr/local/bin/kmonad."
