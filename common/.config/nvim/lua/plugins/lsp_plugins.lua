return {
	{
		-- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
		-- used for completion, annotations and signatures of Neovim apis
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				-- Load luvit types when the `vim.uv` word is found
				{ path = "luvit-meta/library", words = { "vim%.uv" } },
			},
		},
	},
	{ "Bilal2453/luvit-meta", lazy = true },
	{
		-- Main LSP Configuration
		"neovim/nvim-lspconfig",
		dependencies = {
			-- Mason
			{ "williamboman/mason.nvim", config = true }, -- NOTE: Must be loaded before dependants
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			-- Autoformat
			{ "j-hui/fidget.nvim", opts = {} },
			"hrsh7th/cmp-nvim-lsp",
			-- Navic
			"SmiteshP/nvim-navic",
		},
		config = function()
			-- This function will be executed to configure the current buffer when the LSP server attaches
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
				callback = function(event)
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					require("alex-config.keymaps").set_lsp_keys(event, client)
					require("alex-config.auto_cmds").set_lsp_autocmds(event, client)
				end,
			})

			-- Change diagnostic symbols in the sign column (gutter)
			if vim.g.have_nerd_font then
				local signs = { ERROR = "", WARN = "", INFO = "", HINT = "" }
				local diagnostic_signs = {}
				for type, icon in pairs(signs) do
					diagnostic_signs[vim.diagnostic.severity[type]] = icon
				end
				vim.diagnostic.config({ signs = { text = diagnostic_signs } })
			end

			-- Set up LSP capabilities
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

			capabilities = vim.tbl_deep_extend("force", capabilities, {
				text_document = {
					position_encoding = "utf-16",
				},
			})

			local lsp_config = require("alex-config.lsp")
			local servers = lsp_config.servers
			local external_servers = lsp_config.external_servers

			-- Run setup_config for all external servers that define it
			for server_name, server_config in pairs(external_servers) do
				if type(server_config.setup_config) == "function" then
					server_config.setup_config()
				end
			end

			require("mason").setup()

			-- Only install servers from the main servers table
			local ensure_installed = vim.tbl_keys(servers or {})
			vim.list_extend(ensure_installed, lsp_config.additional_tools)

			local navic = require("nvim-navic")

			require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

			-- Helper function to setup an LSP server
			local function setup_server(server_name, server_config)
				server_config = server_config or {}
				server_config.capabilities =
					vim.tbl_deep_extend("force", {}, capabilities, server_config.capabilities or {})

				-- Attach Navic to servers that support document symbols
				local original_on_attach = server_config.on_attach

				server_config.on_attach = function(client, bufnr)
					if original_on_attach then
						original_on_attach(client, bufnr)
					end

					if client.server_capabilities.documentSymbolProvider then
						navic.attach(client, bufnr)
					end
				end

				require("lspconfig")[server_name].setup(server_config)
			end

			require("mason-lspconfig").setup({
				automatic_installation = true,
				ensure_installed = {},
				handlers = {
					function(server_name)
						setup_server(server_name, servers[server_name])
					end,
				},
			})

			-- Setup external servers (not managed by Mason)
			for server_name, server_config in pairs(external_servers) do
				setup_server(server_name, server_config)
			end
		end,
	},

	{ -- Autoformat
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = require("alex-config.keymaps").conform_keys,
		opts = {
			notify_on_error = false,
			format_on_save = function(bufnr)
				-- -- Disable "format_on_save lsp_fallback" for languages that don't
				-- -- have a well standardized coding style. You can add additional
				-- -- languages here or re-enable it for the disabled ones.
				-- local disable_filetypes = { c = true, cpp = true }
				-- local lsp_format_opt
				-- if disable_filetypes[vim.bo[bufnr].filetype] then
				lsp_format_opt = "never"
				-- else
				-- 	lsp_format_opt = "fallback"
				-- end
				return {
					timeout_ms = 500,
					lsp_format = lsp_format_opt,
				}
			end,
			formatters_by_ft = {
				go = { "goimports", "gofumpt" },
				lua = { "stylua" },
				nix = { "nixfmt" },
			},
		},
	},

	{ -- Autocompletion
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			{
				"L3MON4D3/LuaSnip",
				build = (function()
					if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
						return
					end
					return "make install_jsregexp"
				end)(),
				dependencies = {
					{
						"rafamadriz/friendly-snippets",
						config = function()
							require("luasnip.loaders.from_vscode").lazy_load()
						end,
					},
				},
			},
			"saadparwaiz1/cmp_luasnip",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-path",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			luasnip.config.setup({})

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				completion = { completeopt = "menu,menuone,noinsert" },

				-- For an understanding of why these mappings were
				-- chosen, you will need to read `:help ins-completion`
				--
				-- No, but seriously. Please read `:help ins-completion`, it is really good!
				mapping = cmp.mapping.preset.insert(require("alex-config.keymaps").cmp_keys(cmp, luasnip)),
				sources = {
					{
						name = "lazydev",
						-- set group index to 0 to skip loading LuaLS completions as lazydev recommends it
						group_index = 0,
					},
					{ name = "nvim_lsp" },
					-- { name = "supermaven" },
					{ name = "luasnip" },
					{ name = "path" },
				},
			})
		end,
	},

	{ -- rustaceanvim
		"mrcjkb/rustaceanvim",
		version = "^6",
		lazy = false,
		config = function()
			vim.g.rustaceanvim = {
				server = {
					on_attach = function(client, bufnr)
						require("alex-config.keymaps").set_rust_lsp_keys(bufnr, client)
					end,
				},
			}
		end,
	},
	{
		"saecki/crates.nvim",
		event = { "BufRead Cargo.toml" }, -- Lazy load only when opening Cargo.toml
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local crates = require("crates")

			crates.setup({
				-- Smart features
				smart_insert = true,
				remove_enabled_default_features = true,
				remove_empty_features = true,
				insert_closing_quote = true,

				-- Auto features
				autoload = true,
				autoupdate = true,
				autoupdate_throttle = 250,
				loading_indicator = true,

				-- Enable crate name completion (searches crates.io)
				completion = {
					crates = {
						enabled = true,
						max_results = 8,
						min_chars = 3,
					},
				},

				-- Use LSP for completion and code actions
				lsp = {
					enabled = true,
					actions = true,
					completion = true,
					hover = true,
					on_attach = function(client, bufnr)
						-- This will use your existing LSP on_attach if needed
						local keymaps = require("alex-config.keymaps")
						if keymaps.set_crates_keys then
							keymaps.set_crates_keys(bufnr)
						end
					end,
				},

				-- Popup configuration
				popup = {
					autofocus = false,
					hide_on_select = false,
					show_version_date = true,
					show_dependency_version = true,
					style = "minimal",
					border = "rounded", -- Match your Neovim style
				},
			})
		end,
	},
}
