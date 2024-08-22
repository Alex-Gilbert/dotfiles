---@type user_options
local surround_opts = {
    keymaps = {
        insert = "<C-g>s",
        insert_line = "<C-g>S",
        normal = "z",
        normal_cur = "zz",
        normal_line = "Z",
        normal_cur_line = "ZZ",
        visual = "z",
        visual_line = "Z",
        delete = "<leader>sd",
        change = "<leader>sc",
        change_line = "<leader>cS",
    },
}

return {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
        require("nvim-surround").setup(surround_opts)
    end
}
