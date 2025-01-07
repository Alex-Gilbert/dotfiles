local M = {}

local opts = { noremap = true, silent = true, nowait = true, remap = false }
local term_opts = { noremap = false, remap = true, silent = true, nowait = true }

-- Function to merge tables
local function merge_tables(base, overrides)
	local result = vim.tbl_extend("force", base, overrides or {})
	return result
end

-- Wrapper function for key mappings
local function keymap(mode, lhs, rhs, desc, extra_opts)
	-- Merge base opts with extra_opts
	local options = merge_tables(opts, extra_opts)
	if desc then
		options.desc = desc
	end
	vim.keymap.set(mode, lhs, rhs, options)
end

M.init = function()
	-- Remap space as leader key
	keymap("", "<Space>", "<Nop>", nil, opts)
	vim.g.mapleader = " "
	vim.g.maplocalleader = " "

	-- Better pasting
	keymap("v", "<C-p>", '"_dP')

	-- Normal --
	-- Better window navigation
	keymap("n", "<C-h>", "<C-w>h") -- left window
	keymap("n", "<C-k>", "<C-w>k") -- up window
	keymap("n", "<C-j>", "<C-w>j") -- down window
	keymap("n", "<C-l>", "<C-w>l") -- right window

	-- Page Scrolling
	keymap("n", "<C-d>", "<C-d>zz") -- right window
	keymap("n", "<C-u>", "<C-u>zz") -- right window

	-- Better search
	keymap("n", "n", "nzzzv")
	keymap("n", "N", "Nzzzv")

	-- Resize with arrows when using multiple windows
	-- keymap("n", "<C-Up>", ":resize -2<CR>")
	-- keymap("n", "<C-down>", ":resize +2<cr>")
	-- keymap("n", "<C-right>", ":vertical resize -2<cr>")
	-- keymap("n", "<C-left>", ":vertical resize +2<cr>")

	--Better terminal navigation
	keymap("t", "<C-X>", "<C-\\><C-N>", nil, term_opts)
	keymap("t", "<C-h>", "<C-\\><C-N><C-w>h", nil, term_opts)
	keymap("t", "<C-j>", "<C-\\><C-N><C-w>j", nil, term_opts)
	keymap("t", "<C-k>", "<C-\\><C-N><C-w>k", nil, term_opts)
	keymap("t", "<C-l>", "<C-\\><C-N><C-w>l", nil, term_opts)

	keymap("n", "<leader>w", "<cmd>w!<CR>", "Save", { nowait = true, remap = false })
	keymap("n", "<leader>W", "<cmd>wall!<CR>", "Save All", { nowait = true, remap = false })
end

M.whichkey_spec = {
	{
		"<leader>q",
		vim.diagnostic.setloclist,
		desc = "Open diagnostics [Q]uickfix list",
		nowait = true,
		remap = false,
	},

	{ "<leader>c", group = "[C]ode", nowait = true, remap = false },

	{ "<leader>n", group = "Split", nowait = true, remap = false },
	{
		"<leader>ns",
		"<cmd>clo<CR>",
		desc = "Close Split",
		nowait = true,
		remap = false,
	},

	{ "<leader>p", group = "Project", nowait = true, remap = false },
	{ "<leader>ps", group = "Project Search", nowait = true, remap = false },

	{ "<leader>s", group = "Surround", nowait = true, remap = false },
}

M.set_copilot_keys = function()
	vim.g.copilot_no_tab_map = true
	vim.keymap.set(
		"i",
		"<C-L>",
		"copilot#Accept('<CR>')",
		{ noremap = true, silent = true, expr = true, replace_keycodes = false }
	)
	vim.keymap.set("i", "<C-S>", "<Plug>(copilot-accept-word)")
end

