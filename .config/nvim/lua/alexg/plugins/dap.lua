local function dap_menu()
    local dap = require "dap"
    local dapui = require "dapui"
    local dap_widgets = require "dap.ui.widgets"

    local hint = [[
 _t_: Toggle Breakpoint             _R_: Run to Cursor
 _s_: Start                         _E_: Evaluate Input
 _c_: Continue                      _C_: Conditional Breakpoint
 _b_: Step Back                     _U_: Toggle UI
 _d_: Disconnect                    _S_: Scopes
 _e_: Evaluate                      _X_: Close
 _g_: Get Session                   _O_: Step Into
 _y_: Hover Variables               _o_: Step Over
 _r_: Toggle REPL                   _u_: Step Out
 _x_: Terminate                     _p_: Pause
 ^ ^               _q_: Quit
]]

    return {
        name = "Debug",
        hint = hint,
        config = {
            color = "pink",
            invoke_on_body = true,
            hint = {
                border = "rounded",
                position = "middle-right",
            },
        },
        mode = "n",
        body = "<A-d>",
        -- stylua: ignore
        heads = {
            { "C", function() dap.set_breakpoint(vim.fn.input "[Condition] > ") end, desc = "Conditional Breakpoint", },
            { "E", function() dapui.eval(vim.fn.input "[Expression] > ") end,        desc = "Evaluate Input", },
            { "R", function() dap.run_to_cursor() end,                               desc = "Run to Cursor", },
            { "S", function() dap_widgets.scopes() end,                              desc = "Scopes", },
            { "U", function() dapui.toggle() end,                                    desc = "Toggle UI", },
            { "X", function() dap.close() end,                                       desc = "Quit", },
            { "b", function() dap.step_back() end,                                   desc = "Step Back", },
            { "c", function() dap.continue() end,                                    desc = "Continue", },
            { "d", function() dap.disconnect() end,                                  desc = "Disconnect", },
            {
                "e",
                function() dapui.eval() end,
                mode = { "n", "v" },
                desc =
                "Evaluate",
            },
            { "g", function() dap.session() end,           desc = "Get Session", },
            { "y", function() dap_widgets.hover() end,     desc = "Hover Variables", },
            { "O", function() dap.step_into() end,         desc = "Step Into", },
            { "o", function() dap.step_over() end,         desc = "Step Over", },
            { "p", function() dap.pause.toggle() end,      desc = "Pause", },
            { "r", function() dap.repl.toggle() end,       desc = "Toggle REPL", },
            { "s", function() dap.continue() end,          desc = "Start", },
            { "t", function() dap.toggle_breakpoint() end, desc = "Toggle Breakpoint", },
            { "u", function() dap.step_out() end,          desc = "Step Out", },
            { "x", function() dap.terminate() end,         desc = "Terminate", },
            { "q", nil, {
                exit = true,
                nowait = true,
                desc = "Exit"
            } },
        },
    }
end

local M = {
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            { "rcarriga/nvim-dap-ui" },
            { "theHamsta/nvim-dap-virtual-text" },
            { "nvim-telescope/telescope-dap.nvim" },
            { "jay-babu/mason-nvim-dap.nvim" },
            { "LiadOz/nvim-dap-repl-highlights",  opts = {} },
        },
        -- stylua: ignore
        keys = {
        },
        opts = {
            setup = {
                netcoredbg = function(_, _)
                    local dap = require "dap"

                    local function get_dotnet_debugger()
                        local mason_registry = require "mason-registry"
                        local debugger = mason_registry.get_package "netcoredbg"
                        return debugger:get_install_path() .. "/netcoredbg"
                    end

                    dap.configurations.cs = {
                        {
                            type = "coreclr",
                            name = "launch - netcoredbg",
                            request = "launch",
                            program = function()
                                return vim.fn.input("Path to dll", vim.fn.getcwd() .. "/bin/Debug/", "file")
                            end,
                        },
                    }
                    dap.adapters.coreclr = {
                        type = "executable",
                        command = get_dotnet_debugger(),
                        args = { "--interpreter=vscode" },
                    }
                    dap.adapters.netcoredbg = {
                        type = "executable",
                        command = get_dotnet_debugger(),
                        args = { "--interpreter=vscode" },
                    }
                end,
            },
        },
        config = function(plugin, opts)
            local icons = require "alexg.config.icons"
            vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

            for name, sign in pairs(icons.dap) do
                sign = type(sign) == "table" and sign or { sign }
                vim.fn.sign_define("Dap" .. name,
                    { text = sign[1], texthl = sign[2] or "DiagnosticInfo", linehl = sign[3], numhl = sign[3] })
            end

            require("nvim-dap-virtual-text").setup {
                commented = true,
            }

            local dap, dapui = require "dap", require "dapui"
            dapui.setup {}

            dap.listeners.after.event_initialized["dapui_config"] = function()
                dapui.open()
            end
            dap.listeners.before.event_terminated["dapui_config"] = function()
                dapui.close()
            end
            dap.listeners.before.event_exited["dapui_config"] = function()
                dapui.close()
            end

            -- set up debugger
            -- for k, _ in pairs(opts.setup) do
            -- opts.setup[k](plugin, opts)
            -- end
        end,
    },
    {
        "anuvyklack/hydra.nvim",
        event = "VeryLazy",
        config = function(_, _)
            local Hydra = require "hydra"
            Hydra(dap_menu())
        end,
    },
    --TODO: to configure
    {
        "jay-babu/mason-nvim-dap.nvim",
        dependencies = "mason.nvim",
        cmd = { "DapInstall", "DapUninstall" },
        opts = {
            automatic_setup = true,
            handlers = {},
            ensure_installed = {},
        },
    },
    {
        "ldelossa/nvim-dap-projects",
        event = "VeryLazy",
        config = function (_,_)
            require("nvim-dap-projects").search_project_config()
        end
    },
}

return M
