# Android (Termux) Setup Instructions

Setting up an Android tablet (Galaxy Tab S11 + Glove80, in my case) as a
poweruser remote dev machine. The pattern is the same as macOS / Linux:
`common` + `android` stowed into `$HOME`. Most heavy lifting happens on
remote machines over Tailscale + mosh + tmux — the tablet is a thin client.

## 📋 Prerequisites

- Android tablet, ideally with DeX (Galaxy Tab S-series) for windowed mode
- A hardware keyboard (Glove80, USB or BT)
- Termux installed **from F-Droid or GitHub releases** — *not* the Play Store
  version, which is frozen and broken
- Termux companion apps from the same source:
  - Termux:API (clipboard, notifications, sensors)
  - Termux:Widget (home-screen one-tap launchers)
  - Termux:X11 (optional — windowed apps)
  - Termux:Tasker (optional — automation)
- Tailscale Android app from Play Store (handles VPN at the OS level)

## 🚀 Setup

### Step 1: Bootstrap Termux

In Termux:

```bash
pkg update -y && pkg upgrade -y
pkg install -y git
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
bash ~/dotfiles/scripts/setup-android.sh
```

`setup-android.sh` installs everything (fish, neovim, tmux, mosh, openssh,
fzf, zoxide, ripgrep, fd, bat, eza, lazygit, yazi, rsync, starship,
git-delta, node, python, rust, go, termux-api, termux-tools), runs stow,
and reloads Termux settings.

### Step 2: Tailscale

1. Install Tailscale from Play Store, sign in. Approve the VPN profile.
2. Verify reachability from Termux: `ping desktop` (or whatever your
   MagicDNS hostnames are). Termux inherits the OS-level VPN.
3. (Optional) `tailscale up` from inside Termux if you want the CLI for
   `tailscale ssh`.

### Step 3: SSH config

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cat > ~/.ssh/config <<'EOF'
Host *
    ControlMaster auto
    ControlPath ~/.ssh/cm-%r@%h:%p
    ControlPersist 10m
    ServerAliveInterval 30
    ServerAliveCountMax 4

Host desktop
    HostName desktop.tail-scale-name.ts.net
    User alex

Host laptop
    HostName laptop.tail-scale-name.ts.net
    User alex

Host devbox
    HostName devbox.tail-scale-name.ts.net
    User alex
EOF
chmod 600 ~/.ssh/config
```

Generate a key and add it to your other machines / GitHub:

```bash
ssh-keygen -t ed25519 -C "tablet@$(hostname)"
termux-clipboard-set < ~/.ssh/id_ed25519.pub
```

### Step 4: Font + colors

The Kanagawa color scheme is already stowed into `~/.termux/colors.properties`.
Drop a Nerd Font:

```bash
curl -L -o ~/.termux/font.ttf \
  https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/JetBrainsMono/Ligatures/Regular/JetBrainsMonoNerdFont-Regular.ttf
termux-reload-settings
```

### Step 5: Termux:Widget

Long-press your home screen → Add widget → Termux:Widget. The launchers in
`~/.shortcuts/` show up automatically:

| Launcher          | What it does                                |
| ----------------- | ------------------------------------------- |
| `mosh-desktop`    | mosh + reattach tmux on `desktop`           |
| `mosh-laptop`     | mosh + reattach tmux on `laptop`            |
| `mosh-devbox`     | mosh + reattach tmux on `devbox`            |
| `update-termux`   | `pkg update && pkg upgrade`                 |

Edit `android/.shortcuts/` in the dotfiles repo to add hosts; commit; pull
on the tablet; `termux-reload-settings`. The `tasks/sync-dotfiles` script
is for Termux:Tasker (background pulls).

### Step 6: Persistent remote tmux

On each remote machine you'll connect to, set up a long-lived session per
project. The widget launchers run `tmux new-session -A -s main`, which
attaches if `main` exists, or creates it. Drop into a project pane and
leave it; reconnect from the tablet a week later, same window layout.

### Step 7: DeX + Glove80

- Pair / plug in the Glove80; DeX flips on automatically when it detects
  a keyboard.
- Settings → General Management → Physical Keyboard → disable any media
  key interception that fights your Glove80 layer.
- Flash a Glove80 Android layer with `&kp K_APP_SWITCH`, `&kp K_HOMEPAGE`,
  `&kp K_BACK` so the tablet is keyboard-driven (no touchscreen needed in
  DeX).
- Pin Termux + browser + Tailscale to the DeX taskbar.
- For a hyperkey-driven app launcher / system-wide remapper on the tablet,
  see the **glovemap** project at [`~/dev/glovemap/`](../dev/glovemap/) — a
  YAML-configured AccessibilityService deployed via `cook deploy` over
  Tailscale ADB.

### Step 8: Editor

Three options, in order of how I use them:

1. **Remote nvim** over `mosh + tmux` — your `common/.config/nvim/` runs
   on the dev box, the tablet just renders bytes. Daily driver.
2. **Local nvim in Termux** — installed by `setup-android.sh`. For quick
   edits without a remote.
3. **code-server in browser** — run `code-server` on a Tailscale-reachable
   box, hit `https://devbox.ts.net:8443` from Brave on the tablet. Real
   VS Code, real filesystem.

