-- Wait for the UI to load, then set up the "Yank and Quit" trigger
vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("YankAndQuit", { clear = true }),
	callback = function()
		-- Brief delay to ensure the yank syncs to the system clipboard/tmux
		vim.defer_fn(function()
			vim.cmd("qa!")
		end, 50)
	end,
})

-- Optional: Jump to the bottom of the file automatically
vim.cmd("normal! G")
