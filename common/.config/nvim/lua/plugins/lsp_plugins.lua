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
			-- NOTE: fidget.nvim removed - noice.nvim handles LSP progress
			-- Completion capabilities (blink.cmp)
			"saghen/blink.cmp",
			-- Navic
			"SmiteshP/nvim-navic",
		},
		config = function()
			-- This function will be executed to configure the current buffer when the LSP server attaches
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
				callback = function(event)
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if not client then
						return
					end
					local keymaps = require("alex-config.keymaps")
					-- One handler so the Rust overrides (K, <leader>ca) aren't clobbered by the base keys
					if client.name == "rust-analyzer" then
						keymaps.set_rust_lsp_keys(event.buf, client)
					else
						keymaps.set_lsp_keys(event, client)
					end
					if client.name == "gleam" then
						keymaps.set_gleam_keys(event.buf)
					end
					if client.server_capabilities.documentSymbolProvider then
						require("nvim-navic").attach(client, event.buf)
					end
					require("alex-config.auto_cmds").set_lsp_autocmds(event, client)
				end,
			})

			-- Change diagnostic symbols in the sign column (gutter)
			if vim.g.have_nerd_font then
				local signs = { ERROR = "", WARN = "", INFO = "", HINT = "" }
				local diagnostic_signs = {}
				for type, icon in pairs(signs) do
					diagnostic_signs[vim.diagnostic.severity[type]] = icon
				end
				vim.diagnostic.config({ signs = { text = diagnostic_signs } })
			end

			vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })

			local lsp_config = require("alex-config.lsp")
			local servers = lsp_config.servers

			require("mason").setup()

			local ensure_installed = vim.tbl_keys(servers or {})
			vim.list_extend(ensure_installed, lsp_config.additional_tools)
			require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

			-- Settings merge over nvim-lspconfig's defaults; mason-lspconfig enables
			-- every Mason-installed server (it no longer takes per-server handlers).
			for server_name, server_config in pairs(servers) do
				vim.lsp.config(server_name, server_config)
			end
			require("mason-lspconfig").setup({
				-- ltex_plus replaces ltex; both packages are installed
				automatic_enable = { exclude = { "ltex" } },
			})

			-- Servers not managed by Mason
			for server_name, server_config in pairs(lsp_config.external_servers) do
				vim.lsp.config(server_name, server_config)
				vim.lsp.enable(server_name)
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
					timeout_ms = 1000, -- prettier's cold start can exceed 500ms
					lsp_format = lsp_format_opt,
				}
			end,
			formatters_by_ft = {
				elixir = { "mix" },
				gleam = { "gleam" },
				go = { "goimports", "gofumpt" },
				lua = { "stylua" },
				nix = { "nixfmt" },
				rust = { "rustfmt" },
				javascript = { "prettier" },
				javascriptreact = { "prettier" },
				typescript = { "prettier" },
				typescriptreact = { "prettier" },
				json = { "prettier" },
				css = { "prettier" },
				html = { "prettier" },
			},
			-- Only format JS/TS where the project opted into prettier; most repos have no config
			formatters = { prettier = { require_cwd = true } },
		},
	},

	-- Linting for filetypes with no language server to do it. conform handles
	-- formatting; this is the diagnostics half. Mainly here for shellcheck --
	-- this repo carries ~30 shell scripts that nothing else checks.
	--
	-- nvim-lint no-ops silently when a linter binary is absent, so a machine
	-- without shellcheck/markdownlint installed just gets no diagnostics
	-- rather than errors on every write.
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPost", "BufWritePost", "InsertLeave" },
		config = function()
			local lint = require("lint")

			lint.linters_by_ft = {
				sh = { "shellcheck" },
				bash = { "shellcheck" },
				markdown = { "markdownlint" },
			}

			-- fish has its own built-in checker (`fish --no-execute`), which
			-- nvim-lint ships as the "fish" linter.
			if vim.fn.executable("fish") == 1 then
				lint.linters_by_ft.fish = { "fish" }
			end

			local group = vim.api.nvim_create_augroup("alex-nvim-lint", { clear = true })
			vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
				group = group,
				callback = function()
					-- Only lint modifiable, on-disk buffers; skips help,
					-- terminals, and the various plugin scratch windows.
					if vim.bo.modifiable and vim.bo.buftype == "" then
						lint.try_lint()
					end
				end,
			})
		end,
	},

	{ -- Autocompletion (blink.cmp - faster, modern replacement for nvim-cmp)
		"saghen/blink.cmp",
		version = "1.*",
		dependencies = {
			"rafamadriz/friendly-snippets",
		},
		event = "InsertEnter",
		---@module 'blink.cmp'
		---@type blink.cmp.Config
		opts = {
			keymap = {
				preset = "none",
				["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
				["<C-e>"] = { "hide" },
				["<C-y>"] = { "select_and_accept" },

				["<C-p>"] = { "select_prev", "fallback" },
				["<C-n>"] = { "select_next", "fallback" },

				["<C-b>"] = { "scroll_documentation_up", "fallback" },
				["<C-f>"] = { "scroll_documentation_down", "fallback" },

				["<C-left>"] = { "snippet_forward", "fallback" },
				["<C-right>"] = { "snippet_backward", "fallback" },
			},

			appearance = {
				use_nvim_cmp_as_default = true,
				nerd_font_variant = "mono",
			},

			completion = {
				accept = { auto_brackets = { enabled = true } },
				documentation = { auto_show = true, auto_show_delay_ms = 200 },
				list = { selection = { preselect = true, auto_insert = true } },
			},

			-- Obsidian completion uses the LSP source
			sources = {
				default = { "lazydev", "lsp", "path", "snippets", "buffer" },
				providers = {
					lazydev = {
						name = "LazyDev",
						module = "lazydev.integrations.blink",
						score_offset = 100,
					},
				},
			},
		},
		opts_extend = { "sources.default" },
	},

	{ -- rustaceanvim
		"mrcjkb/rustaceanvim",
		version = "^9",
		lazy = false,
		init = function()
			vim.g.rustaceanvim = {
				server = {
					default_settings = {
						["rust-analyzer"] = { check = { command = "clippy" } },
					},
				},
				dap = {
					adapter = function()
						local install_root = require("mason.settings").current.install_root_dir
						local extension_path = install_root .. "/packages/codelldb/extension/"
						local codelldb_path = extension_path .. "adapter/codelldb"
						local liblldb_path = extension_path
							.. "lldb/lib/liblldb."
							.. (vim.fn.has("mac") == 1 and "dylib" or "so")

						local cfg = require("rustaceanvim.config")
						return cfg.get_codelldb_adapter(codelldb_path, liblldb_path)
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
