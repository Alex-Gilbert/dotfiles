function whichkey_config ()
	local status_ok, which_key = pcall(require, "which-key")
	if not status_ok then
		return
	end
	which_key.add(require("alexg.leader-mappings"))
end



return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	init = function()
		vim.o.timeout = true
		vim.o.timeoutlen = 300
	end,
	config = whichkey_config,
}
