-- [[Globals]]
-- See `:help vim.g`
vim.g.have_nerd_font = true

-- [[ Setting options ]]
-- See `:help vim.opt`
vim.opt.relativenumber = true
vim.opt.clipboard = 'xclip'
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = 'yes'

-- this controls writes to the swap file
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300

vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.opt.inccommand = 'split'
vim.opt.cursorline = true
vim.opt.scrolloff = 10
vim.opt.hlsearch = true
