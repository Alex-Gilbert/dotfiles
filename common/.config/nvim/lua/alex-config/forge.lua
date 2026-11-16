-- Pull requests for the current repo across every remote on GitHub (gh) or Gitea (tea),
-- reviewed in diffview.
local M = {}

local function run(cmd)
	local r = vim.system(cmd, { text = true }):wait()
	if r.code ~= 0 then
		vim.notify(vim.trim(r.stderr ~= "" and r.stderr or r.stdout), vim.log.levels.ERROR)
		return nil
	end
	return r.stdout
end

-- One forge per distinct repo across all remotes; remotes on other hosts (soft serve, paths) are skipped.
-- shortcut: Gitea login and host are hardcoded, make them config if a second Gitea ever appears
local function forges()
	local out = run({ "git", "remote", "-v" })
	if not out then
		return nil
	end
	local found, seen = {}, {}
	for remote, url in out:gmatch("(%S+)%s+(%S+)%s+%(fetch%)") do
		local slug = url:gsub("%.git$", ""):match("([^/:]+/[^/:]+)$")
		local f
		if url:find("github") then
			f = { remote = remote, kind = "gh", slug = slug, args = { "-R", slug } }
		elseif url:find("gitea") or url:find("gilbert") then
			f = {
				remote = remote,
				kind = "tea",
				slug = slug,
				args = { "--login", "gilbert", "--repo", slug },
				web = "https://git.gilbert.haus/" .. slug,
			}
		end
		if f and not seen[f.kind .. f.slug] then
			seen[f.kind .. f.slug] = true
			table.insert(found, f)
		end
	end
	if #found == 0 then
		vim.notify("No GitHub or Gitea remote in this repo", vim.log.levels.WARN)
		return nil
	end
	return found
end

local function cmd(f, ...)
	local argv = { f.kind, f.kind == "tea" and "pulls" or "pr", ... }
	return vim.list_extend(argv, f.args)
end

-- Actions with a single target: use the only forge, or ask which remote.
local function choose(callback)
	local fs = forges()
	if not fs then
		return
	end
	if #fs == 1 then
		return callback(fs[1])
	end
	vim.ui.select(fs, {
		prompt = "Remote",
		format_item = function(f)
			return f.remote .. "  " .. f.kind .. ":" .. f.slug
		end,
	}, function(f)
		if f then
			callback(f)
		end
	end)
end

local function terminal(argv)
	vim.cmd("botright split | terminal " .. table.concat(vim.tbl_map(vim.fn.shellescape, argv), " "))
	vim.cmd("startinsert")
end

-- Open PRs from every forge, fetched in parallel.
local function list(fs)
	local jobs = vim.tbl_map(function(f)
		local argv = f.kind == "tea" and cmd(f, "list", "-o", "json", "-f", "index,title,base,author,url")
			or cmd(f, "list", "--json", "number,title,baseRefName,author,url")
		return vim.system(argv, { text = true })
	end, fs)
	local prs = {}
	for i, job in ipairs(jobs) do
		local r = job:wait()
		if r.code ~= 0 then
			vim.notify(fs[i].remote .. ": " .. vim.trim(r.stderr), vim.log.levels.WARN)
		else
			for _, p in ipairs(vim.json.decode(r.stdout)) do
				table.insert(prs, {
					forge = fs[i],
					number = tonumber(p.index or p.number),
					title = p.title,
					base = p.base or p.baseRefName,
					author = type(p.author) == "table" and p.author.login or p.author,
					url = p.url,
				})
			end
		end
	end
	return prs
end

local function review(pr)
	local f = pr.forge
	if not run(cmd(f, "checkout", tostring(pr.number))) then
		return
	end
	run({ "git", "fetch", f.remote, pr.base })
	vim.cmd("DiffviewOpen " .. f.remote .. "/" .. pr.base .. "...HEAD")
end

-- Telescope picker: open PRs -> <CR> checks out and reviews in diffview, <C-o> opens in browser
M.pick = function()
	local fs = forges()
	if not fs then
		return
	end
	local prs = list(fs)
	if #prs == 0 then
		vim.notify("No open pull requests")
		return
	end
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	require("telescope.pickers")
		.new({}, {
			prompt_title = "Pull requests",
			finder = require("telescope.finders").new_table({
				results = prs,
				entry_maker = function(pr)
					local line = string.format("[%s] #%d %s (%s)", pr.forge.remote, pr.number, pr.title, pr.author)
					return { value = pr, display = line, ordinal = line }
				end,
			}),
			sorter = require("telescope.config").values.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					review(action_state.get_selected_entry().value)
				end)
				map({ "i", "n" }, "<C-o>", function()
					actions.close(prompt_bufnr)
					vim.ui.open(action_state.get_selected_entry().value.url)
				end)
				return true
			end,
		})
		:find()
end

M.create = function()
	choose(function(f)
		terminal(cmd(f, "create"))
	end)
end

-- The current branch's changes against the remote default branch, PR-style.
M.review_branch = function()
	choose(function(f)
		local head = f.remote .. "/HEAD"
		-- repos created by push (not clone) have no <remote>/HEAD; ask the remote once
		if vim.system({ "git", "rev-parse", "--verify", "-q", head }):wait().code ~= 0 then
			if not run({ "git", "remote", "set-head", f.remote, "--auto" }) then
				return
			end
		end
		vim.cmd("DiffviewOpen " .. head .. "...HEAD")
	end)
end

M.browse = function()
	choose(function(f)
		vim.ui.open(f.web and f.web .. "/pulls" or "https://github.com/" .. f.slug .. "/pulls")
	end)
end

M.checks = function()
	choose(function(f)
		if f.web then
			vim.ui.open(f.web .. "/actions")
		else
			-- gh refuses -R without a PR number; it finds the current branch's PR itself
			terminal({ "gh", "pr", "checks", "--watch" })
		end
	end)
end

M.keys = {
	{ "<leader>gpl", M.pick, desc = "List PRs on all remotes (review in diffview)" },
	{ "<leader>gpr", M.review_branch, desc = "Review current branch vs <remote>/HEAD" },
	{ "<leader>gpc", M.create, desc = "Create PR" },
	{ "<leader>gpb", M.browse, desc = "Open PRs in browser" },
	{ "<leader>gps", M.checks, desc = "PR checks / Actions" },
}

return M
