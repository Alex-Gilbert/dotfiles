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

	-- Page Scrolling
	keymap("n", "<C-d>", "<C-d>zz") -- right window
	keymap("n", "<C-u>", "<C-u>zz") -- right window

	-- Better search
	keymap("n", "n", "nzzzv")
	keymap("n", "N", "Nzzzv")

	-- Resize with arrows when using multiple windows
	keymap("n", "<C-Up>", ":resize -2<CR>")
	keymap("n", "<C-down>", ":resize +2<cr>")
	keymap("n", "<C-right>", ":vertical resize -2<cr>")
	keymap("n", "<C-left>", ":vertical resize +2<cr>")

	--Better terminal navigation
	keymap("t", "<C-X>", "<C-\\><C-N>", nil, term_opts)
	keymap("t", "<C-h>", "<C-\\><C-N><C-w>h", nil, term_opts)
	keymap("t", "<C-j>", "<C-\\><C-N><C-w>j", nil, term_opts)
	keymap("t", "<C-k>", "<C-\\><C-N><C-w>k", nil, term_opts)
	keymap("t", "<C-l>", "<C-\\><C-N><C-w>l", nil, term_opts)

	keymap("n", "<leader>w", "<cmd>w!<CR>", "Save", { nowait = true, remap = false })
	keymap("n", "<leader>W", "<cmd>wall!<CR>", "Save All", { nowait = true, remap = false })

	-- Macro execution with visible indicator (instant, but shows what register)
	keymap("n", "@", function()
		-- Show brief indicator
		vim.notify("@", vim.log.levels.INFO, { title = "Macro", timeout = 500 })
		-- Get register and execute immediately
		local reg = vim.fn.getcharstr()
		if reg then
			local count = vim.v.count1
			vim.cmd("normal! " .. count .. "@" .. reg)
		end
	end, "Execute macro")
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
	{ "<leader>o", group = "Obsidian", nowait = true, remap = false },
	{ "<leader>i", group = "Intelligence (AI)", nowait = true, remap = false },
	{ "<leader>g", group = "[G]it", nowait = true, remap = false },
	{ "<leader>gd", group = "[G]it [D]iff", nowait = true, remap = false },
	{ "<leader>x", group = "Swap", nowait = true, remap = false },
	{ "<leader>m", group = "[M]essages (Noice)", nowait = true, remap = false },
	{ "gs", group = "Surround", nowait = true, remap = false },
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
	require("telescope").load_extension("project_navigator")
	local builtin = require("telescope.builtin")

	keymap("n", "<leader>pf", builtin.find_files, "[P]roject [F]iles")
	keymap("n", "<leader>pss", builtin.live_grep, "[P]roject [S]earch Grep")
	keymap("n", "<leader>psh", builtin.help_tags, "[P]roject [S]earch [H]elp")
	keymap("n", "<leader>psk", builtin.keymaps, "[P]roject [S]earch [K]eymaps")
	keymap("n", "<leader>psw", builtin.grep_string, "[P]roject [S]earch current [W]ord")
	keymap("n", "<leader>pst", builtin.builtin, "[P]roject [S]earch by [G]rep")
	keymap("n", "<leader>psd", builtin.diagnostics, "[P]roject [S]earch [D]iagnostics")
	keymap("n", "<leader>psr", builtin.resume, "[P]roject [S]earch [R]esume")

	keymap("n", "<leader>psy", function()
		vim.cmd.Telescope({ "yank_history" })
	end, "[P]roject [S]earch [Y]ank")

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

	-- Telescope project finder
	-- Key mappings
	keymap("n", "<leader>fp", function()
		require("telescope").extensions.project_navigator.projects({
			include_worktrees = false,
		})
	end, "Find Projects")

	keymap("n", "<leader>fP", function()
		require("telescope").extensions.project_navigator.projects({
			include_worktrees = true,
		})
	end, "Find Projects & Worktrees")

	keymap("n", "<leader>fw", function()
		require("telescope").extensions.project_navigator.worktrees()
	end, "Find Current Project Worktrees")
end

