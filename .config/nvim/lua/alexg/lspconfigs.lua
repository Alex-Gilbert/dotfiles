local lspzero = require('lsp-zero').preset({})
local lsp = require('lspconfig')

return {
    lspzero.default_setup,
    csharp_ls = function()
        lsp.csharp_ls.setup({
            on_attach = function ()
                print('Hello From C Sharp')
            end,
            filetypes = {"cs"},
            root_dir = function (startpath)
                return lsp.util.root_pattern("*.sln")(startpath)
                    or lsp.util.root_pattern("*.csproj")(startpath)
                    or lsp.util.root_pattern("*.fsproj")(startpath)
                    or lsp.util.root_pattern(".git")(startpath)
            end,
            init_options =
                {
                    AutomaticWorkspaceInit = true
                }
        })
    end
}
