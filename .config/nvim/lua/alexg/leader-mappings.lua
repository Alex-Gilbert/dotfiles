local open_terminal = require("alexg.my_scripts.open_terminal")

local mappings = {

    ["a"] = { "<cmd>lua require('harpoon.mark').add_file()<CR>", "Mark File" },                -- Close current file
    ["e"] = { "<cmd>lua require('harpoon.ui').toggle_quick_menu()<CR>", "Open Harpoon Menu" }, -- Close current file
    ["l"] = { "<cmd>Lazy<CR>", "Lazy Plugin Manager" },                                        -- Invoking plugin manager
    ["q"] = { "<cmd>wqall!<CR>", "Quit" },                                                     -- Quit Neovim after saving the file
    ["w"] = { "<cmd>w!<CR>", "Save" },                                                         -- Save current file
    ["W"] = { "<cmd>wall!<CR>", "Save" },                                                      -- Save current file
    ["r"] = { "<cmd>%s/\\<<C-r><C-w>\\>//g<left><left><CR>", "Change Instances of Word" },

    p = {
        name = "Project",
        v = { "<cmd>Oil<cr>", "Explore" },
        f = { "<cmd>lua require('telescope.builtin').find_files()<cr>", "Find Files" },
        r = { "<cmd>lua require('telescope.builtin').registers()<cr>", "Find Files" },
        s = { "<cmd>Telescope live_grep<cr>", "Search in Files" },
    },

    c = {
        name = "Code",
        p = { "<cmd>Telescope luasnip<cr>", "Search Snippets" },
        a = { "<cmd>lua vim.lsp.buf.code_action()<cr>", "Code Action" },
        h = { "<cmd>lua vim.lsp.buf.hover()<cr>", "Doc Hover" },
        d = { "<cmd>lua vim.diagnostic.open_float()<cr>", "Open Float Diagnostic" },
        f = { "<cmd>lua vim.lsp.buf.format({async=true})<cr>", "Format Code" },
        i = { "<cmd>LspInfo<cr>", "Info" },
        l = { "<cmd>lua vim.lsp.codelens.run()<cr>", "CodeLens Action" },
        r = { "<cmd>lua vim.lsp.buf.rename()<cr>", "Rename" },
        s = { "<cmd>Telescope lsp_document_symbols<cr>", "Document Symbols" },
        S = {
            "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>",
            "Workspace Symbols",
        },
        g = {
            name = "ChatGPT",
            c = { "<cmd>ChatGPT<CR>", "ChatGPT" },
            e = { "<cmd>ChatGPTEditWithInstruction<CR>", "Edit with instruction", mode = { "n", "v" } },
            p = { "<cmd>ChatGPTRun complete_code<CR>", "Complete Code", mode = { "n", "v" } },
            g = { "<cmd>ChatGPTRun grammar_correction<CR>", "Grammar Correction", mode = { "n", "v" } },
            t = { "<cmd>ChatGPTRun translate<CR>", "Translate", mode = { "n", "v" } },
            k = { "<cmd>ChatGPTRun keywords<CR>", "Keywords", mode = { "n", "v" } },
            d = { "<cmd>ChatGPTRun docstring<CR>", "Docstring", mode = { "n", "v" } },
            a = { "<cmd>ChatGPTRun add_tests<CR>", "Add Tests", mode = { "n", "v" } },
            o = { "<cmd>ChatGPTRun optimize_code<CR>", "Optimize Code", mode = { "n", "v" } },
            s = { "<cmd>ChatGPTRun summarize<CR>", "Summarize", mode = { "n", "v" } },
            f = { "<cmd>ChatGPTRun fix_bugs<CR>", "Fix Bugs", mode = { "n", "v" } },
            x = { "<cmd>ChatGPTRun explain_code<CR>", "Explain Code", mode = { "n", "v" } },
            r = { "<cmd>ChatGPTRun roxygen_edit<CR>", "Roxygen Edit", mode = { "n", "v" } },
            l = { "<cmd>ChatGPTRun code_readability_analysis<CR>", "Code Readability Analysis", mode = { "n", "v" } },
        },
    },

    t = {
        name = "Tree Explorer",
        t = { "<cmd>Neotree float<cr>", "Toggle Tree" },
        h = { "<cmd>Neotree close float<cr>", "Hide Tree" },
        d = { "<cmd>Neotree float reveal_force_cwd<cr>", "Find File in Tree" },
    },

    g = {
        name = "Git",
        g = { "<cmd>Git<CR>", "Git" },
    },

    n = {
        name = "Split",
        h = { "<cmd>vertical leftabove split<CR><cmd>Oil<CR>", "Split Left" },
        j = { "<cmd>horizontal belowright split<CR><cmd>Oil<CR>", "Split Down" },
        k = { "<cmd>horizontal leftabove split<CR><cmd>Oil<CR>", "Split Up" },
        l = { "<cmd>vertical belowright split<CR><cmd>Oil<CR>", "Split Right" },
        s = { "<cmd>clo<CR>", "Close Split" },
        H = { function() open_terminal.in_current_dir("left") end, "Open Terminal Left" },
        J = { function() open_terminal.in_current_dir("right") end, "Open Terminal Right" },
        K = { function() open_terminal.in_current_dir("up") end, "Open Terminal Up" },
        L = { function() open_terminal.in_current_dir("down") end, "Open Terminal Down" },
    },

    s = {
        name = "Surround",
    },

    x = {
        name = "trouble",
        x = { "<cmd>TroubleToggle<cr>", "Toggle Trouble" },
        w = { "<cmd>TroubleToggle workspace_diagnostics<cr>", "Workspace Diagnostics" },
        d = { "<cmd>TroubleToggle document_diagnostics<cr>", "Document Diagnostics" },
        q = { "<cmd>TroubleToggle quickfix<cr>", "Quick Fix" },
        l = { "<cmd>TroubleToggle loclist<cr>", "Loc List" },
        r = { "cmd>TroubleToggle lsp_references<cr>", "LSP References" },
    },

    o = {
        name = "Obsidian",
        n = { "<cmd>ObsidianNew<cr>", "New Note" },
        o = { "<cmd>ObsidianSearch<cr>", "Search or Create Note" },
        t = { "<cmd>ObsidianTemplate<cr>", "Insert Template" },
        b = { "<cmd>ObsidianBacklinks<cr>", "Backlinks" },
        r = { "<cmd>ObsidianRename<cr>", "Rename" },
        s = { "<cmd>ObsidianQuickSwitch<cr>", "Quick Switch" },
        l = { "<cmd>ObsidianLink<cr>", "Link" },
    }
}
return mappings
