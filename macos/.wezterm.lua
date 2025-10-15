local wezterm = require("wezterm")

return {
	-- Font
	font = wezterm.font("JetBrainsMono Nerd Font"),
	font_size = 18.0,

	-- Window padding
	window_padding = {
		left = 10,
		right = 10,
		top = 10,
		bottom = 10,
	},

	-- Colors (Kanagawa-inspired)
	colors = {
		foreground = "#DCD7BA",
		background = "#1F1F28",
		cursor_bg = "#C8C093",
		cursor_border = "#C8C093",
		cursor_fg = "#1F1F28",
		selection_bg = "#2D4F67",
		selection_fg = "#C8C093",
		ansi = {
			"#16161D",
			"#C34043",
			"#76946A",
			"#C0A36E",
			"#7E9CD8",
			"#957FB8",
			"#6A9589",
			"#C8C093",
		},
		brights = {
			"#727169",
			"#E82424",
			"#98BB6C",
			"#E6C384",
			"#7FB4CA",
			"#938AA9",
			"#7AA89F",
			"#DCD7BA",
		},
		indexed = {
			[16] = "#FFA066",
			[17] = "#FF5D62",
		},
	},

	-- Transparency
	window_background_opacity = 0.90,

	-- Cursor
	default_cursor_style = "BlinkingBlock",

	-- Scrollback
	scrollback_lines = 10000,

	-- macOS tweaks
	macos_window_background_blur = 20,
	macos_forward_to_ime_modifier_mask = "OPT", -- option as alt
	hide_tab_bar_if_only_one_tab = true,

	-- Disable Close Prompt
	window_close_confirmation = "NeverPrompt",
	keys = {
		{ key = "Enter", mods = "SHIFT", action = wezterm.action({ SendString = "\x1b\r" }) },
	},
}