M.set_telescope_keys = function()
	-- See `:help telescope.builtin`
	local builtin = require("telescope.builtin")

	keymap("n", "<leader>pf", builtin.find_files, "[P]roject [F]iles")
	keymap("n", "<leader>pss", builtin.live_grep, "[P]roject [S]earch Grep")
	keymap("n", "<leader>psh", builtin.help_tags, "[P]roject [S]earch [H]elp")
	keymap("n", "<leader>psk", builtin.keymaps, "[P]roject [S]earch [K]eymaps")
	keymap("n", "<leader>psw", builtin.grep_string, "[P]roject [S]earch current [W]ord")
	keymap("n", "<leader>pst", builtin.builtin, "[P]roject [S]earch by [G]rep")
	keymap("n", "<leader>psd", builtin.diagnostics, "[P]roject [S]earch [D]iagnostics")
	keymap("n", "<leader>psr", builtin.resume, "[P]roject [S]earch [R]esume")

	-- Search hidden files with live grep
	keymap("n", "<leader>ps.", function()
		builtin.live_grep({
			additional_args = function(_opts)
				return { "--hidden" }
			end,
		})
	end, "[P]roject [S]earch hidden files with live grep")

	-- Slightly advanced example of overriding default behavior and theme
	vim.keymap.set("n", "<leader>/", function()
		-- You can pass additional configuration to Telescope to change the theme, layout, etc.
		builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
			winblend = 10,
			previewer = false,
		}))
	end, { desc = "[/] Fuzzily search in current buffer" })
end

