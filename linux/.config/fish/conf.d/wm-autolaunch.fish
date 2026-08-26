# tty1 login -> autolaunch the right WM by which GPU the DP cable is in
# (mobo DP -> sway on iGPU, nvidia DP -> startx/i3). See SETUP-DESKTOP-DUAL-WM.md
if status is-login; and test (tty) = /dev/tty1
    exec ~/dotfiles/scripts/wm-autolaunch.sh
end
