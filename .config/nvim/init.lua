package.cpath = package.cpath .. ";/home/alex/lua51/lib/lua/5.1/jsregexp/?.so"

require("alexg.keymaps")
require("alexg.options")
require("alexg.lazy-config")
require("current-theme")
require("alexg.my_scripts.rust_analyzer_scripts")

vim.api.nvim_set_keymap('n', '<leader>b', ":lua require('alexg.my_scripts.make_targets').telescope()<CR>", {noremap = true, silent = true})

local pipepath = vim.fn.stdpath("cache") .. "/server.pipe"
if not vim.loop.fs_stat(pipepath) then
  vim.fn.serverstart(pipepath)
end
