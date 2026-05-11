# Termux/Android env. Bail out on non-Termux Linux/macOS.
if not set -q PREFIX; or test "$PREFIX" != /data/data/com.termux/files/usr
    exit
end

# Termux PATH (most binaries live under $PREFIX/bin)
fish_add_path $PREFIX/bin
fish_add_path $HOME/go/bin

# TERM upgrade so colors survive over ssh/mosh sessions
if test "$TERM" = xterm
    set -gx TERM xterm-256color
end

# Termux:API clipboard — overrides the xclip alias from common/config.fish.
# Requires the Termux:API app + `pkg install termux-api`.
if command -q termux-clipboard-set
    alias c='termux-clipboard-set'
    alias v='termux-clipboard-get'
end

# Persistent dev-session helpers. Reattach if a tmux session named "main"
# exists on the target, otherwise create one. Customize hostnames in
# ~/.ssh/config so these "just work" over Tailscale.
function _mosh_tmux --argument-names host session
    set -q session[1]; or set session main
    mosh $host -- tmux new-session -A -s $session
end
alias dev    '_mosh_tmux devbox'
alias laptop '_mosh_tmux laptop'
alias desk   '_mosh_tmux desktop'

# Strip aliases that depend on Linux-desktop tooling we don't have here.
# (xinput, dolphin, wg-quick, xclip are all unreachable on Termux.)
functions -e mouse-speed 2>/dev/null
functions -e dd 2>/dev/null
functions -e vpnup 2>/dev/null
functions -e vpndown 2>/dev/null
