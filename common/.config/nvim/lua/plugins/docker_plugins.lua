return {
	{ -- Docker dashboard: containers/images/compose/logs + container file browser
		"emrearmagan/dockyard.nvim",
		cmd = { "Dockyard", "DockyardFloat", "DockyardBuild", "DockyardRun", "DockyardFiles" },
		keys = require("alex-config.keymaps").dockyard_keys,
		opts = {
			display = { views = { "containers", "compose", "images", "networks", "volumes" } },
			-- its shell needs toggleterm; <leader>Ds uses Snacks.terminal instead
			keymaps = { containers = { open_terminal = false } },
		},
		config = function(_, opts)
			require("dockyard").setup(opts)
			-- `c` in the container file browser copies the entry under the cursor to the host
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "dockyard-files",
				callback = function(ev)
					vim.keymap.set("n", "c", function()
						require("alex-config.docker-cp").pull()
					end, { buffer = ev.buf, desc = "Copy to host (docker cp)" })
				end,
			})
		end,
	},
}
