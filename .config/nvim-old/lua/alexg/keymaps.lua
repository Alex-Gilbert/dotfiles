local opts = { noremap = true, silent = true }

local term_opts = { silent = true }

-- Shorten function name
local keymap = vim.api.nvim_set_keymap

--Remap space as leader key
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",
-- Visual --

-- Better pasting
keymap("v", "<C-p>", "\"_dP", opts)


-- Normal --
-- Better window navigation
keymap("n", "<C-h>", "<C-w>h", opts) -- left window
keymap("n", "<C-k>", "<C-w>k", opts) -- up window
keymap("n", "<C-j>", "<C-w>j", opts) -- down window
keymap("n", "<C-l>", "<C-w>l", opts) -- right window

-- Page Scrolling
keymap("n", "<C-d>", "<C-d>zz", opts) -- right window
keymap("n", "<C-u>", "<C-u>zz", opts) -- right window

-- Better search
keymap("n", "n", "nzzzv", opts) -- right window
keymap("n", "N", "Nzzzv", opts) -- right window

-- Resize with arrows when using multiple windows
keymap("n", "<C-Up>", ":resize -2<CR>", opts)
keymap("n", "<C-down>", ":resize +2<cr>", opts)
keymap("n", "<C-right>", ":vertical resize -2<cr>", opts)
keymap("n", "<C-left>", ":vertical resize +2<cr>", opts)

-- navigate buffers with harpoon
keymap("n", "<F7>", ":lua require'harpoon.ui'.nav_file(1)<CR>", opts)
keymap("n", "<F8>", ":lua require'harpoon.ui'.nav_file(2)<CR>", opts)
keymap("n", "<F9>", ":lua require'harpoon.ui'.nav_file(3)<CR>", opts)
keymap("n", "<F10>", ":lua require'harpoon.ui'.nav_file(4)<CR>", opts)
keymap("n", "<F11>", ":lua require'harpoon.ui'.nav_file(5)<CR>", opts)
keymap("n", "<F12>", ":lua require'harpoon.ui'.nav_file(6)<CR>", opts)

--Better terminal navigation
keymap("t", "<C-X>", "<C-\\><C-N>", term_opts)
keymap("t", "<C-h>", "<C-\\><C-N><C-w>h", term_opts)
keymap("t", "<C-j>", "<C-\\><C-N><C-w>j", term_opts)
keymap("t", "<C-k>", "<C-\\><C-N><C-w>k", term_opts)
keymap("t", "<C-l>", "<C-\\><C-N><C-w>l", term_opts)

-- Copilot
vim.g.copilot_no_tab_map = true
local map = vim.keymap.set
map("i", "<C-L>", "copilot#Accept('<CR>')", {noremap = true, silent = true, expr=true, replace_keycodes = false })
map('i', '<C-S>', '<Plug>(copilot-accept-word)')
