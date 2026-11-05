-- Paneru (sliding/scrolling tiler). Keys match niri on Linux.
-- Hot-reloads on save. Hyper = cmd+alt+ctrl+shift (kmonad hold-A / hold-S).
-- Paneru has no modes, so resize/move are direct chords.

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

-- Workspaces 1..10 -> virtual workspaces. alt-ctrl-N sends without following.
for n = 1, 10 do
	local key = tostring(n % 10)
	bindings["window virtualnum " .. n] = H .. key
	bindings["window virtualsendnum " .. n] = AC .. key
end

paneru.setup({
	-- No default_workspaces: 0.5.2 puts startup windows in every pre-made workspace, and
	-- they get parked in the bottom-right corner. Hyper-N creates workspaces on demand.
	restore = { enabled = false },
	options = {
		focus_follows_mouse = false,
		mouse_follows_focus = false,
		auto_center = false, -- done per workspace in Lua below (Hyper-m)
		-- No animation_speed: unset = no animation. Sliding left windows stuck at the
		-- bottom when switching workspaces quickly.
	},
	padding = { top = 5, bottom = 5, left = 5, right = 5 },
	windows = {
		-- 5px per window + 5px screen padding = 10px gaps between windows and at the edges
		gaps = { title = ".*", horizontal_padding = 5, vertical_padding = 5 },
		pip = { title = "Picture-in-Picture", floating = true },
		tridactyl = { title = "tridactyl-editor", floating = true },
		open_dialog = { title = "^Open$", floating = true },
		settings = { title = ".*", bundle_id = "com.apple.systempreferences", floating = true },
	},
	bindings = bindings,
})

paneru.bind(AS .. "k", "window stack")
paneru.bind(AS .. "j", "window unstack")

-- Auto-center, per workspace. Hyper-n lines the columns up from the left edge and stops
-- centering here; pressing it again brings centering back.
local function aligned_key(ws)
	return "aligned." .. ws:current()
end

-- `window center` always warps the mouse to the screen center, so skip it when the
-- focus came from a click (as native auto_center does) or didn't change window
-- (menus and the menu bar re-fire focus on the same window).
local mouse_down, last_centered, last_click = false, nil, nil
paneru.on("mouse_down", function(event)
	mouse_down = true
	last_click = { modifiers = event.modifiers, at = os.time() }
end)
paneru.on("mouse_up", function() mouse_down = false end)

-- Something hid every app mid screen share once, and Paneru shuffles hidden windows out
-- of the layout. Record each hide with the last click, to catch the cause next time.
paneru.on("application_hidden", function(event)
	local log = io.open(os.getenv("HOME") .. "/Library/Logs/paneru-app-hidden.log", "a")
	if log then
		log:write(os.date("%F %T"), " pid=", event.pid,
			" last_click_modifiers=", tostring(last_click and last_click.modifiers),
			" click_age_s=", tostring(last_click and os.time() - last_click.at), "\n")
		log:close()
	end
end)

-- Closing a workspace's last window: macOS focuses the app's next window, which pulls us
-- to its workspace. Stay put. With neighbours left, Paneru refocuses on this workspace.
-- shortcut: os.time is whole seconds, so Hyper-N right after a close can bounce back; no
-- finer clock in Paneru's Lua, narrow it if that ever gets annoying.
-- Track the workspace ourselves: on Hyper-q, ws:current() has already followed the focus.
local closed_from, focused_workspace = nil, nil
paneru.on("window_destroyed", function(event)
	if event.window_id == last_centered then
		closed_from = { workspace = focused_workspace, at = os.time() }
	end
end)

paneru.on("window_focused", function(event, ws)
	-- macOS repeats that focus event, so keep correcting until the window passes.
	if closed_from then
		local home = closed_from.workspace
		if home and os.time() - closed_from.at <= 1 and ws:workspace_of(event.window_id) ~= home then
			return ws:view(home)
		end
		closed_from = nil
	end
	focused_workspace = ws:workspace_of(event.window_id)
	local same = event.window_id == last_centered
	last_centered = event.window_id
	if not (same or mouse_down or paneru.state.get(aligned_key(ws))) then
		paneru.run("window center")
	end
end)

-- One-shot: new windows don't refit, press again. ws:width only resizes the focused
-- window, so size that one and let `window balance` copy its width to the rest. Balance
-- reads the live size, so it has to wait for the resize. The immediate run covers a
-- window already at that width, which fires no event.
local balance_after = nil
paneru.bind(H .. "m", function(ws)
	local focused = ws:focused()
	if not focused then
		return
	end
	local columns = #ws:columns()
	balance_after = { id = focused, at = os.time() }
	paneru.run("window balance")
	paneru.flash("fit " .. columns)
	return ws:width(focused, 1 / columns)
end)

paneru.on("window_resized", function(event)
	if balance_after and event.window_id == balance_after.id then
		local fresh = os.time() - balance_after.at <= 1
		balance_after = nil
		if fresh then
			paneru.run("window balance")
		end
	end
end)

paneru.bind(H .. "n", function(ws)
	local key = aligned_key(ws)
	if paneru.state.get(key) then
		paneru.state.set(key, nil)
		paneru.flash("auto-center")
		paneru.run("window center")
		return
	end
	paneru.state.set(key, true)
	paneru.flash("aligned")
	-- Focusing the first column is what scrolls the row flush left.
	local focused = ws:focused()
	paneru.run("window focus first")
	if focused then
		return ws:focus(focused)
	end
end)

-- Browser, same key as sway/niri on Linux: always a new window on this workspace.
-- `open -a` would raise an existing window (pulling us to its workspace); the binary
-- hands --new-window to the running Firefox, if its default profile is the one running.
paneru.bind(H .. "b", function()
	os.execute("(pgrep -qx firefox && /Applications/Firefox.app/Contents/MacOS/firefox --new-window || open -a Firefox) >/dev/null 2>&1 &")
end)

-- File manager, same key as yazi on Linux. Shuffle is single-window: this raises it.
paneru.bind(H .. "e", function()
	os.execute("open -a Shuffle >/dev/null 2>&1 &")
end)

-- Close: Paneru has no close command (see close-window.js). The script refuses if the
-- frontmost app isn't the one Paneru has focused: on an empty workspace macOS can still
-- have a hidden window active, and cmd-w would close it.
paneru.bind(H .. "q", function(ws)
	local window = ws:focused() and ws:window(ws:focused())
	local bundle = window and window.bundle_id
	if not (bundle and bundle:match("^[%w%.%-]+$")) then
		paneru.flash("nothing to close")
		return
	end
	os.execute("osascript -l JavaScript ~/.config/paneru/close-window.js " .. bundle .. " >/dev/null 2>>/tmp/paneru-close.log &")
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
-- (the launchd service's PATH lacks Homebrew)
os.execute("pgrep -qx borders || (PATH=/opt/homebrew/bin:$PATH borders >/dev/null 2>&1 &)")
