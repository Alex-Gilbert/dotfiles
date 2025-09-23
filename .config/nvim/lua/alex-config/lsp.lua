local lsp = require("lspconfig")

local M = {}

M.additional_tools = {
	"stylua", -- Lua formatter
	"delve", -- Go debugger
	"golangci-lint", -- Go linter
	"gofumpt", -- Go formatter
	"goimports", -- Go import formatter
	"gotests", -- Go test generator
	"impl", -- Go interface implementation generator
	"typescript-language-server",
	"eslint-lsp", -- if using ESLint
	"prettier", -- for formatting
	"js-debug-adapter", -- for js debugging
	"netcoredbg", -- for c# debugging
}

M.servers = {
	lua_ls = {
		settings = {
			Lua = {
				completion = {
					callSnippet = "Replace",
				},
			},
		},
	},

	csharp_ls = {
		on_attach = function()
			print("Hello From C#")
		end,
		filetypes = { "cs" },
		root_dir = function(startpath)
			return lsp.util.root_pattern("*.sln")(startpath)
				or lsp.util.root_pattern("*.csproj")(startpath)
				or lsp.util.root_pattern("*.fsproj")(startpath)
				or lsp.util.root_pattern(".git")(startpath)
		end,
		init_options = {
			AutomaticWorkspaceInit = true,
		},
	},

	pylsp = {
		on_attach = function()
			print("Hello From Python")
		end,
		settings = {
			pylsp = {
				plugins = {
					pycodestyle = {
						maxLineLength = 120,
					},
				},
			},
		},
	},

	clangd = {
		cmd = { "clangd", "--experimental-modules-support" },
	},

	-- Add Go language server
	gopls = {
		on_attach = function()
			print("Hello From Go")
		end,
		settings = {
			gopls = {
				gofumpt = true, -- Use gofumpt for formatting
				codelenses = {
					gc_details = false,
					generate = true,
					regenerate_cgo = true,
					run_govulncheck = true,
					test = true,
					tidy = true,
					upgrade_dependency = true,
					vendor = true,
				},
				hints = {
					assignVariableTypes = true,
					compositeLiteralFields = true,
					compositeLiteralTypes = true,
					constantValues = true,
					functionTypeParameters = true,
					parameterNames = true,
					rangeVariableTypes = true,
				},
				analyses = {
					nilness = true,
					unusedparams = true,
					unusedwrite = true,
					useany = true,
				},
				usePlaceholders = true,
				completeUnimported = true,
				staticcheck = true,
				directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
				semanticTokens = true,
			},
		},
	},
	ts_ls = {
		-- TypeScript Language Server
		init_options = {
			preferences = {
				disableSuggestions = true,
			},
		},
		settings = {
			typescript = {
				inlayHints = {
					includeInlayParameterNameHints = "all",
					includeInlayParameterNameHintsWhenArgumentMatchesName = false,
					includeInlayFunctionParameterTypeHints = true,
					includeInlayVariableTypeHints = true,
					includeInlayPropertyDeclarationTypeHints = true,
					includeInlayFunctionLikeReturnTypeHints = true,
					includeInlayEnumMemberValueHints = true,
				},
			},
			javascript = {
				inlayHints = {
					includeInlayParameterNameHints = "all",
					includeInlayParameterNameHintsWhenArgumentMatchesName = false,
					includeInlayFunctionParameterTypeHints = true,
					includeInlayVariableTypeHints = true,
					includeInlayPropertyDeclarationTypeHints = true,
					includeInlayFunctionLikeReturnTypeHints = true,
					includeInlayEnumMemberValueHints = true,
				},
			},
		},
	},
	eslint = {},
}

-- Servers that are managed outside of Mason (cargo, npm, system packages, etc.)
M.external_servers = {
	-- cargotomllsp = {
	-- 	-- Define how to register this server with lspconfig
	-- 	setup_config = function()
	-- 		local configs = require("lspconfig.configs")
	-- 		if not configs.cargotomllsp then
	-- 			configs.cargotomllsp = {
	-- 				default_config = {
	-- 					cmd = { "cargotomllsp" },
	-- 					filetypes = { "toml" },
	-- 					root_dir = function(fname)
	-- 						local util = require("lspconfig.util")
	-- 						-- Only attach to Cargo.toml files in Rust projects
	-- 						local root = util.root_pattern("Cargo.toml")(fname)
	-- 						if root and fname:match("Cargo%.toml$") then
	-- 							return root
	-- 						end
	-- 						-- Return nil to prevent attachment to other files
	-- 						return nil
	-- 					end,
	-- 					single_file_support = true,
	-- 					-- Specify server capabilities we expect
	-- 					server_capabilities = {
	-- 						completionProvider = true,
	-- 					},
	-- 				},
	-- 			}
	-- 		end
	-- 	end,
	--
	-- 	single_file_support = true,
	-- 	on_attach = function(client, bufnr)
	-- 		client.server_capabilities.documentFormattingProvider = false
	-- 		client.server_capabilities.documentRangeFormattingProvider = false
	-- 	end,
	-- },
}
return M
