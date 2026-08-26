#!/usr/bin/env bash
# Audio visualiser for waybar.
#
# waybar 0.15.0 on this box has NO built-in cava module (no libcava/fftw
# linkage, no waybar-cava man page), so this feeds it from the cava binary
# instead. cava's raw/ascii output is one frame per line: N values 0-7
# separated by ';'. Map each to a block glyph and print a line per frame —
# waybar treats each line of a custom module's stdout as an update.
#
# On silence every value is 0; print an empty line rather than 12 spaces,
# because waybar hides a custom module whose text is empty but renders a blank
# chip for whitespace. So the visualiser only exists while something is playing.
#
# cava runs through a FIFO rather than a plain `cava | awk` pipeline so its PID
# is known and killable. With a pipeline, waybar exiting kills awk but leaves
# cava orphaned to PID 1, spinning against an already-deleted config — and sway
# runs `killall -q waybar; exec waybar` on every reload, so those accumulate.

set -eu
command -v cava >/dev/null 2>&1 || exit 0   # module just stays empty, as elsewhere

CONF=$(mktemp)
FIFO=$(mktemp -u)
mkfifo "$FIFO"
cava_pid=""
cleanup() {
    [ -n "$cava_pid" ] && kill "$cava_pid" 2>/dev/null || true
    rm -f "$CONF" "$FIFO"
}
trap cleanup EXIT INT TERM

# Delimiter is quoted as <<'CAVA' so backticks in these comments stay comments;
# unquoted, the shell ran the command substitution and pasted its output into
# cava's config, which then failed to parse.
#
# No [input] block: cava autodetects, which picks up pipewire on both hosts.
# If the bars stay flat while audio plays, that autodetect is the knob — add
#   [input]
#   method = pipewire
#   source = auto
# and check `wpctl status` for the right monitor source.
cat > "$CONF" <<'CAVA'
[general]
framerate = 30
bars = 12
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
CAVA

cava -p "$CONF" > "$FIFO" &
cava_pid=$!

# fflush matters: without it awk buffers and the bar updates in laggy bursts.
awk -F';' '
    BEGIN { split(" :▁:▂:▃:▄:▅:▆:▇:█", g, ":") }
    { s = ""; nz = 0
      for (i = 1; i < NF; i++) { v = $i + 0; if (v > 0) nz = 1; s = s g[v + 1] }
      print (nz ? s : ""); fflush() }
' < "$FIFO"
