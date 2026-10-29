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
	["window manage"] = H .. "g", -- float <-> tile
	["window resize"] = H .. "r", -- cycle preset widths
	["window center"] = H .. "c",

	-- Focus
	["window focus west"] = H .. "h",
	["window focus south"] = H .. "j",
	["window focus north"] = H .. "k",
	["window focus east"] = H .. "l",

	-- Move (swap with neighbour)
	["window swap west"] = AC .. "h",
	["window swap south"] = AC .. "j",
	["window swap north"] = AC .. "k",
	["window swap east"] = AC .. "l",

	-- Join: stacking always goes onto the column to the left (k/j aliases bound below)
	["window stack"] = AS .. "h",
	["window unstack"] = AS .. "l",

	-- Resize (was resize mode)
	["window shrink"] = ACS .. "h",
	["window grow"] = ACS .. "l",
	["window vertical grow"] = ACS .. "j",
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

paneru.setup({
	default_workspaces = 10,
	options = {
		focus_follows_mouse = false,
		mouse_follows_focus = false,
		auto_center = false, -- done per workspace in Lua below (Hyper-m)
		-- No animation_speed: unset = no animation. Sliding left windows stuck at the
		-- bottom when switching workspaces quickly.
	},
	padding = { top = 5, bottom = 5, left = 5, right = 5 },
	windows = {
		-- 5px per window + 5px screen padding = AeroSpace's 10px inner/outer gaps
		gaps = { title = ".*", horizontal_padding = 5, vertical_padding = 5 },
		pip = { title = "Picture-in-Picture", floating = true },
		settings = { title = ".*", bundle_id = "com.apple.systempreferences", floating = true },
	},
	bindings = bindings,
})

paneru.bind(AS .. "k", "window stack")
paneru.bind(AS .. "j", "window unstack")

-- Auto-center, per workspace. Hyper-m fits this workspace's columns to the
-- screen (one-shot: new windows don't refit, press again) and stops centering
-- here; pressing it on a fitted workspace brings centering back.
local function fitted_key(ws)
	return "fitted." .. ws:current()
end

paneru.on("window_focused", function(event, ws)
	if not paneru.state.get(fitted_key(ws)) then
		paneru.run("window center")
	end
end)

paneru.bind(H .. "m", function(ws)
	local key = fitted_key(ws)
	if paneru.state.get(key) then
		paneru.state.set(key, nil)
		paneru.flash("auto-center")
		paneru.run("window center")
		return
	end
	paneru.state.set(key, true)
	local columns = ws:columns()
	for _, column in ipairs(columns) do
		ws = ws:width(column[1], 1 / #columns)
	end
	paneru.flash("fit " .. #columns)
	return ws
end)

-- Browser, same key as sway/niri on Linux: always a new window on this workspace.
-- `open -a` would raise an existing window (pulling us to its workspace); the binary
-- hands --new-window to the running Firefox, if its default profile is the one running.
paneru.bind(H .. "b", function()
	os.execute("(pgrep -qx firefox && /Applications/Firefox.app/Contents/MacOS/firefox --new-window || open -a Firefox) >/dev/null 2>&1 &")
end)

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
