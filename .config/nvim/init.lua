require("alexg.keymaps")
require("alexg.options")
require("alexg.lazy-config")

vim.api.nvim_set_keymap('n', '<leader>b', ":lua require('alexg.my_scripts.make_targets').telescope()<CR>", {noremap = true, silent = true})
