local function lspzero_config()
    local lsp_zero = require('lsp-zero')

    lsp_zero.on_attach(function(client, bufnr)
        vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
        vim.keymap.set("n", "gD", function() vim.lsp.buf.declaration() end, opts)
        vim.keymap.set("n", "gi", function() vim.lsp.buf.implementation() end, opts)
        vim.keymap.set("n", "gs", function() vim.lsp.buf.signature_help() end, opts)

        vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)

        vim.keymap.set("n", "[d", function() vim.diagnostics.goto_prev() end, opts)
        vim.keymap.set("n", "]d", function() vim.diagnostics.goto_next() end, opts)

        vim.keymap.set('n', 'gr', '<cmd>Telescope lsp_references<cr>', { buffer = true })
        -- lsp zero will preserve already existing keymaps
        lsp_zero.default_keymaps({ buffer = bufnr })
    end)

    require('mason').setup()
    require('mason-lspconfig').setup({
        ensure_installed = { 'rust_analyzer', 'csharp_ls', 'zls', 'lua_ls' },
        handlers = require('alexg.lspconfigs'),
    })

    local cmp = require('cmp')
    cmp.setup(require('alexg.cmp'))
end

return {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v3.x',
    dependencies = {
        -- LSP Support
        { 'neovim/nvim-lspconfig' },             -- Required
        { 'williamboman/mason.nvim' },           -- Optional
        { 'williamboman/mason-lspconfig.nvim' }, -- Optional

        -- Autocompletion
        { 'hrsh7th/nvim-cmp' },     -- Required
        { 'hrsh7th/cmp-nvim-lsp' }, -- Required
        { 'hrsh7th/cmp-buffer' },   -- Optional
        { 'hrsh7th/cmp-path' },     -- Optional
        { 'hrsh7th/cmp-nvim-lua' }, -- Optional

        -- Snippets
        {
            "L3MON4D3/LuaSnip",
            build = vim.fn.has "win32" ~= 0 and "make install_jsregexp" or nil,
            dependencies = {
                "rafamadriz/friendly-snippets",
                "benfowler/telescope-luasnip.nvim",
                'saadparwaiz1/cmp_luasnip',
            },
            config = function(_, opts)
                local ls = require("luasnip")
                if opts then ls.config.setup(opts) end
                vim.tbl_map(
                    function(type) require("luasnip.loaders.from_" .. type).lazy_load() end,
                    { "vscode", "snipmate", "lua" }
                )
                -- friendly-snippets - enable standardized comments snippets
                ls.filetype_extend("typescript", { "tsdoc" })
                ls.filetype_extend("javascript", { "jsdoc" })
                ls.filetype_extend("lua", { "luadoc" })
                ls.filetype_extend("python", { "pydoc" })
                ls.filetype_extend("rust", { "rustdoc" })
                ls.filetype_extend("cs", { "csharpdoc" })
                ls.filetype_extend("java", { "javadoc" })
                ls.filetype_extend("c", { "cdoc" })
                ls.filetype_extend("cpp", { "cppdoc" })
                ls.filetype_extend("php", { "phpdoc" })
                ls.filetype_extend("kotlin", { "kdoc" })
                ls.filetype_extend("ruby", { "rdoc" })
                ls.filetype_extend("sh", { "shelldoc" })

                vim.keymap.set({ "i", "s" }, "<C-E>", function()
                    if ls.choice_active() then
                        ls.change_choice(1)
                    end
                end, { silent = true })
            end,
        },
    },
    config = lspzero_config,
}
