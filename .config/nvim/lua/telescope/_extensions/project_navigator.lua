-- Project navigation with Telescope
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

-- Function to get all project names
local function get_project_names()
	local projects = {}
	local handle = io.popen(
		"find ~/dev/ -mindepth 3 -maxdepth 4 -type d -not -path '*/\\.git*' -not -path '*/node_modules/*' | sort"
	)

	if handle then
		for line in handle:lines() do
			local project_name = vim.fn.fnamemodify(line, ":t")
			local project_path = line
			projects[#projects + 1] = { name = project_name, path = project_path }
		end
		handle:close()
	end

	return projects
end

-- Function to get worktree directories for a specific project
local function get_worktrees(project_name)
	local worktrees = {}
	local worktree_base = "~/dev/worktrees/" .. project_name
	local expanded_path = vim.fn.expand(worktree_base)

	if vim.fn.isdirectory(expanded_path) == 1 then
		local handle = io.popen("find " .. expanded_path .. " -mindepth 1 -maxdepth 1 -type d | sort")

		if handle then
			for line in handle:lines() do
				local branch_name = vim.fn.fnamemodify(line, ":t")
				worktrees[#worktrees + 1] = { name = project_name .. ":" .. branch_name, path = line }
			end
			handle:close()
		end
	end

	return worktrees
end

-- Define the Telescope extension
local project_navigator = {}

project_navigator.projects = function(opts)
	opts = opts or {}
	local projects = get_project_names()
	local all_items = {}

	-- Add main projects
	for _, project in ipairs(projects) do
		table.insert(all_items, project)

		-- Add worktrees for this project if requested
		if opts.include_worktrees then
			local worktrees = get_worktrees(project.name)
			for _, worktree in ipairs(worktrees) do
				table.insert(all_items, worktree)
			end
		end
	end

	pickers
		.new(opts, {
			prompt_title = "Projects" .. (opts.include_worktrees and " & Worktrees" or ""),
			finder = finders.new_table({
				results = all_items,
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry.name,
						ordinal = entry.name,
						path = entry.path,
					}
				end,
			}),
			sorter = conf.generic_sorter(opts),
			previewer = conf.file_previewer(opts),
			attach_mappings = function(prompt_bufnr, map)
				-- Default action: change directory and edit
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)

					-- Change directory and open in editor
					vim.cmd("cd " .. selection.path)
					vim.cmd("edit " .. selection.path)
				end)

				return true
			end,
		})
		:find()
end

project_navigator.worktrees = function(opts)
	opts = opts or {}
	local current_dir = vim.fn.expand("%:p:h")
	local project_name = ""

	-- Try to extract project name from path
	if string.find(current_dir, "/dev/remote/") then
		project_name = vim.fn.fnamemodify(current_dir, ":t")
	elseif string.find(current_dir, "/dev/worktrees/") then
		project_name = vim.fn.fnamemodify(vim.fn.fnamemodify(current_dir, ":h"), ":t")
	else
		if opts.project then
			project_name = opts.project
		else
			print("Not in a recognized project directory")
			return
		end
	end

	local worktrees = get_worktrees(project_name)

	pickers
		.new(opts, {
			prompt_title = project_name .. " Worktrees",
			finder = finders.new_table({
				results = worktrees,
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry.name:gsub(project_name .. ":", ""),
						ordinal = entry.name,
						path = entry.path,
					}
				end,
			}),
			sorter = conf.generic_sorter(opts),
			previewer = conf.file_previewer(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)

					-- Change directory and open in editor
					vim.cmd("cd " .. selection.path)
					vim.cmd("edit " .. selection.path)
				end)
				return true
			end,
		})
		:find()
end

-- Register with Telescope
return require("telescope").register_extension({
	exports = {
		projects = project_navigator.projects,
		worktrees = project_navigator.worktrees,
	},
})
