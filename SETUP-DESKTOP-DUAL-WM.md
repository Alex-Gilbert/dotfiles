# Desktop: dual-WM setup — sway (iGPU) / i3 (nvidia)

Both cables stay plugged: DP → nvidia card, HDMI (mobo/iGPU) → monitor HDMI-2.
The monitor keeps hotplug asserted on the inactive input, so *both* GPUs always
report "connected" — cable position can't be the mode switch anymore. The
switch is now the monitor's input select + which tty you log into:

| want | do |
|---|---|
| sway / wayland (llama-swap gets all VRAM) | monitor input → HDMI-2, log in on tty1 — autolaunch defaults to sway |
| i3 / X11 (video editing, gaming) | monitor input → DP, log in on tty2 (any tty ≠ 1), `startx` |

`scripts/wm-autolaunch.sh` still reads `/sys/class/drm/*/status`; with both
connected it prefers the iGPU, which is the right default.

## 1. Sync the repo

```sh
cd ~/dotfiles && git pull
./scripts/stow_dotfiles.sh   # links sway/foot/wofi/gtklock + linux/.xinitrc etc.
```

## 2. BIOS

Enable the iGPU while a dGPU is present (usually "iGPU Multi-Monitor" or
"Primary Display: CPU Graphics" — you want *both* GPUs active, iGPU can stay
non-primary). Without this the mobo DP port is dead.

## 3. Packages (sway stack)

```sh
pacman -S --needed sway swayidle autotiling foot wofi mako waybar grim slurp
# gtklock is AUR
```

## 4. Host config

Nothing to do — the main sway config does
`include ~/.config/sway/hosts/$(uname -n).conf` (sway includes go through
wordexp, so command substitution works), and `hosts/cachy-two.conf` exists
with connector + mode filled in from the EDID: `HDMI-A-2`, 3840x2160@120
(the monitor's HDMI max; 240 is DP-only). Switch the monitor input to
HDMI-2, start sway once (`WLR_DRM_DEVICES=/dev/dri/card0 sway` from a tty,
or via wm-autolaunch), and confirm with `swaymsg -t get_outputs` — if the
mobo port is only HDMI 2.0 it'll cap at 60Hz; drop the mode line to match.

One-time migration on the laptop after pulling this change:

```sh
cd ~/dotfiles
git mv linux/.config/sway/hosts/laptop.conf "linux/.config/sway/hosts/$(uname -n).conf"
rm -rf linux/.config/sway/config.d   # old symlink mechanism, no longer read
```

## 5. Wire up autolaunch

Add to `~/.bash_profile` (or fish's `config.fish` login block):

```sh
[ "$(tty)" = /dev/tty1 ] && exec ~/dotfiles/scripts/wm-autolaunch.sh
```

If the desktop runs a display manager instead, either disable it in favor of
tty login, or keep the DM and pick sway/i3 sessions manually — autolaunch is
for the no-DM flow. (Laptop note: ly's config exists there but the service
isn't registered; laptop boots sway fine regardless.)

## 6. X11/nvidia side still works

- `linux/.xinitrc` now exists and just execs i3 (`startx` path).
- **Gotcha:** once the iGPU is enabled in BIOS, Xorg may auto-pick the iGPU as
  primary. If `startx` comes up on the wrong GPU or headless, pin nvidia in
  `/etc/X11/xorg.conf.d/10-nvidia.conf`:

  ```
  Section "Device"
      Identifier "nvidia"
      Driver "nvidia"
      Option "PrimaryGPU" "yes"
  EndSection
  ```

- The i3 config's `xrandr --output DP-0 --mode 3840x2160 --rate 239.99` line is
  unchanged and applies when the cable is on the nvidia card.

## 7. nvidia = headless CUDA card under sway (llama-swap)

The point of sway mode: with `WLR_DRM_DEVICES` pinned to the iGPU (autolaunch
does this), nothing display-related ever opens the nvidia card — llama-swap
gets ALL the VRAM. CUDA needs no display and no nvidia-drm modeset.

Do enable persistenced so the driver stays initialized on the headless card
(fast CUDA context creation, no init latency after llama-swap unloads a model):

```sh
systemctl enable --now nvidia-persistenced
```

Skip `NVreg_DynamicPowerManagement` runtime-suspend: llama-swap unloads idle
models by design, and a suspended card adds cold-start latency to the next
inference. Persistenced keeps it warm instead.

Sanity check from sway: `nvidia-smi` should show ~0 MiB used with no models
loaded — if Xorg or a compositor appears in the process list, something is
touching the card that shouldn't be.

One-off GPU apps inside sway still possible via `prime-run <app>`
(nvidia-prime pkg) — they'll compete with llama-swap for VRAM while running.

## 8. kmonad

Config + user service are in the repo now:

```sh
systemctl --user daemon-reload
systemctl --user enable --now kmonad
```

## Verify checklist

- [ ] monitor input HDMI-2 → tty1 login → sway comes up on HDMI-A-2 (check rate in `swaymsg -t get_outputs`)
- [ ] under sway: `nvidia-smi` shows no display processes, ~0 MiB baseline — full VRAM for llama-swap
- [ ] monitor input DP → tty2 login → `startx` → i3 comes up at 4K@240
- [ ] `hosts/cachy-two.conf` refresh rate confirmed + committed
- [ ] waybar/mako/wofi/foot all themed & working under sway (kanagawa, same as laptop)
