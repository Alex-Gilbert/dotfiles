return {
	-- 'tpope/vim-slueth',

	-- Snacks: QoL suite. keymaps.lua:set_snacks_keys() binds ~11 keys against
	-- the Snacks global (zen, lazygit, gitbrowse, bufdelete, scratch, rename,
	-- words, terminal), so this has to be installed and loaded eagerly or
	-- every one of those keys errors with "attempt to index global 'Snacks'".
	--
	-- Only the modules those keymaps actually use are enabled. Deliberately
	-- left OFF, because something else already owns each of these:
	--   picker / explorer  -> telescope + fff.nvim
	--   notifier           -> nvim-notify + noice.nvim
	--   input              -> noice.nvim
	--   statuscolumn       -> heirline
	--   dashboard          -> not used
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		---@type snacks.Config
		opts = {
			-- Autocmd-driven, so it needs explicit enabling. Backs ]] / [[.
			words = { enabled = true },

			-- Pure wins: skip expensive setup on huge files, and render the
			-- file passed on the command line before the rest of startup.
			bigfile = { enabled = true },
			quickfile = { enabled = true },

			-- Called on demand from keymaps; enabled here to carry config.
			zen = { enabled = true },
			scratch = { enabled = true },
			terminal = { enabled = true },

			notifier = { enabled = false },
			picker = { enabled = false },
			input = { enabled = false },
			dashboard = { enabled = false },
			statuscolumn = { enabled = false },
			indent = { enabled = false },
			scroll = { enabled = false },
		},
	},

	{ -- Useful plugin to show you pending keybinds.
		"folke/which-key.nvim",
		event = "VimEnter", -- Sets the loading event to 'VimEnter'
		opts = {
			delay = 0,
			icons = {
				mappings = vim.g.have_nerd_font,
				keys = vim.g.have_nerd_font and {} or {
					Up = "<Up> ",
					Down = "<Down> ",
					Left = "<Left> ",
					Right = "<Right> ",
					C = "<C-…> ",
					M = "<M-…> ",
					D = "<D-…> ",
					S = "<S-…> ",
					CR = "<CR> ",
					Esc = "<Esc> ",
					ScrollWheelDown = "<ScrollWheelDown> ",
					ScrollWheelUp = "<ScrollWheelUp> ",
					NL = "<NL> ",
					BS = "<BS> ",
					Space = "<Space> ",
					Tab = "<Tab> ",
					F1 = "<F1>",
					F2 = "<F2>",
					F3 = "<F3>",
					F4 = "<F4>",
					F5 = "<F5>",
					F6 = "<F6>",
					F7 = "<F7>",
					F8 = "<F8>",
					F9 = "<F9>",
					F10 = "<F10>",
					F11 = "<F11>",
					F12 = "<F12>",
				},
			},

			spec = require("alex-config.keymaps").whichkey_spec,
		},
	},

	-- Tree-sitter (main branch — new architecture for Neovim 0.11+; upstream
	-- archived 2026-04-03 but the main-branch code is the recommended setup
	-- for 0.12 and remains functional).
	--
	-- Parser installs happen once at `build` time (synchronously, with :wait).
	-- Doing it on every startup is noisy because install/update log per-language
	-- via vim.api.nvim_echo. Add new parsers to ensure_parsers and run :Lazy
	-- build nvim-treesitter (or :TSInstall <lang>) to pick them up.
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = function()
			local ensure = {
				"bash",
				"c",
				"css",
				"diff",
				"dockerfile",
				"elixir",
				"fish",
				"gitcommit",
				"gleam",
				"go",
				"heex",
				"html",
				"javascript",
				"json",
				"lua",
				"luadoc",
				"markdown",
				"markdown_inline",
				"nix",
				"python",
				"query",
				"rust",
				"sql",
				"toml",
				"tsx",
				"typescript",
				"vim",
				"vimdoc",
				"yaml",
			}
			require("nvim-treesitter").install(ensure):wait(300000)
		end,
		config = function()
			require("nvim-treesitter").setup()

			local cook_dir = vim.fn.expand("~/dev/cook/tree-sitter-cook")
			if vim.fn.isdirectory(cook_dir) then
				vim.api.nvim_create_autocmd("User", {
					pattern = "TSUpdate",
					callback = function()
						require("nvim-treesitter.parsers").cook = {
							install_info = {
								path = cook_dir,
							},
						}
					end,
				})
				vim.treesitter.language.register("cook", { "cook" })
			end

			vim.api.nvim_create_autocmd("FileType", {
				callback = function(args)
					local ft = vim.bo[args.buf].filetype
					if ft == "" then
						return
					end
					local lang = vim.treesitter.language.get_lang(ft) or ft
					if not pcall(vim.treesitter.language.add, lang) then
						return
					end
					pcall(vim.treesitter.start, args.buf, lang)
					vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
					vim.wo.foldmethod = "expr"
					if ft ~= "ruby" then
						vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
					end
				end,
			})
		end,
	},

	-- Tree-sitter textobjects (main branch — ships textobjects.scm queries
	-- consumed by mini.ai's ai.gen_spec.treesitter()).
	--
	-- lazy = false because mini.ai reads the textobjects queries at setup time;
	-- deferring to VeryLazy raced that lookup.
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		lazy = false,
		config = function()
			require("nvim-treesitter-textobjects").setup({
				select = { lookahead = true },
				move = { set_jumps = true },
			})

			local move = require("nvim-treesitter-textobjects.move")
			local swap = require("nvim-treesitter-textobjects.swap")
			local map = vim.keymap.set

			map({ "n", "x", "o" }, "]f", function()
				move.goto_next_start("@function.outer", "textobjects")
			end, { desc = "Next function start" })
			map({ "n", "x", "o" }, "]c", function()
				move.goto_next_start("@class.outer", "textobjects")
			end, { desc = "Next class start" })
			map({ "n", "x", "o" }, "]a", function()
				move.goto_next_start("@parameter.inner", "textobjects")
			end, { desc = "Next parameter start" })
			map({ "n", "x", "o" }, "]F", function()
				move.goto_next_end("@function.outer", "textobjects")
			end, { desc = "Next function end" })
			map({ "n", "x", "o" }, "]C", function()
				move.goto_next_end("@class.outer", "textobjects")
			end, { desc = "Next class end" })
			map({ "n", "x", "o" }, "[f", function()
				move.goto_previous_start("@function.outer", "textobjects")
			end, { desc = "Prev function start" })
			map({ "n", "x", "o" }, "[c", function()
				move.goto_previous_start("@class.outer", "textobjects")
			end, { desc = "Prev class start" })
			map({ "n", "x", "o" }, "[a", function()
				move.goto_previous_start("@parameter.inner", "textobjects")
			end, { desc = "Prev parameter start" })
			map({ "n", "x", "o" }, "[F", function()
				move.goto_previous_end("@function.outer", "textobjects")
			end, { desc = "Prev function end" })
			map({ "n", "x", "o" }, "[C", function()
				move.goto_previous_end("@class.outer", "textobjects")
			end, { desc = "Prev class end" })

			map("n", "<leader>xp", function()
				swap.swap_next("@parameter.inner")
			end, { desc = "Swap parameter with next" })
			map("n", "<leader>xP", function()
				swap.swap_previous("@parameter.inner")
			end, { desc = "Swap parameter with previous" })
		end,
	},

	{
		"ravsii/tree-sitter-d2",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		build = "make nvim-install",
	},
}