## ✅ Verification Checklist

```bash
# Termux
echo $PREFIX                       # /data/data/com.termux/files/usr
echo $SHELL                        # .../usr/bin/fish

# Stow targets
ls -la ~/.config/fish/config.fish  # symlink into ~/dotfiles/common/...
ls -la ~/.config/fish/conf.d/android-env.fish
ls -la ~/.termux/colors.properties
ls -la ~/.shortcuts/mosh-desktop

# Networking
tailscale status                   # if you installed the CLI
ping desktop                       # MagicDNS resolves
ssh desktop                        # ControlMaster path is set

# Terminal stack
fish --version
nvim --version | head -1
mosh --version
tmux -V
```

## 🔧 Troubleshooting

### Stow conflicts on first install

If you set up Termux defaults before stowing (e.g. `~/.termux/colors.properties`
already exists as a regular file):

```bash
mv ~/.termux/colors.properties ~/.termux/colors.properties.bak
cd ~/dotfiles && stow -v -R common android
```

### `mosh` connects but disconnects immediately

UDP blocked on the network. Mosh defaults to ports 60000–61000.
Workaround: `mosh -p 60001 desktop` and open just that port on the
remote firewall. Long-term: use Tailscale, where everything is end-to-end
encrypted UDP through MagicDNS.

### Glove80 keys do nothing in DeX

Settings → General Management → Physical Keyboard → check that the layout
matches your Glove80 layer. Some Samsung media-key handlers swallow the
top row — disable them in the same panel.

### Termux can't reach Tailscale hostnames

The Tailscale Android app must be active (green "Connected"). Termux uses
the OS-level VPN; you don't need the Termux-side `tailscale` daemon for
basic reachability — only for `tailscale ssh` and CLI commands.

### Fish complains about missing commands at startup

Expected on first launch. The aliases in `common/config.fish` reference
Linux-desktop tools (`xinput`, `dolphin`, `wg-quick`, `xclip`); the
`android-env.fish` conf.d file erases them. If you see them anyway, your
conf.d ordering is off — make sure `android-env.fish` is loaded *after*
`common/config.fish` (default fish behavior; nothing to do).

## 📁 Where everything lives

| Path                                               | What                          |
| -------------------------------------------------- | ----------------------------- |
| `~/.config/fish/config.fish`                       | from `common/`                |
| `~/.config/fish/conf.d/android-env.fish`           | from `android/`               |
| `~/.config/nvim/`                                  | from `common/`                |
| `~/.config/tmux/`                                  | from `common/`                |
| `~/.termux/termux.properties`                      | from `android/`               |
| `~/.termux/colors.properties`                      | from `android/`               |
| `~/.termux/font.ttf`                               | drop-in (not in repo)         |
| `~/.shortcuts/`                                    | from `android/`               |

## 🎯 Optional next steps

- **Syncthing** between tablet and dev boxes over Tailscale. Two-way sync
  of `~/notes`, screenshots, scratch dirs.
- **Atuin** for shared shell history across all your machines (self-host
  the sync server on a Tailscale box).
- **code-server** on your main dev box for browser-based VS Code with
  your real filesystem.
- **Termux:Tasker** to wire `~/.shortcuts/tasks/sync-dotfiles` to a daily
  trigger.

## 📚 Resources

- [Termux Wiki](https://wiki.termux.com/)
- [Termux:Widget](https://wiki.termux.com/wiki/Termux:Widget)
- [Termux:API](https://wiki.termux.com/wiki/Termux:API)
- [Tailscale Android](https://tailscale.com/kb/1023/install-android)
- [Mosh](https://mosh.org/)
