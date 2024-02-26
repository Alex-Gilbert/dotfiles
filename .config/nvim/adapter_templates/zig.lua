local dap = require("dap")

local function get_debugger()
    local os = require "os"
    local debugger = os.getenv("HOME") .. '/.local/share/cpptools/debugAdapters/bin/OpenDebugAD7'
    print(debugger)
    return debugger
end

dap.adapters.cppdbg = {
    id = 'cppdbg',
    type = "executable",
    command = get_debugger(), -- adjust as needed
}

dap.configurations.zig = {
    {
        name = "hello-world",
        type = "cppdbg",
        request = "launch",
        program = function()
            return vim.fn.getcwd() .. "/zig-out/bin/NewtonRaphsonCS_OpenCl"
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
    },
}
