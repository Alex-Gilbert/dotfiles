-- Project navigation with Snacks.picker
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

-- Convert projects to snacks.picker items
local function projects_to_items(projects)
	local items = {}
	for _, project in ipairs(projects) do
		items[#items + 1] = {
			text = project.name,
			file = project.path,
			path = project.path,
		}
	end
	return items
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

	Snacks.picker.pick({
		title = "Projects" .. (opts.include_worktrees and " & Worktrees" or ""),
		items = projects_to_items(all_items),
		format = "file",
		preview = "directory",
		confirm = function(picker, item)
			picker:close()
			if item then
				vim.cmd("cd " .. item.path)
				vim.cmd("edit " .. item.path)
			end
		end,
	})
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

	-- Convert to picker items with simplified display
	local items = {}
	for _, wt in ipairs(worktrees) do
		items[#items + 1] = {
			text = wt.name:gsub(project_name .. ":", ""),
			file = wt.path,
			path = wt.path,
		}
	end

	Snacks.picker.pick({
		title = project_name .. " Worktrees",
		items = items,
		format = "file",
		preview = "directory",
		confirm = function(picker, item)
			picker:close()
			if item then
				vim.cmd("cd " .. item.path)
				vim.cmd("edit " .. item.path)
			end
		end,
	})
end

return M
