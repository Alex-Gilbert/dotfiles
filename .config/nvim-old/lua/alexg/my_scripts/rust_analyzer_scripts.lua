-- Function to change the Rust Analyzer target
function ChangeRustAnalyzerTarget(new_target)
    -- Ensure the lspconfig plugin is loaded
    local lspconfig = require('lspconfig')

    -- Define the new settings with the specified target
    local new_settings = {
        ["rust-analyzer"] = {
            cargo = {
                target = new_target,
            },
        },
    }

    -- Apply the new settings
    lspconfig.rust_analyzer.setup({
        settings = new_settings
    })

    -- Restart Rust Analyzer to apply the changes
    -- First, we need to stop the current instance
    vim.lsp.stop_client(vim.lsp.get_active_clients({name = "rust_analyzer"}))
    -- Then, wait a bit for it to shut down properly (adjust delay as needed)
    vim.defer_fn(function()
        -- Start a new instance with the updated settings
        lspconfig.rust_analyzer.launch()
    end, 500) -- Delay in milliseconds
end
