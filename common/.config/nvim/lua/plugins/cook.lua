return {
	-- cook build system: live build panel, cache `why` explorer, Cookfile smarts
	dir = "~/dev/cook.nvim",
	-- local checkout only for now; skip on machines that don't have it
	cond = vim.uv.fs_stat(vim.fn.expand("~/dev/cook.nvim")) ~= nil,
	-- not lazy: its ftdetect/ftplugin must be on 'rtp' before the first Cookfile opens.
	-- plugin/cook.lua only defines :Cook and two autocmds; modules load on use.
	lazy = false,
	keys = require("alex-config.keymaps").cook_keys,
	opts = {},
	config = function(_, opts)
		require("cook").setup(opts)
	end,
}
