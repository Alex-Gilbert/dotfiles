#!/usr/bin/env bash
# Warm Zen at login and hide it.
#
# Gecko's first start is slow (~seconds); every window after it is effectively
# free. So park one resident instance in the scratchpad — the process stays
# warm, nothing sits in the tiling layout — and let hyper+b be a plain
# `zen-browser`, which then opens a new tiled window in single-digit ms.
#
# Headless cannot do this job: a `--headless` instance takes the profile and
# then silently swallows every later invocation (they exit 0 and no window ever
# appears), so it can warm a process but never become a visible browser.
#
# The window is parked by con_id, NOT by an [app_id=zen] criteria match.
# Criteria match *every* Zen window, so a criteria-based `move scratchpad`
# also sweeps the windows you actually opened into the scratchpad.

set -eu

if [ -n "${WAYLAND_DISPLAY:-}" ] && command -v swaymsg >/dev/null 2>&1; then
    msg=swaymsg; sel='.app_id'
elif command -v i3-msg >/dev/null 2>&1; then
    msg=i3-msg;  sel='.window_properties.class'
else
    exit 0
fi
command -v jq >/dev/null 2>&1 || exit 0

ids() {
    "$msg" -t get_tree | jq "[recurse(.nodes[]?, .floating_nodes[]?)
        | select((($sel // \"\") | ascii_downcase) == \"zen\") | .id]"
}

# Already warm (WM reload, or a browser left running) — do nothing.
[ "$(ids | jq 'length')" -gt 0 ] && exit 0

zen-browser >/dev/null 2>&1 &
for _ in $(seq 60); do
    id=$(ids | jq -r '.[0] // empty')
    [ -n "$id" ] && break
    sleep 0.5
done
[ -n "${id:-}" ] || exit 0      # gave up waiting; leave whatever happened alone

# Session restore (browser.startup.page=3) can open SEVERAL windows, and they
# don't all appear at once — so wait for the count to settle rather than parking
# the first one and calling it done. Leftovers would sit on the workspace at
# login, which is precisely what this script exists to prevent.
prev=-1
for _ in $(seq 20); do
    cur=$(ids | jq 'length')
    [ "$cur" = "$prev" ] && break
    prev=$cur
    sleep 0.5
done

# Park every window that exists *now*. Safe to be broad here: --warm has exited
# long before you press hyper+b, so windows you open later are never touched.
for wid in $(ids | jq -r '.[]'); do
    "$msg" "[con_id=$wid] move scratchpad" >/dev/null
done
