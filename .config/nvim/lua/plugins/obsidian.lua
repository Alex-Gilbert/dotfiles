return {
	"epwalsh/obsidian.nvim",
	version = "*", -- recommended, use latest release instead of latest commit
	lazy = true,
	keys = require("alex-config.keymaps").obsidian_keys,
	ft = "markdown",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	opts = {
		workspaces = {
			{
				name = "personal",
				path = "~/alex-vault/",
			},
		},

		notes_subdir = "000-INBOX",
		new_notes_location = "notes_subdir",

		---@param title string|?
		---@return string
		note_id_func = function(title)
			local suffix = ""
			title = title or vim.fn.input("Title: ")
			if title ~= nil then
				suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
			else
				for _ = 1, 4 do
					suffix = suffix .. string.char(math.random(65, 90))
				end
			end
			local timestamp = os.date("%Y%m%d")
			return timestamp .. "-" .. suffix
		end,

		completion = {
			nvim_cmp = true,
			min_chars = 2,
		},

		templates = {
			folder = "999-TEMPLATES",
			date_format = "%Y-%m-%d",
			time_format = "%H:%M",
		},

		---@param url string
		follow_url_func = function(url)
			vim.fn.jobstart({ "xdg-open", url }) -- linux
		end,

		---@param img string
		follow_img_func = function(img)
			vim.fn.jobstart({ "xdg-open", img }) -- linux
		end,

		picker = { name = "telescope.nvim" },

		mappings = {},
	},
	config = function(_, opts)
		require("obsidian").setup(opts)
		local process_note = function()
			local filepath = vim.fn.expand("%:p") -- Get the current file path
			local filename = vim.fn.expand("%:t") -- Get the current file name
			local filedir = vim.fn.expand("%:p:h") -- Get the file's directory
			local sanitized_title = filename:gsub("%.md$", ""):gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()

			-- Fetch file creation date using `stat`
			local handle = io.popen('stat -c %w "' .. filepath .. '"') -- `%w` gets the birth/creation time
			local creation_date = handle:read("*a"):gsub("\n", "")
			handle:close()

			-- If `stat` doesn't support `%w`, fallback to `mtime`
			if creation_date == "" or creation_date == "?" then
				local mtime_handle = io.popen('stat -c %y "' .. filepath .. '"') -- `%y` gets modification time
				creation_date = mtime_handle:read("*a"):gsub("\n", ""):sub(1, 10):gsub("-", "")
				mtime_handle:close()
			else
				creation_date = creation_date:sub(1, 10):gsub("-", "")
			end

			-- Ensure creation_date is valid
			if creation_date == "" then
				print("Error: Unable to determine file creation date for " .. filepath)
				return
			end

			-- Generate the new filename
			local new_filename = creation_date .. "-" .. sanitized_title .. ".md"
			local new_filepath = filedir .. "/" .. new_filename

			-- Rename the file
			os.rename(filepath, new_filepath)

			-- Read the file content
			local lines = {}
			for line in io.lines(new_filepath) do
				table.insert(lines, line)
			end

			-- Look for the frontmatter block
			local frontmatter_start, frontmatter_end, id_found = nil, nil, false
			for i, line in ipairs(lines) do
				if line:match("^---$") then
					if not frontmatter_start then
						frontmatter_start = i
					else
						frontmatter_end = i
						break
					end
				elseif line:match("^id: ") then
					id_found = true
					lines[i] = "id: " .. creation_date .. "-" .. sanitized_title -- Update the existing id
				end
			end

			-- If frontmatter exists but `id` is not found, add it
			if frontmatter_start and frontmatter_end and not id_found then
				table.insert(lines, frontmatter_end, "id: " .. creation_date .. "-" .. sanitized_title)
			elseif not frontmatter_start then
				-- If no frontmatter, add it
				table.insert(lines, 1, "---")
				table.insert(lines, 2, "id: " .. creation_date .. "-" .. sanitized_title)
				table.insert(lines, 3, "---")
			end

			-- Write updated content back to the renamed file
			local file = io.open(new_filepath, "w")
			for _, line in ipairs(lines) do
				file:write(line .. "\n")
			end
			file:close()

			-- Open the renamed file
			vim.cmd("edit " .. new_filepath)

			print("Note renamed and processed: " .. new_filename)
		end

		vim.api.nvim_create_user_command("ProcessNote", process_note, {})
		require("alex-config.keymaps").set_obsidian_keys()
	end,
}
