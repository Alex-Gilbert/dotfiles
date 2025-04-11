return {
	-- Colorscheme
	{
		"rebelot/kanagawa.nvim",
		lazy = false, -- make sure we load this during startup if it is your main colorscheme
		priority = 1000, -- make sure to load this before all the other start plugins
		opts = {
			compile = false, -- enable compiling the colorscheme
			undercurl = true, -- enable undercurls
			commentStyle = { italic = true },
			functionStyle = {},
			keywordStyle = { italic = true },
			statementStyle = { bold = true },
			typeStyle = {},
			transparent = false, -- do not set background color
			dimInactive = true, -- dim inactive window `:h hl-NormalNC`
			terminalColors = true, -- define vim.g.terminal_color_{0,17}
			colors = { -- add/modify theme and palette colors
				palette = {},
				theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
			},
			theme = "wave", -- Load "wave" theme when 'background' option is not set
			background = { -- map the value of 'background' option to a theme
				dark = "wave", -- try "dragon" !
				light = "lotus",
			},
		},
		config = function()
			vim.cmd([[colorscheme kanagawa]])
		end,
	},

	-- {
	-- 	"aktersnurra/no-clown-fiesta.nvim",
	-- 	priority = 1000,
	-- 	config = function()
	-- 		local opts = {
	-- 			styles = {
	-- 				type = { bold = true },
	-- 				lsp = { underline = false },
	-- 				match_paren = { underline = true },
	-- 			},
	-- 		}
	--
	-- 		local plugin = require("no-clown-fiesta")
	-- 		plugin.setup(opts)
	-- 		return plugin.load()
	-- 	end,
	-- 	lazy = false,
	-- },

	"Zeioth/heirline-components.nvim",
	"SmiteshP/nvim-navic",

	-- Status Line
	{
		"rebelot/heirline.nvim",
		depends = {
			"rebelot/kanagawa.nvim",
			"Zeioth/heirline-components.nvim",
			"SmiteshP/nvim-navic",
			"ThePrimeagen/harpoon",
		},
		lazy = false,
		config = function()
			-- local colors = require("kanagawa.colors").setup()
			-- local colors = require("kanagawa.colors").setup()
			local heirline = require("heirline")
			local my_heir = require("alex-config.heirlines")
			local components = require("heirline-components.all")

			heirline.load_colors(components.hl.get_colors())

			heirline.setup({
				statusline = my_heir.Statusline,
				tabline = my_heir.TabLine,
			})

			vim.o.showtabline = 2
		end,
	},
}
