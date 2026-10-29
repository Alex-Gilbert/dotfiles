# macOS Setup

A new Mac with the dotfiles and Paneru, a sliding/scrolling tiler (the macOS
twin of niri on Linux).

## 1. Homebrew and the dotfiles

```bash
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

git clone https://github.com/Alex-Gilbert/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./bootstrap.sh
```

`bootstrap.sh` runs `scripts/setup-macos.sh`: fish as the login shell, the CLI
tools, language toolchains, and the `common` + `macos` stow packages. Restart
the terminal afterwards.

## 2. Window manager: Paneru

```bash
brew install paneru felixkratz/formulae/borders
brew install --cask raycast
paneru install && paneru start   # launchd service, starts at login
```

The configs come from the `macos` stow package: `~/.config/paneru/init.lua`
(keys, rules, per-workspace fit mode) and `~/.config/borders/bordersrc`
(focus border). Paneru starts borders itself.

Paneru needs **Displays have separate Spaces** on:

```bash
defaults write com.apple.spaces spans-displays -bool false   # then log out
```

## 3. Permissions

**System Settings → Privacy & Security → Accessibility**: enable Paneru,
Raycast, kitty, and Karabiner/kmonad (whatever provides Hyper). Paneru exits
without it.

## 4. macOS shortcuts and Dock

- **Keyboard → Keyboard Shortcuts**: turn off the Mission Control and
  Spotlight shortcuts that clash with Hyper chords and Raycast.
- **Desktop & Dock**: auto-hide the Dock.

## Keys

Hyper = cmd+alt+ctrl+shift (hold A or S). Paneru grabs its chords before
Raycast sees them. The full list lives in `init.lua`.

| Keys | Action |
|---|---|
| Hyper-h/j/k/l | focus |
| Alt-ctrl-h/j/k/l | swap with neighbour |
| Alt-shift-h/k, -j/l | stack onto the column to the left / unstack |
| Alt-ctrl-shift-h/l, -j/k | narrower/wider, taller/shorter |
| Hyper-1…0 | virtual workspace 1–10 |
| Alt-ctrl-1…0 | send window to workspace, stay here |
| Hyper-f | full width |
| Hyper-r | cycle preset widths |
| Hyper-c | center |
| Hyper-m | fit this workspace's columns to the screen, auto-center off here; again to undo |
| Hyper-v | next window opens below the focused one |
| Hyper-g | float ↔ tile |
| Hyper-q | close window |
| Hyper-b | new Firefox window |
| Hyper-tab | move window to next display |

Raycast's **Paneru** script command runs the rest (balance, equalize, tabbed
stack, snap, copy window rule, restart).

## Troubleshooting

```bash
paneru restart                 # options in init.lua only apply on (re)start; key edits hot-reload
tail -f /tmp/com.github.karinushka.paneru_501.err.log
paneru query state             # what Paneru thinks is where
```

- **Paneru quits at once**: Accessibility permission, or separate Spaces off.
- **A window won't take focus keys**: it's floating; Hyper-g tiles it.
- **Things it launches don't start**: its launchd service has no Homebrew on
  `PATH`, so give full paths or prefix `PATH=/opt/homebrew/bin:$PATH`.
- Re-link after pulling: `~/dotfiles/bootstrap.sh --stow-only`.
