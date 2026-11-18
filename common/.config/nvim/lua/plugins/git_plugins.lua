return {
	{ -- Adds git related signs to the gutter, as well as utilities for managing changes
		"lewis6991/gitsigns.nvim",
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
		},
	},
	{ -- Diffview - better diff/merge conflict UI
		"sindrets/diffview.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles" },
		-- forge keys (PR pickers) live here too: they all end in diffview
		keys = vim.list_extend(
			vim.list_extend(vim.deepcopy(require("alex-config.keymaps").diffview_keys), require("alex-config.forge").keys),
			require("gitea").keys
		),
		opts = {
			enhanced_diff_hl = true,
			view = {
				default = { layout = "diff2_horizontal" },
				merge_tool = {
					layout = "diff3_mixed",
					disable_diagnostics = true,
				},
			},
			file_panel = {
				win_config = { position = "left", width = 35 },
			},
		},
	},
	-- LazyGit now provided by snacks.nvim
}
