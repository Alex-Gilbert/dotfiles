# tty1 login -> autolaunch niri on whichever GPU the DP cable is in
# (mobo DP -> iGPU, nvidia DP -> nvidia). See SETUP-DESKTOP-DUAL-WM.md
if status is-login; and test (tty) = /dev/tty1
    exec ~/dotfiles/scripts/wm-autolaunch.sh
end
