return {
	-- Snacks.nvim - QoL plugin suite
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		---@type snacks.Config
		opts = {
			-- Core features (already using)
			input = { enabled = true },
			picker = {
				enabled = true,
				ui_select = true, -- replaces telescope-ui-select
			},
			terminal = { enabled = true },

			-- New high-value additions
			bigfile = { enabled = true },
			quickfile = { enabled = true },
			words = { enabled = true },
			lazygit = { enabled = true },
			zen = { enabled = true },
			gitbrowse = { enabled = true },
			toggle = { enabled = true },
			bufdelete = { enabled = true },
			indent = { enabled = true },
			scope = { enabled = true },
			dim = { enabled = true },
			-- notifier disabled - using noice.nvim instead
			-- notifier = { enabled = true, timeout = 3000 },
			scratch = { enabled = true },
			rename = { enabled = true },
			debug = { enabled = true },
		},
		init = function()
			vim.api.nvim_create_autocmd("User", {
				pattern = "VeryLazy",
				callback = function()
					-- Setup debug globals
					_G.dd = function(...)
						Snacks.debug.inspect(...)
					end
					_G.bt = function()
						Snacks.debug.backtrace()
					end
					vim.print = _G.dd

					-- Toggle mappings (using <leader>u prefix for "UI/Utils")
					Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
					Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
					Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
					Snacks.toggle.diagnostics():map("<leader>ud")
					Snacks.toggle.line_number():map("<leader>ul")
					Snacks.toggle
						.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
						:map("<leader>uc")
					Snacks.toggle.treesitter():map("<leader>uT")
					Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
					Snacks.toggle.inlay_hints():map("<leader>uh")
					Snacks.toggle.indent():map("<leader>ug")
					Snacks.toggle.dim():map("<leader>uD")
				end,
			})
		end,
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
