local opt = vim.opt
local g = vim.g

-- options to set after vim has loaded
vim.schedule(function()
    opt.clipboard = "unnamedplus"  -- Sync with system clipboard
end)

g.copilot_no_tab_map = true
g.have_nerd_font = true

opt.autowrite = true           -- Enable auto write
opt.completeopt = "menu,menuone,noselect"
opt.conceallevel = 0           -- So that I can see `` in markdown files
opt.confirm = true             -- Confirm to save changes before exiting modified buffer
opt.cursorline = true          -- Enable highlighting of the current line
opt.colorcolumn = "120"
opt.expandtab = true           -- Use spaces instead of tabs
opt.formatoptions = "jqlnt"
opt.grepformat = "%f:%l:%c:%m"
opt.grepprg = "rg --vimgrep"
opt.ignorecase = true      -- Ignore case
opt.inccommand = "split" -- preview incremental substitute
opt.incsearch = true
opt.laststatus = 0
opt.list = true           -- Show some invisible characters (tabs...
opt.mouse = "a"           -- Enable mouse mode
opt.number = true         -- Print line number
opt.pumblend = 10         -- Popup blend
opt.pumheight = 10        -- Maximum number of entries in a popup
opt.relativenumber = true -- Relative line numbers
opt.scrolloff = 8         -- Lines of context
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize" }
opt.shiftround = true     -- Round indent
opt.shiftwidth = 4        -- Size of an indent
opt.shortmess:append { W = true, I = true, c = true }
opt.showmode = false      -- Dont show mode since we have a statusline
opt.sidescrolloff = 8     -- Columns of context
opt.signcolumn = "yes"    -- Always show the signcolumn, otherwise it would shift the text each time
opt.smartcase = true      -- Don't ignore case with capitals
opt.smartindent = true    -- Insert indents automatically
opt.spelllang = { "en" }
opt.splitbelow = true     -- Put new windows below current
opt.splitright = true     -- Put new windows right of current
opt.tabstop = 4           -- Number of spaces tabs count for
opt.termguicolors = true  -- True color support
opt.timeoutlen = 350      -- speed must be under 500ms inorder for keys to work, increase if you are not able to.
opt.undofile = true
opt.undolevels = 10000
opt.updatetime = 50               -- Save swap file and trigger CursorHold
opt.wildmode = "longest:full,full" -- Command-line completion mode
opt.winminwidth = 5                -- Minimum window width
opt.wrap = false                   -- Disable line wrap.

opt.swapfile = false
opt.backup = false
opt.undodir = os.getenv('HOME') .. '/.vim/undodir'
opt.undofile = true

opt.isfname:append("@-@")

-- Fix markdown indentation settings
g.markdown_recommended_style = 0

-- Fix the fucking commenting bullshit
vim.cmd([[autocmd BufEnter * set formatoptions-=cro]])

-- Auto insert when entering termnal windows
vim.cmd([[autocmd WinEnter term://* star]])

-- Register wgsl files
vim.cmd([[autocmd BufNewFile,BufRead *.wgsl setfiletype wgsl]])

-- Presenting Options
g.presenting_font_large = 'maxiwi'
g.presenting_font_small = 'miniwi'
