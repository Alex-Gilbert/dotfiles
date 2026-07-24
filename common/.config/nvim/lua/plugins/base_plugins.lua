return {
	-- 'tpope/vim-slueth',
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
				"diff",
				"elixir",
				"gleam",
				"go",
				"heex",
				"html",
				"lua",
				"luadoc",
				"markdown",
				"markdown_inline",
				"query",
				"vim",
				"vimdoc",
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
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		lazy = false,
	},

	{
		"ravsii/tree-sitter-d2",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		build = "make nvim-install",
	},
}
