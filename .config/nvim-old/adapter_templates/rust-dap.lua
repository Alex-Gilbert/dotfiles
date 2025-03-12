local dap = require("dap")

local function get_debugger()
    local debugger = vim.fn.stdpath("data") .. '/mason/bin/codelldb'
    print(debugger)
    return debugger
end

dap.adapters.codelldb = {
    id = 'codelldb',
    type = 'server',
    port = "${port}",
    executable = {
        -- Change this to your path!
        command = get_debugger(),
        args = { "--port", "${port}" },
    }
}

dap.configurations.rust = {
    {
        name = "guessing_game",
        type = "codelldb",
        request = "launch",
        program = function()
            return vim.fn.getcwd() .. "/target/debug/guessing_game"
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
    },
}