-- Base LSP keymaps that apply to all language servers
local function set_base_lsp_keys(bufnr, client, overrides)
	overrides = overrides or {}
	local lsp_opts = { buffer = bufnr }
	local telescope = require("telescope.builtin")
	local lsp = vim.lsp

	-- Navigation keymaps (with overrides support)
	keymap("n", "gd", overrides.goto_definition or telescope.lsp_definitions, "[G]oto [D]efinition", lsp_opts)
	keymap("n", "gD", overrides.goto_declaration or lsp.buf.declaration, "[G]oto [D]eclaration", lsp_opts)
	keymap("n", "gr", overrides.goto_references or telescope.lsp_references, "[G]oto [R]eferences", lsp_opts)
	keymap(
		"n",
		"gI",
		overrides.goto_implementation or telescope.lsp_implementations,
		"[G]oto [I]mplementations",
		lsp_opts
	)
	keymap(
		"n",
		"<leader>ct",
		overrides.type_definition or telescope.lsp_type_definitions,
		"[C]ode Goto [T]ype Definition",
		lsp_opts
	)

	-- Document/workspace symbols
	-- NOTE: <leader>cs is now handled by aerial.nvim (Telescope aerial)
	keymap("n", "<leader>cS", telescope.lsp_dynamic_workspace_symbols, "[C]ode Workspace [S]ymbols", lsp_opts)

	-- Actions (with overrides support)
	keymap("n", "<leader>cr", overrides.rename or lsp.buf.rename, "[C]ode [R]ename", lsp_opts)
	keymap({ "n", "x" }, "<leader>ca", overrides.code_action or lsp.buf.code_action, "[C]ode [A]ction", lsp_opts)
	keymap("n", "K", overrides.hover or lsp.buf.hover, "Hover", lsp_opts)

	-- Inlay hints toggle
	if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
		keymap("n", "<leader>th", function()
			vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }))
		end, "[T]oggle Inlay [H]ints", lsp_opts)
	end

	-- Apply any additional keymaps from overrides
	if overrides.additional_keymaps then
		for _, keymap_config in ipairs(overrides.additional_keymaps) do
			keymap(unpack(keymap_config))
		end
	end
end

-- Standard LSP keymaps for non-Rust languages
M.set_lsp_keys = function(event, client)
	set_base_lsp_keys(event.buf, client)
end

-- Rust-specific LSP keymaps with rustaceanvim enhancements
M.set_rust_lsp_keys = function(bufnr, client)
	local lsp_opts = { buffer = bufnr }

	-- Rust-specific overrides
	local rust_overrides = {
		code_action = function()
			vim.cmd.RustLsp("codeAction")
		end,
		hover = function()
			vim.cmd.RustLsp({ "hover", "actions" })
		end,
		additional_keymaps = {
			-- Rust-specific keymaps
			{
				"n",
				"<leader>ce",
				function()
					vim.cmd.RustLsp({ "explainError", "current" })
				end,
				"[C]ode [E]xplain Error",
				lsp_opts,
			},

			{
				"n",
				"<leader>cd",
				function()
					vim.cmd.RustLsp({ "renderDiagnostic", "current" })
				end,
				"[C]ode [D]iagnostics",
				lsp_opts,
			},

			{
				"n",
				"gR",
				function()
					vim.cmd.RustLsp("relatedDiagnostics")
				end,
				"[G]oto [R]elated Diagnostic",
				lsp_opts,
			},
		},
	}

	set_base_lsp_keys(bufnr, client, rust_overrides)
	print("Setting up Rust LSP keys")
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

-- NOTE: cmp_keys removed - blink.cmp handles its own keymaps in lsp_plugins.lua
-- NOTE: surround_keys removed - mini.surround handles its own keymaps (gz prefix)

