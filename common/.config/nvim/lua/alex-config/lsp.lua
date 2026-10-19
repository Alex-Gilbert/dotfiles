local M = {}

-- TS 7 (native Go compiler) ships no tsserver.js, so ts_ls can't serve it; its own
-- `tsc --lsp` can. Pick the server per project by the installed typescript major.
local function ts_major(root)
	local ok, lines = pcall(vim.fn.readfile, root .. "/node_modules/typescript/package.json")
	local version = ok and vim.json.decode(table.concat(lines, "\n")).version
	return tonumber(version and version:match("^(%d+)")) or 0
end

-- shortcut: reads the nearest node_modules only, so a monorepo package that hoists
-- typescript to the root falls to ts_ls; walk further up if that bites.
local function ts_gate(name, want_native)
	-- each vim.lsp.config[name] read reloads lsp/<name>.lua; tsc's root_dir and cmd
	-- share a binary cache, so both must come from the same load
	local base = vim.lsp.config[name]
	return {
		cmd = base.cmd,
		root_dir = function(bufnr, on_dir)
			local root = vim.fs.root(bufnr, "node_modules")
			if ((root and ts_major(root) or 0) >= 7) == want_native then
				base.root_dir(bufnr, on_dir)
			end
		end,
	}
end

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
		filetypes = { "cs" },
		root_dir = function(bufnr, on_dir)
			local root = vim.fs.root(bufnr, function(name)
				return name:match("%.sln$") or name:match("%.csproj$") or name:match("%.fsproj$")
			end)
			on_dir(root or vim.fs.root(bufnr, ".git"))
		end,
		init_options = {
			AutomaticWorkspaceInit = true,
		},
	},

	pylsp = {
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
		-- TypeScript Language Server (TS <= 6 projects)
		root_dir = ts_gate("ts_ls", false).root_dir,
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

	ltex_plus = {},

	elixirls = {},
}

-- Servers that are managed outside of Mason (cargo, npm, system packages, etc.)
M.external_servers = {
	gleam = {},
	-- TS 7 projects: the project's own tsc is the language server
	tsc = ts_gate("tsc", true),
}

return M
