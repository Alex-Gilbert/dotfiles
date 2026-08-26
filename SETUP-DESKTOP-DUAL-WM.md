# Desktop: dual-WM setup — sway (iGPU) / i3 (nvidia)

Cable-as-switch: one DP cable, monitor input stays on DP. Which GPU the cable
is plugged into IS the mode switch — only that GPU reads "connected" in
`/sys/class/drm/*/status`, so `scripts/wm-autolaunch.sh` picks the right
session from a tty1 login in both modes. No tty rule, no monitor input button.

| want | do |
|---|---|
| sway / wayland (llama-swap gets all VRAM) | DP cable → mobo DP port, log in on tty1 → sway |
| i3 / X11 (video editing, gaming) | DP cable → nvidia card, log in on tty1 → startx/i3 |

(We tried both-cables-plugged with the monitor's input select as the switch —
doesn't work: the monitor asserts hotplug on the inactive input too, so both
GPUs always read "connected" and software can't tell which input is active.)

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
wordexp, so command substitution works), and `hosts/cachy-two.conf` matches
`output *` (mobo DP lands on amdgpu DP-4/5/6 depending on port; single
monitor, so wildcard is fine) at 3840x2160@240. Plug the DP cable into the
mobo, start sway once (tty1 login, or `WLR_DRM_DEVICES=/dev/dri/card0 sway`),
and confirm the rate with `swaymsg -t get_outputs` — if the iGPU DP link
can't carry 4K@240, drop the mode line to what it reports.

One-time migration on the laptop after pulling this change:

```sh
cd ~/dotfiles
git mv linux/.config/sway/hosts/laptop.conf "linux/.config/sway/hosts/$(uname -n).conf"
rm -rf linux/.config/sway/config.d   # old symlink mechanism, no longer read
```

## 5. Wire up autolaunch

Nothing to do — `linux/.config/fish/conf.d/wm-autolaunch.fish` is stowed and
execs `scripts/wm-autolaunch.sh` on tty1 login; it reads connector status and
starts sway (iGPU connected) or startx (nvidia connected). No DM: the mode
switch is physical cable position, so a session picker adds nothing. Make sure
no DM service is enabled (`systemctl list-unit-files 'display-manager*'`).

Optional zero-typing boot (straight into sway, gtklock still guards idle):

```sh
sudo systemctl edit getty@tty1   # then:
# [Service]
# ExecStart=
# ExecStart=-/sbin/agetty -a alex - $TERM
```

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

- [ ] DP cable in mobo → tty1 login → sway comes up (check rate in `swaymsg -t get_outputs`)
- [ ] under sway: `nvidia-smi` shows no display processes, ~0 MiB baseline — full VRAM for llama-swap
- [ ] DP cable in nvidia → tty1 login → i3 comes up at 4K@240
- [ ] `hosts/cachy-two.conf` refresh rate confirmed + committed
- [ ] waybar/mako/wofi/foot all themed & working under sway (kanagawa, same as laptop)
