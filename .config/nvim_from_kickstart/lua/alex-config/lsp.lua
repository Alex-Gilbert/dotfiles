local lsp = require('lspconfig')

local M = {}

M.additional_tools = { 'stylua' }

M.servers = {
    rust_analyzer = {},

    lua_ls = {
        settings = {
            Lua = {
                completion = {
                    callSnippet = 'Replace',
                },
            },
        },
    },

    csharp_ls = {
        on_attach = function()
            print('Hello From C#')
        end,
        filetypes = { "cs" },
        root_dir = function(startpath)
            return lsp.util.root_pattern("*.sln")(startpath)
                or lsp.util.root_pattern("*.csproj")(startpath)
                or lsp.util.root_pattern("*.fsproj")(startpath)
                or lsp.util.root_pattern(".git")(startpath)
        end,
        init_options = {
            AutomaticWorkspaceInit = true
        },
    },

    pylsp = {
        on_attach = function()
            print('Hello From Python')
        end,
        settings = {
            pylsp = {
                plugins = {
                    pycodestyle = {
                        maxLineLength = 120
                    },
                },
            },
        },
    },
}

return M
