-- Paneru (sliding/scrolling tiler). Ported from ~/.aerospace.toml.
-- Hot-reloads on save. Hyper = cmd+alt+ctrl+shift (kmonad hold-A / hold-S).
-- Paneru has no modes, so the AeroSpace resize/move modes became direct chords.

local H = "cmd + alt + ctrl + shift - "
local AC = "alt + ctrl - "
local AS = "alt + shift - "
local ACS = "alt + ctrl + shift - "

local bindings = {
  -- Core
  ["window fullwidth"] = H .. "f",
  ["window manage"]    = H .. "g", -- float <-> tile
  ["window resize"]    = H .. "r", -- cycle preset widths
  ["window center"]    = H .. "c",
  ["window balance"]   = H .. "b",
  ["window equalize"]  = H .. "e", -- equal heights in a stack

  -- Focus
  ["window focus west"]  = H .. "h",
  ["window focus south"] = H .. "j",
  ["window focus north"] = H .. "k",
  ["window focus east"]  = H .. "l",

  -- Move (swap with neighbour)
  ["window swap west"]  = AC .. "h",
  ["window swap south"] = AC .. "j",
  ["window swap north"] = AC .. "k",
  ["window swap east"]  = AC .. "l",

  -- Join: stacking always goes onto the column to the left (k/j aliases bound below)
  ["window stack"]   = AS .. "h",
  ["window unstack"] = AS .. "l",

  -- Resize (was resize mode)
  ["window shrink"]          = ACS .. "h",
  ["window grow"]            = ACS .. "l",
  ["window vertical grow"]   = ACS .. "j",
  ["window vertical shrink"] = ACS .. "k",

  -- Monitors
  ["window nextdisplay"] = H .. "tab",
}

-- Workspaces 1..10 -> virtual workspaces. alt-ctrl-N sends without following, like AeroSpace.
for n = 1, 10 do
  local key = tostring(n % 10)
  bindings["window virtualnum " .. n] = H .. key
  bindings["window virtualsendnum " .. n] = AC .. key
end

paneru.setup {
  default_workspaces = 10,
  options = {
    focus_follows_mouse = false,
    mouse_follows_focus = true,
    auto_center = true,
    animation_speed = 35.0, -- higher = faster; 8 is slow, very high or unset = no animation
  },
  padding = { top = 5, bottom = 5, left = 5, right = 5 },
  windows = {
    -- 5px per window + 5px screen padding = AeroSpace's 10px inner/outer gaps
    gaps = { title = ".*", horizontal_padding = 5, vertical_padding = 5 },
    pip = { title = "Picture-in-Picture", floating = true },
    settings = { title = ".*", bundle_id = "com.apple.systempreferences", floating = true },
  },
  bindings = bindings,
}

paneru.bind(AS .. "k", "window stack")
paneru.bind(AS .. "j", "window unstack")

-- Close: Paneru has no close command (see close-window.js)
paneru.bind(H .. "q", function()
  os.execute("osascript -l JavaScript ~/.config/paneru/close-window.js >/dev/null 2>>/tmp/paneru-close.log &")
end)

-- Vertical split: Hyper-v arms it, and the next window opens below the focused one
-- in the same column instead of in a new column. Press again to cancel.
local split_below = nil
paneru.bind(H .. "v", function(ws)
  split_below = (split_below == nil) and ws:focused() or nil
  paneru.flash(split_below and "split ↓" or "split cancelled")
end)

paneru.on("window_spawned", function(event, ws)
  local target = split_below
  split_below = nil
  if target and event.managed and not event.floating and ws:window(target) then
    return ws:stack(event.window_id, target)
  end
end)

-- JankyBorders reads ~/.config/borders/bordersrc when started without args
os.execute("pgrep -qx borders || (borders >/dev/null 2>&1 &)")
