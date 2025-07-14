return {
	"epwalsh/obsidian.nvim",
	version = "*", -- recommended, use latest release instead of latest commit
	lazy = true,
	ft = "markdown",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	opts = {
		workspaces = {
			{
				name = "zettelkasten",
				path = "~/Zettelkasten",
			},
		},
		notes_subdir = "00-inbox",

		-- Template handling
		templates = {
			subdir = "90-resources/templates",
		},

		new_notes_location = "notes_subdir",

		completion = {
			nvim_cmp = true,
			min_chars = 2,
		},

		preferred_link_style = "wiki",

		-- Disable automatic UI features
		ui = { enable = false },

		-- Custom note ID function that returns just the title
		---@param title string|?
		---@return string
		note_id_func = function(title)
			if title ~= nil then
				return title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
			else
				return tostring(os.time())
			end
		end,

		note_frontmatter_func = function(note)
			local out = { id = note.id, tags = note.tags }
			if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
				for k, v in pairs(note.metadata) do
					out[k] = v
				end
			end
			return out
		end,

		-- Optional, customize how note file names are generated given the ID, target directory, and title.
		---@param spec { id: string, dir: obsidian.Path, title: string|? }
		---@return string|obsidian.Path The full path to the new note.
		note_path_func = function(spec)
			-- Use just the note ID as the filename
			local path = spec.dir / tostring(spec.id)
			return path:with_suffix(".md")
		end,

		wiki_link_func = function(opts)
			if opts.id == nil then
				return string.format("[[%s]]", opts.label)
			elseif opts.label ~= opts.id then
				return string.format("[[%s|%s]]", opts.id, opts.label)
			else
				return string.format("[[%s]]", opts.id)
			end
		end,

		-- Optional, configure key mappings.
		disable_frontmatter = false,

		-- Optional, by default when you use `:ObsidianFollowLink` on a link to an external
		-- URL it will be ignored but you can customize this behavior here.
		-- Windows/Linux behavior
		daily_notes = {
			date_format = "%Y-%m-%d",
			template = "daily-template.md",
			alias_format = "%B %-d, %Y",
			default_tags = { "daily-notes" },
			time_format = "%H:%M",
		},

		-- Load platform utilities
		follow_url_func = function(url)
			local platform = require("utils.platform")
			local open_cmd = platform.get_open_cmd()
			vim.fn.jobstart({ open_cmd, url })
		end,

		follow_img_func = function(img)
			local platform = require("utils.platform")
			local open_cmd = platform.get_open_cmd()
			vim.fn.jobstart({ open_cmd, img })
		end,

		picker = { name = "telescope.nvim" },

		mappings = {},
	},
	config = function(_, opts)
		require("obsidian").setup(opts)
		local platform = require("utils.platform")
		
		local process_note = function()
			local filepath = vim.fn.expand("%:p") -- Get the current file path
			local filename = vim.fn.expand("%:t") -- Get the current file name
			local filedir = vim.fn.expand("%:p:h") -- Get the file's directory
			local sanitized_title = filename:gsub("%.md$", ""):gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()

			-- Fetch file creation date using platform-appropriate stat command
			local stat_cmd = platform.get_stat_cmd("birth")
			local handle = io.popen(stat_cmd .. ' "' .. filepath .. '"')
			local creation_date = handle:read("*a"):gsub("\n", "")
			handle:close()

			-- If birth time is not available, fallback to modification time
			if creation_date == "" or creation_date == "?" or creation_date == "-" then
				local mtime_cmd = platform.get_stat_cmd("modified")
				local mtime_handle = io.popen(mtime_cmd .. ' "' .. filepath .. '"')
				creation_date = mtime_handle:read("*a"):gsub("\n", "")
				mtime_handle:close()
				
				-- Extract date portion (handling different output formats)
				if platform.is_macos then
					-- macOS stat returns epoch timestamp, convert it
					local timestamp = tonumber(creation_date)
					if timestamp then
						creation_date = os.date("%Y%m%d", timestamp)
					end
				else
					-- Linux stat returns formatted date, extract YYYYMMDD
					creation_date = creation_date:sub(1, 10):gsub("-", "")
				end
			else
				-- Handle birth time format
				if platform.is_macos then
					local timestamp = tonumber(creation_date)
					if timestamp then
						creation_date = os.date("%Y%m%d", timestamp)
					end
				else
					creation_date = creation_date:sub(1, 10):gsub("-", "")
				end
			end

			-- Ensure creation_date is valid
			if not creation_date or creation_date == "" or not creation_date:match("^%d%d%d%d%d%d%d%d$") then
				creation_date = os.date("%Y%m%d")
			end

			-- Generate the new filename
			local new_filename = creation_date .. "-" .. sanitized_title .. ".md"
			local new_filepath = filedir .. "/" .. new_filename

			-- Rename the file
			if filepath ~= new_filepath then
				local ok, err = os.rename(filepath, new_filepath)
				if ok then
					-- Reopen the renamed file in the current buffer
					vim.cmd("edit " .. vim.fn.fnameescape(new_filepath))
					print("Renamed to: " .. new_filename)
				else
					print("Error renaming file: " .. err)
				end
			else
				print("File already has the correct name: " .. new_filename)
			end
		end

		vim.keymap.set("n", "<leader>zp", process_note, { desc = "Process Note" })
		vim.keymap.set("n", "<leader>z<leader>", "<cmd>ObsidianQuickSwitch<CR>", { desc = "Quick Switch" })
		vim.keymap.set("n", "<leader>zf", "<cmd>ObsidianSearch<CR>", { desc = "Find in vault" })
		vim.keymap.set("n", "<leader>zn", "<cmd>ObsidianNew<CR>", { desc = "New note" })
		vim.keymap.set("n", "<leader>zN", "<cmd>ObsidianNewFromTemplate<CR>", { desc = "New from template" })
		vim.keymap.set("n", "<leader>zt", "<cmd>ObsidianTags<CR>", { desc = "Tags" })
		vim.keymap.set("n", "<leader>zd", "<cmd>ObsidianDailies<CR>", { desc = "Daily notes" })
		vim.keymap.set("n", "<leader>zD", "<cmd>ObsidianToday<CR>", { desc = "Today's note" })
		vim.keymap.set("n", "<leader>zy", "<cmd>ObsidianYesterday<CR>", { desc = "Yesterday's note" })
		vim.keymap.set("n", "<leader>zb", "<cmd>ObsidianBacklinks<CR>", { desc = "Backlinks" })
		vim.keymap.set("n", "<leader>zl", "<cmd>ObsidianLinks<CR>", { desc = "Links" })
		vim.keymap.set("n", "<leader>zo", "<cmd>ObsidianOpen<CR>", { desc = "Open in Obsidian" })
		vim.keymap.set("n", "<leader>zx", "<cmd>ObsidianExtractNote<CR>", { desc = "Extract note" })
		vim.keymap.set("n", "<leader>zi", "<cmd>ObsidianTemplate<CR>", { desc = "Insert template" })
		vim.keymap.set("n", "<leader>zT", "<cmd>ObsidianTOC<CR>", { desc = "Table of Contents" })
		vim.keymap.set("n", "<leader>zr", "<cmd>ObsidianRename<CR>", { desc = "Rename note" })
		vim.keymap.set("n", "<leader>zs", "<cmd>ObsidianQuickSwitch<CR>", { desc = "Quick switch" })
		vim.keymap.set("n", "<leader>zw", "<cmd>ObsidianWorkspace<CR>", { desc = "Switch workspace" })

		-- Concealer setup
		vim.opt.conceallevel = 1
		vim.api.nvim_create_autocmd({ "BufRead", "BufEnter" }, {
			pattern = { "*.md" },
			callback = function()
				vim.opt.conceallevel = 1
			end,
		})
	end,
}