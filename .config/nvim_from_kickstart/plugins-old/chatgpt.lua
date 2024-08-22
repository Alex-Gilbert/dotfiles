return {
    "jackMort/ChatGPT.nvim",
    lazy = true,
    config = function()
        local home = vim.fn.expand("$HOME")
        require("chatgpt").setup({
            api_key_cmd = "gpg --decrypt " .. home .. "/.config/gpt-secret.sec"
        })
    end,
    dependencies = {
        "MunifTanjim/nui.nvim",
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope.nvim"
    },
    cmd = {
        "ChatGPT",
        "ChatGPTEditWithInstruction",
        "ChatGPTRun"
    }
}