M.set_lsp_keys = function(event, client)
	local lsp_opts = { buffer = event.buf }

	local telescope = require("telescope.builtin")
	local lsp = vim.lsp

	keymap("n", "gd", telescope.lsp_definitions, "[G]oto [D]efinition", lsp_opts)
	keymap("n", "gD", lsp.buf.declaration, "[G]oto [D]eclaration", lsp_opts)
	keymap("n", "gr", telescope.lsp_references, "[G]oto [R]eferences", lsp_opts)
	keymap("n", "gI", telescope.lsp_implementations, "[G]oto [I]mplementations", lsp_opts)
	keymap("n", "<leader>ct", telescope.lsp_type_definitions, "[C]ode Goto [T]ype Definition")
	keymap("n", "<leader>cs", telescope.lsp_document_symbols, "[C]ode Document [S]ymbols")
	keymap("n", "<leader>cS", telescope.lsp_dynamic_workspace_symbols, "[C]ode Workspace [S]ymbols")
	keymap("n", "<leader>cr", vim.lsp.buf.rename, "[C]ode [R]ename")
	keymap({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
	keymap("n", "K", lsp.buf.hover, "Hover")

	-- The following code creates a keymap to toggle inlay hints in your
	-- code, if the language server you are using supports them
	--
	-- This may be unwanted, since they displace some of your code
	if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
		keymap("n", "<leader>th", function()
			vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
		end, "[T]oggle Inlay [H]ints")
	end
end

M.conform_keys = {
	{
		"<leader>cf",
		function()
			require("conform").format({ async = true, lsp_format = "fallback" })
		end,
		mode = "",
		desc = "[C]ode [F]ormat buffer",
	},
}

M.cmp_keys = function(cmp, luasnip)
	return {
		-- Select the [n]ext item
		["<C-n>"] = cmp.mapping.select_next_item(),
		-- Select the [p]revious item
		["<C-p>"] = cmp.mapping.select_prev_item(),

		-- Scroll the documentation window [b]ack / [f]orward
		["<C-b>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),

		-- Accept ([y]es) the completion.
		--  This will auto-import if your LSP supports it.
		--  This will expand snippets if the LSP sent a snippet.
		["<C-y>"] = cmp.mapping.confirm({ select = true }),

		-- Manually trigger a completion from nvim-cmp.
		["<C-Space>"] = cmp.mapping.complete({}),

		-- <c-l> will move you to the right of each of the expansion locations.
		-- <c-h> is similar, except moving you backwards.
		["<C-left>"] = cmp.mapping(function()
			if luasnip.expand_or_locally_jumpable() then
				luasnip.expand_or_jump()
			end
		end, { "i", "s" }),
		["<C-right>"] = cmp.mapping(function()
			if luasnip.locally_jumpable(-1) then
				luasnip.jump(-1)
			end
		end, { "i", "s" }),
	}
end

M.surround_keys = {
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
}

M.oil_keys = {
	["g?"] = { "actions.show_help", mode = "n" },
	["<CR>"] = "actions.select",
	["<C-s>"] = { "actions.select", opts = { vertical = true } },
	["<C-h>"] = { "actions.select", opts = { horizontal = true } },
	["<C-t>"] = { "actions.select", opts = { tab = true } },
	["<C-p>"] = "actions.preview",
	["<C-c>"] = { "actions.close", mode = "n" },
	["<C-b>"] = "actions.refresh",
	["-"] = { "actions.parent", mode = "n" },
	["_"] = { "actions.open_cwd", mode = "n" },
	["`"] = { "actions.cd", mode = "n" },
	["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
	["gs"] = { "actions.change_sort", mode = "n" },
	["gx"] = "actions.open_external",
	["g."] = { "actions.toggle_hidden", mode = "n" },
	["g\\"] = { "actions.toggle_trash", mode = "n" },
}

M.set_oil_keys = function()
	keymap("n", "<leader>pv", "<cmd>Oil<CR>", "[P]roject [V]iew", { nowait = true, remap = false })

	keymap(
		"n",
		"<leader>nh",
		"<cmd>vertical leftabove split<CR><cmd>Oil<CR>",
		"Split Left",
		{ nowait = true, remap = false }
	)
	keymap(
		"n",
		"<leader>nj",
		"<cmd>horizontal belowright split<CR><cmd>Oil<CR>",
		"Split Down",
		{ nowait = true, remap = false }
	)
	keymap(
		"n",
		"<leader>nk",
		"<cmd>horizontal leftabove split<CR><cmd>Oil<CR>",
		"Split Up",
		{ nowait = true, remap = false }
	)
	keymap(
		"n",
		"<leader>nl",
		"<cmd>vertical belowright split<CR><cmd>Oil<CR>",
		"Split Right",
		{ nowait = true, remap = false }
	)
end

M.set_harpoon_keys = function(harpoon)
	keymap("n", "<leader>a", function()
		harpoon:list():add()
	end, "[A]dd file to Harpoon")
	keymap("n", "<leader>e", function()
		harpoon.ui:toggle_quick_menu(harpoon:list())
	end, "[E]xplore Harpoon")

	keymap("n", "<C-1>", function()
		harpoon:list():select(1)
	end, "[H]arpoon [1]")
	keymap("n", "<C-2>", function()
		harpoon:list():select(2)
	end, "[H]arpoon [2]")
	keymap("n", "<C-3>", function()
		harpoon:list():select(3)
	end, "[H]arpoon [3]")
	keymap("n", "<C-4>", function()
		harpoon:list():select(4)
	end, "[H]arpoon [4]")

	keymap("n", "<C-S-H>", function()
		harpoon:list():prev()
	end, "[H]arpoon [P]revious")
	keymap("n", "<C-S-L>", function()
		harpoon:list():next()
	end, "[H]arpoon [N]ext")
end

M.mini_move_keys = {
	left = "<left>",
	right = "<right>",
	down = "<down>",
	up = "<up>",

	line_left = "<left>",
	line_right = "<right>",
	line_down = "<down>",
	line_up = "<up>",
}

M.flash_keys = {
	{
		"s",
		mode = { "n", "x", "o" },
		function()
			require("flash").jump()
		end,
		desc = "Flash",
	},
	{
		"S",
		mode = { "n", "x", "o" },
		function()
			require("flash").treesitter()
		end,
		desc = "Flash Treesitter",
	},
	{
		"r",
		mode = "o",
		function()
			require("flash").remote()
		end,
		desc = "Remote Flash",
	},
	{
		"R",
		mode = { "o", "x" },
		function()
			require("flash").treesitter_search()
		end,
		desc = "Treesitter Search",
	},
	{
		"<c-s>",
		mode = { "c" },
		function()
			require("flash").toggle()
		end,
		desc = "Toggle Flash Search",
	},
}

return M
