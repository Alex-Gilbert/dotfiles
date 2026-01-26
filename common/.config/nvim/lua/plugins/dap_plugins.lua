local M = {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			{ "igorlfs/nvim-dap-view", opts = {} },
			{ "theHamsta/nvim-dap-virtual-text" },
			{ "nvim-neotest/nvim-nio" },

			{ "jay-babu/mason-nvim-dap.nvim" },
			{ "LiadOz/nvim-dap-repl-highlights", opts = {} },
			{ "nvim-tree/nvim-web-devicons" },
			{ "echasnovski/mini.icons", opts = {} },
		},
        -- stylua: ignore
        keys = require("alex-config.keymaps").dap_keys,
		opts = {},
		config = function(plugin, opts)
			require("nvim-dap-virtual-text").setup(opts)

			local dap = require("dap")
			local dapui = require("dap-view")

			vim.cmd("hi DapBreakpointColor guifg=#e51400") -- Bright red for breakpoints
			vim.cmd("hi DapBreakpointConditionColor guifg=#ffa500") -- Orange for conditional breakpoints
			vim.cmd("hi DapBreakpointRejectedColor guifg=#888888") -- Gray for rejected breakpoints
			vim.cmd("hi DapStoppedColor guifg=#00ff00") -- Green for current execution line
			vim.cmd("hi DapLogPointColor guifg=#61afef") -- Blue for log points

			-- Define the signs with icons and colors
			vim.fn.sign_define(
				"DapBreakpoint",
				{ text = "●", texthl = "DapBreakpointColor", linehl = "", numhl = "" }
			)

			vim.fn.sign_define(
				"DapBreakpointCondition",
				{ text = "◐", texthl = "DapBreakpointConditionColor", linehl = "", numhl = "" }
			)

			vim.fn.sign_define(
				"DapBreakpointRejected",
				{ text = "●", texthl = "DapBreakpointRejectedColor", linehl = "", numhl = "" }
			)

			vim.fn.sign_define(
				"DapStopped",
				{ text = "󰁕", texthl = "DapStoppedColor", linehl = "DapStoppedLine", numhl = "DapStoppedColor" }
			)

			vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DapLogPointColor", linehl = "", numhl = "" })

			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end
		end,
	},
	{

		"jay-babu/mason-nvim-dap.nvim",
		dependencies = "mason.nvim",
		cmd = { "DapInstall", "DapUninstall" },
		opts = {
			automatic_setup = true,
			handlers = {},
			ensure_installed = {},
		},
	},

	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"antoinemadec/FixCursorHold.nvim",
			"nvim-treesitter/nvim-treesitter",
			"Issafalcon/neotest-dotnet",
			{
				"fredrikaverpil/neotest-golang", -- Installation
				dependencies = {
					"leoluz/nvim-dap-go",
				},
			},
		},
		keys = require("alex-config.keymaps").neotest_keys,
	},
}

return M
