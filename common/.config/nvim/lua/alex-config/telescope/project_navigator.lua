-- Project navigation with Telescope
local M = {}

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

-- Projects picker
M.projects = function(opts)
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

	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	pickers
		.new({}, {
			prompt_title = "Projects" .. (opts.include_worktrees and " & Worktrees" or ""),
			finder = finders.new_table({
				results = all_items,
				entry_maker = function(entry)
					return {
						value = entry.path,
						display = entry.name,
						ordinal = entry.name,
						path = entry.path,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			previewer = conf.file_previewer({}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					if selection then
						vim.cmd("cd " .. selection.value)
						vim.cmd("edit " .. selection.value)
					end
				end)
				return true
			end,
		})
		:find()
end

-- Worktrees picker for current project
M.worktrees = function(opts)
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
			vim.notify("Not in a recognized project directory", vim.log.levels.WARN)
			return
		end
	end

	local worktrees = get_worktrees(project_name)

	if #worktrees == 0 then
		vim.notify("No worktrees found for " .. project_name, vim.log.levels.INFO)
		return
	end

	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	pickers
		.new({}, {
			prompt_title = project_name .. " Worktrees",
			finder = finders.new_table({
				results = worktrees,
				entry_maker = function(entry)
					local display_name = entry.name:gsub(project_name .. ":", "")
					return {
						value = entry.path,
						display = display_name,
						ordinal = display_name,
						path = entry.path,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			previewer = conf.file_previewer({}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					if selection then
						vim.cmd("cd " .. selection.value)
						vim.cmd("edit " .. selection.value)
					end
				end)
				return true
			end,
		})
		:find()
end

return M
