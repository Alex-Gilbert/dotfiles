return {
	{
		"pwntester/octo.nvim",
		cmd = { "Octo", "OctoAttach" },
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		opts = {
			picker = "telescope",
			enable_builtin = true,
			ssh_aliases = { ["p%.github%.com"] = "github.com" },
		},
		config = function(_, opts)
			require("octo").setup(opts)
			vim.api.nvim_create_user_command("OctoAttach", function(args)
				require("alex-config.octo-attach").attach(args.fargs[1])
			end, { nargs = "?", complete = "file", desc = "Upload image/video to the open PR description" })
		end,
		keys = {
			{ "<leader>gpo", "<cmd>Octo pr edit<cr>", desc = "Open current PR" },
			{ "<leader>gpl", "<cmd>Octo pr list<cr>", desc = "List PRs" },
			{ "<leader>gpc", "<cmd>Octo pr create<cr>", desc = "Create PR" },
			{ "<leader>gpr", "<cmd>Octo review start<cr>", desc = "Review PR" },
			{ "<leader>gps", "<cmd>Octo pr checks<cr>", desc = "PR checks" },
			{ "<leader>gpi", "<cmd>OctoAttach<cr>", desc = "Upload image/video to PR description" },
			{ "<leader>gpb", "<cmd>Octo pr browser<cr>", desc = "Open PR in browser" },
			{ "<leader>gpa", "<cmd>Octo<cr>", desc = "GitHub actions" },
		},
	},
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
		keys = require("alex-config.keymaps").diffview_keys,
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
