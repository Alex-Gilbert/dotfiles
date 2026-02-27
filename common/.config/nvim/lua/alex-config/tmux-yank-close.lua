vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Close nvim after yanking from tmux scratch buffer",
	group = vim.api.nvim_create_augroup("tmux-yank-close", { clear = true }),
	callback = function()
		if vim.v.event.operator == "y" then
			vim.defer_fn(function()
				vim.cmd("qa!")
			end, 100)
		end
	end,
})
