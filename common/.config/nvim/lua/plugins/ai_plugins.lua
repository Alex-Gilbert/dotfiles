return {
	-- Snacks.nvim (required for opencode.nvim input/picker/terminal)
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		opts = {
			input = { enabled = true },
			picker = { enabled = true },
			terminal = { enabled = true },
		},
	},

	-- OpenCode.nvim (AI assistant integration)
	{
		"NickvanDyke/opencode.nvim",
		dependencies = { "folke/snacks.nvim" },
		event = "VeryLazy",
		config = function()
			---@type opencode.Opts
			vim.g.opencode_opts = {
				-- Auto-detect opencode running in CWD, or use snacks terminal
				provider = {
					enabled = "snacks",
				},
				-- Reload buffers when opencode edits files
				events = {
					reload = true,
				},
			}

			-- Required for events.reload
			vim.o.autoread = true

			require("alex-config.keymaps").set_opencode_keys()
		end,
	},
}
