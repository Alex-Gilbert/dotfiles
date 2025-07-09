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

return M