M.oil_keys = {
	["g?"] = { "actions.show_help", mode = "n" },
	["<CR>"] = "actions.select",
	["<C-s>"] = { "actions.select", opts = { vertical = true } },
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

M.set_grapple_keys = function()
	local grapple = require("grapple")

	keymap("n", "<leader>a", function()
		grapple.toggle()
	end, "[A]dd/Remove file tag (Grapple)")
	keymap("n", "<leader>e", function()
		grapple.toggle_tags()
	end, "[E]xplore Grapple tags")

	keymap("n", "<C-1>", function()
		grapple.select({ index = 1 })
	end, "[G]rapple [1]")
	keymap("n", "<C-2>", function()
		grapple.select({ index = 2 })
	end, "[G]rapple [2]")
	keymap("n", "<C-3>", function()
		grapple.select({ index = 3 })
	end, "[G]rapple [3]")
	keymap("n", "<C-4>", function()
		grapple.select({ index = 4 })
	end, "[G]rapple [4]")
	keymap("n", "<C-5>", function()
		grapple.select({ index = 5 })
	end, "[G]rapple [5]")
	keymap("n", "<C-6>", function()
		grapple.select({ index = 6 })
	end, "[G]rapple [6]")
	keymap("n", "<C-7>", function()
		grapple.select({ index = 7 })
	end, "[G]rapple [7]")
	keymap("n", "<C-8>", function()
		grapple.select({ index = 8 })
	end, "[G]rapple [8]")
	keymap("n", "<C-9>", function()
		grapple.select({ index = 9 })
	end, "[G]rapple [9]")

	keymap("n", "<C-S-H>", function()
		grapple.cycle_tags("prev")
	end, "[G]rapple [P]revious")
	keymap("n", "<C-S-L>", function()
		grapple.cycle_tags("next")
	end, "[G]rapple [N]ext")
end

M.set_opencode_keys = function()
	local opencode = require("opencode")

	-- Core actions
	keymap({ "n", "x" }, "<leader>ia", function()
		opencode.ask()
	end, "[I]ntelligence [A]sk")
	keymap({ "n", "x" }, "<leader>is", function()
		opencode.select()
	end, "[I]ntelligence [S]elect action")
	keymap({ "n", "t" }, "<leader>it", function()
		opencode.toggle()
	end, "[I]ntelligence [T]oggle")

	-- Quick prompts with context
	keymap({ "n", "x" }, "<leader>ie", function()
		opencode.ask("@this: explain", { submit = true })
	end, "[I]ntelligence [E]xplain")
	keymap({ "n", "x" }, "<leader>ir", function()
		opencode.ask("@this: review for correctness and readability", { submit = true })
	end, "[I]ntelligence [R]eview")
	keymap({ "n", "x" }, "<leader>ii", function()
		opencode.ask("@this: implement", { submit = true })
	end, "[I]ntelligence [I]mplement")
	keymap({ "n", "x" }, "<leader>io", function()
		opencode.ask("@this: optimize for performance and readability", { submit = true })
	end, "[I]ntelligence [O]ptimize")
	keymap({ "n", "x" }, "<leader>id", function()
		opencode.ask("@this: add documentation comments", { submit = true })
	end, "[I]ntelligence [D]ocument")

	-- Diagnostics
	keymap("n", "<leader>ix", function()
		opencode.ask("@diagnostics: explain these diagnostics", { submit = true })
	end, "[I]ntelligence Diagnostics E[x]plain")
	keymap("n", "<leader>if", function()
		opencode.ask("@diagnostics: fix these issues", { submit = true })
	end, "[I]ntelligence [F]ix diagnostics")

	-- Git
	keymap("n", "<leader>ig", function()
		opencode.ask("@diff: review this git diff for correctness and readability", { submit = true })
	end, "[I]ntelligence [G]it diff review")

	-- Grapple integration (tagged files context)
	keymap("n", "<leader>ij", function()
		opencode.ask("@grapple: ", { submit = false })
	end, "[I]ntelligence Grapple conte[x]t")

	-- Operator for ranges (vim-style)
	keymap({ "n", "x" }, "go", function()
		return opencode.operator("@this ")
	end, "[G]o [O]pencode (operator)", { expr = true })
	keymap("n", "goo", function()
		return opencode.operator("@this ") .. "_"
	end, "[G]o [O]pencode line", { expr = true })

	-- Session navigation
	keymap("n", "<S-C-u>", function()
		opencode.command("session.half.page.up")
	end, "opencode: scroll up")
	keymap("n", "<S-C-d>", function()
		opencode.command("session.half.page.down")
	end, "opencode: scroll down")
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

M.set_yank_keys = function()
	keymap({ "n", "x" }, "p", "<Plug>(YankyPutAfter)")
	keymap({ "n", "x" }, "P", "<Plug>(YankyPutBefore)")
	keymap({ "n", "x" }, "gp", "<Plug>(YankyGPutAfter)")
	keymap({ "n", "x" }, "gP", "<Plug>(YankyGPutBefore)")

	keymap("n", "<c-p>", "<Plug>(YankyPreviousEntry)")
	keymap("n", "<c-n>", "<Plug>(YankyNextEntry)")
end

M.obsidian_keys = {
	{ "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "[O]bsidian [B]acklinks" },
	{ "<leader>ol", "<cmd>Obsidian link<cr>", desc = "[O]bsidian [L]ink" },
	{ "<leader>on", "<cmd>Obsidian new<cr>", desc = "[O]bsidian [N]ew Note" },
	{ "<leader>oo", "<cmd>Obsidian search<cr>", desc = "[O]bsidian Search" },
	{ "<leader>or", "<cmd>Obsidian rename<cr>", desc = "[O]bsidian [R]ename" },
	{ "<leader>os", "<cmd>Obsidian quick-switch<cr>", desc = "[O]bsidian Quick [S]witch" },
	{ "<leader>op", "<cmd>Obsidian template<cr>", desc = "[O]bsidian Insert Tem[p]late" },
	{ "<leader>od", "<cmd>Obsidian today<cr>", desc = "[O]bsidian: To[d]ay" },
}

M.set_obsidian_keys = function()
	keymap("n", "gf", function()
		if require("obsidian").util.cursor_on_markdown_link() then
			return "<cmd>Obsidian follow-link<CR>"
		else
			return "gf"
		end
	end, "[G]o to [F]ile", { noremap = true, expr = true })

	keymap("n", "<leader>otx", function()
		require("obsidian").util.toggle_checkbox()
	end, "[O]bsidian [T]ask Done")
end

M.neotest_keys = {
	{
		"<leader>ta",
		function()
			require("neotest").run.attach()
		end,
		desc = "[t]est [a]ttach",
	},
	{
		"<leader>tf",
		function()
			require("neotest").run.run(vim.fn.expand("%"))
		end,
		desc = "[t]est run [f]ile",
	},
	{
		"<leader>tA",
		function()
			require("neotest").run.run(vim.uv.cwd())
		end,
		desc = "[t]est [A]ll files",
	},
	{
		"<leader>tS",
		function()
			require("neotest").run.run({ suite = true })
		end,
		desc = "[t]est [S]uite",
	},
	{
		"<leader>tn",
		function()
			require("neotest").run.run()
		end,
		desc = "[t]est [n]earest",
	},
	{
		"<leader>tl",
		function()
			require("neotest").run.run_last()
		end,
		desc = "[t]est [l]ast",
	},
	{
		"<leader>ts",
		function()
			require("neotest").summary.toggle()
		end,
		desc = "[t]est [s]ummary",
	},
	{
		"<leader>to",
		function()
			require("neotest").output.open({ enter = true, auto_close = true })
		end,
		desc = "[t]est [o]utput",
	},
	{
		"<leader>tO",
		function()
			require("neotest").output_panel.toggle()
		end,
		desc = "[t]est [O]utput panel",
	},
	{
		"<leader>tt",
		function()
			require("neotest").run.stop()
		end,
		desc = "[t]est [t]erminate",
	},
	{
		"<leader>td",
		function()
			require("neotest").run.run({ suite = false, strategy = "dap" })
		end,
		desc = "Debug nearest test",
	},
	{
		"<leader>tD",
		function()
			require("neotest").run.run({ vim.fn.expand("%"), strategy = "dap" })
		end,
		desc = "Debug current file",
	},
}

M.dap_keys = {
	{
		"<leader>db",
		function()
			require("dap").toggle_breakpoint()
		end,
		desc = "toggle [d]ebug [b]reakpoint",
	},
	{
		"<leader>dB",
		function()
			require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
		end,
		desc = "[d]ebug [B]reakpoint",
	},
	{
		"<leader>dc",
		function()
			require("dap").continue()
		end,
		desc = "[d]ebug [c]ontinue (start here)",
	},
	{
		"<leader>dC",
		function()
			require("dap").run_to_cursor()
		end,
		desc = "[d]ebug [C]ursor",
	},
	{
		"<leader>dg",
		function()
			require("dap").goto_()
		end,
		desc = "[d]ebug [g]o to line",
	},
	{
		"<leader>do",
		function()
			require("dap").step_over()
		end,
		desc = "[d]ebug step [o]ver",
	},
	{
		"<leader>dO",
		function()
			require("dap").step_out()
		end,
		desc = "[d]ebug step [O]ut",
	},
	{
		"<leader>di",
		function()
			require("dap").step_into()
		end,
		desc = "[d]ebug [i]nto",
	},
	{
		"<leader>dj",
		function()
			require("dap").down()
		end,
		desc = "[d]ebug [j]ump down",
	},
	{
		"<leader>dk",
		function()
			require("dap").up()
		end,
		desc = "[d]ebug [k]ump up",
	},
	{
		"<leader>dl",
		function()
			require("dap").run_last()
		end,
		desc = "[d]ebug [l]ast",
	},
	{
		"<leader>dp",
		function()
			require("dap").pause()
		end,
		desc = "[d]ebug [p]ause",
	},
	{
		"<leader>dr",
		function()
			require("dap").repl.toggle()
		end,
		desc = "[d]ebug [r]epl",
	},
	{
		"<leader>dR",
		function()
			require("dap").clear_breakpoints()
		end,
		desc = "[d]ebug [R]emove breakpoints",
	},
	{
		"<leader>ds",
		function()
			require("dap").session()
		end,
		desc = "[d]ebug [s]ession",
	},
	{
		"<leader>dx",
		function()
			require("dap").terminate()
		end,
		desc = "[d]ebug [t]erminate",
	},
	{
		"<leader>dw",
		function()
			require("dap.ui.widgets").hover()
		end,
		desc = "[d]ebug [w]idgets",
	},
}

M.set_crates_keys = function(bufnr)
	local crates = require("crates")
	local opts = { silent = true, buffer = bufnr }

	-- Toggle UI elements (virtual text)
	keymap("n", "<leader>ct", crates.toggle, "[C]rates [T]oggle", opts)
	keymap("n", "<leader>cr", crates.reload, "[C]rates [R]eload", opts)

	-- Popup keymaps
	keymap("n", "<leader>cv", crates.show_versions_popup, "[C]rates [V]ersions", opts)
	keymap("n", "<leader>cf", crates.show_features_popup, "[C]rates [F]eatures", opts)
	keymap("n", "<leader>cd", crates.show_dependencies_popup, "[C]rates [D]ependencies", opts)
	keymap("n", "<leader>ci", crates.show_crate_popup, "[C]rates [I]nfo", opts)

	-- Update/upgrade crates
	keymap("n", "<leader>cu", crates.update_crate, "[C]rates [U]pdate", opts)
	keymap("v", "<leader>cu", crates.update_crates, "[C]rates [U]pdate", opts)
	keymap("n", "<leader>cU", crates.upgrade_crate, "[C]rates [U]pgrade", opts)
	keymap("v", "<leader>cU", crates.upgrade_crates, "[C]rates [U]pgrade", opts)
	keymap("n", "<leader>ca", crates.update_all_crates, "[C]rates Update [A]ll", opts)
	keymap("n", "<leader>cA", crates.upgrade_all_crates, "[C]rates Upgrade [A]ll", opts)

	-- Extract and expand
	keymap("n", "<leader>cx", crates.expand_plain_crate_to_inline_table, "[C]rates E[x]pand", opts)
	keymap("n", "<leader>cX", crates.extract_crate_into_table, "[C]rates E[X]tract", opts)

	-- Open external links
	keymap("n", "<leader>ch", crates.open_homepage, "[C]rates [H]omepage", opts)
	keymap("n", "<leader>cR", crates.open_repository, "[C]rates [R]epository", opts)
	keymap("n", "<leader>cD", crates.open_documentation, "[C]rates [D]ocumentation", opts)
	keymap("n", "<leader>cC", crates.open_crates_io, "[C]rates Open [C]rates.io", opts)

	-- Override K for hover in Cargo.toml
	keymap("n", "K", function()
		if crates.popup_available() then
			crates.show_popup()
		else
			vim.lsp.buf.hover()
		end
	end, "Show Crate Info", opts)
end

-- Diffview keys (with Telescope integration for branch/commit selection)
M.diffview_keys = {
	-- Quick actions
	{ "<leader>gdd", "<cmd>DiffviewOpen<cr>", desc = "[G]it [D]iff against index" },
	{ "<leader>gdh", "<cmd>DiffviewFileHistory %<cr>", desc = "[G]it [D]iff file [H]istory" },
	{ "<leader>gdH", "<cmd>DiffviewFileHistory<cr>", desc = "[G]it [D]iff repo [H]istory" },
	{ "<leader>gdq", "<cmd>DiffviewClose<cr>", desc = "[G]it [D]iff [Q]uit" },
	{ "<leader>gdr", "<cmd>DiffviewRefresh<cr>", desc = "[G]it [D]iff [R]efresh" },

	-- Telescope pickers (defined below, loaded on keypress)
	{
		"<leader>gdb",
		function()
			require("alex-config.keymaps").diffview_pick_branch()
		end,
		desc = "[G]it [D]iff against [B]ranch",
	},
	{
		"<leader>gdB",
		function()
			require("alex-config.keymaps").diffview_view_branch()
		end,
		desc = "[G]it [D]iff view [B]ranch changes (vs HEAD)",
	},
	{
		"<leader>gdc",
		function()
			require("alex-config.keymaps").diffview_pick_commit()
		end,
		desc = "[G]it [D]iff against [C]ommit",
	},
	{
		"<leader>gdv",
		function()
			require("alex-config.keymaps").diffview_view_commit()
		end,
		desc = "[G]it [D]iff [V]iew commit (what it changed)",
	},
	{
		"<leader>gdC",
		function()
			require("alex-config.keymaps").diffview_pick_commit_range()
		end,
		desc = "[G]it [D]iff [C]ommit range",
	},
}

-- Telescope picker: select branch → diff current state against it
M.diffview_pick_branch = function()
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	require("telescope.builtin").git_branches({
		prompt_title = "Diff current state against branch",
		attach_mappings = function(prompt_bufnr, map)
			local open_diff = function()
				local selection = action_state.get_selected_entry()
				actions.close(prompt_bufnr)
				if selection then
					-- LEFT = selected branch, RIGHT = current working tree
					local branch = selection.value
					vim.cmd("DiffviewOpen " .. branch)
				end
			end

			map("i", "<CR>", open_diff)
			map("n", "<CR>", open_diff)
			return true
		end,
	})
end

-- Telescope picker: select branch → view what it has vs current HEAD
M.diffview_view_branch = function()
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	require("telescope.builtin").git_branches({
		prompt_title = "View branch changes (vs current HEAD)",
		attach_mappings = function(prompt_bufnr, map)
			local open_diff = function()
				local selection = action_state.get_selected_entry()
				actions.close(prompt_bufnr)
				if selection then
					-- Shows what branch has that HEAD doesn't (like a PR diff)
					local branch = selection.value
					vim.cmd("DiffviewOpen HEAD..." .. branch)
				end
			end

			map("i", "<CR>", open_diff)
			map("n", "<CR>", open_diff)
			return true
		end,
	})
end

-- Telescope picker: select commit → diff current state against it
M.diffview_pick_commit = function()
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	require("telescope.builtin").git_commits({
		prompt_title = "Diff current state against commit",
		attach_mappings = function(prompt_bufnr, map)
			local open_diff = function()
				local selection = action_state.get_selected_entry()
				actions.close(prompt_bufnr)
				if selection then
					-- LEFT = selected commit, RIGHT = current working tree
					vim.cmd("DiffviewOpen " .. selection.value)
				end
			end

			map("i", "<CR>", open_diff)
			map("n", "<CR>", open_diff)
			return true
		end,
	})
end

-- Telescope picker: select commit → view what that commit changed
M.diffview_view_commit = function()
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	require("telescope.builtin").git_commits({
		prompt_title = "View commit changes",
		attach_mappings = function(prompt_bufnr, map)
			local open_diff = function()
				local selection = action_state.get_selected_entry()
				actions.close(prompt_bufnr)
				if selection then
					-- Shows what this commit changed (commit vs its parent)
					vim.cmd("DiffviewOpen " .. selection.value .. "^!")
				end
			end

			map("i", "<CR>", open_diff)
			map("n", "<CR>", open_diff)
			return true
		end,
	})
end

-- Telescope picker: select two commits → open diffview for range
M.diffview_pick_commit_range = function()
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local first_commit = nil

	require("telescope.builtin").git_commits({
		prompt_title = "Select FIRST commit (older)",
		attach_mappings = function(prompt_bufnr, map)
			local select_first = function()
				local selection = action_state.get_selected_entry()
				actions.close(prompt_bufnr)
				if selection then
					first_commit = selection.value
					-- Now pick second commit
					vim.defer_fn(function()
						require("telescope.builtin").git_commits({
							prompt_title = "Select SECOND commit (newer)",
							attach_mappings = function(prompt_bufnr2, map2)
								local select_second = function()
									local selection2 = action_state.get_selected_entry()
									actions.close(prompt_bufnr2)
									if selection2 and first_commit then
										vim.cmd("DiffviewOpen " .. first_commit .. ".." .. selection2.value)
									end
								end

								map2("i", "<CR>", select_second)
								map2("n", "<CR>", select_second)
								return true
							end,
						})
					end, 100)
				end
			end

			map("i", "<CR>", select_first)
			map("n", "<CR>", select_first)
			return true
		end,
	})
end

return M
