# Desktop: dual-WM setup — sway (iGPU) / i3 (nvidia)

The DP cable position is the mode switch:

| cable plugged into | session | use case |
|---|---|---|
| motherboard port (iGPU) | sway / wayland | low power, nvidia idles |
| nvidia card | i3 / X11 | video editing, gaming |

`scripts/wm-autolaunch.sh` reads `/sys/class/drm/*/status` at login, sees which
GPU has a connected monitor, and launches the right session. Plug cable, log
in, done.

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

## 4. Pick the host config

```sh
mkdir -p ~/dotfiles/linux/.config/sway/config.d   # gitignored, per-machine
ln -sf ../hosts/desktop.conf ~/dotfiles/linux/.config/sway/config.d/00-host.conf
```

Then plug the cable into the mobo port, start sway once (`WLR_DRM_DEVICES=/dev/dri/cardN sway`
from a tty, or just via wm-autolaunch), run `swaymsg -t get_outputs`, and fill
in the real connector name + best mode in `linux/.config/sway/hosts/desktop.conf`.
The iGPU port may not do 4K@240 — take the best mode it lists. Commit it.

(The laptop does the same thing with `hosts/laptop.conf`; that symlink already
exists there.)

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

## 7. Optional: nvidia fully asleep under sway

With no cable on the card and `WLR_DRM_DEVICES` pinned to the iGPU (autolaunch
does this), the nvidia card can runtime-suspend:

```sh
# /etc/modprobe.d/nvidia-pm.conf
options nvidia NVreg_DynamicPowerManagement=0x02
```

Check with `cat /sys/bus/pci/devices/<nvidia-bdf>/power/runtime_status` → `suspended`.
One-off GPU work inside sway still possible via `prime-run <app>` (nvidia-prime pkg).

## 8. kmonad

Config + user service are in the repo now:

```sh
systemctl --user daemon-reload
systemctl --user enable --now kmonad
```

## Verify checklist

- [ ] cable in mobo port → login → sway comes up, `swaymsg -t get_outputs` shows iGPU connector
- [ ] `nvidia` runtime_status → `suspended` (if step 7 done)
- [ ] cable in nvidia port → login → i3 comes up at 4K@240
- [ ] `hosts/desktop.conf` output line filled in + committed
- [ ] waybar/mako/wofi/foot all themed & working under sway (kanagawa, same as laptop)
