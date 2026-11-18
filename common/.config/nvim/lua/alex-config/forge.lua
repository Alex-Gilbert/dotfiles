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
				login = "gilbert",
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

-- argv for `gh pr VERB ...` / `tea pulls VERB ...`; repo flags go right after VERB, before positionals
local function cmd(f, verb, ...)
	local argv = { f.kind, f.kind == "tea" and "pulls" or "pr", verb }
	return vim.list_extend(vim.list_extend(argv, f.args), { ... })
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

-- The PR last opened for review; the <leader>gp{v,a,x,m} keys act on it.
local current

-- Diff the PR without touching the working tree: fetch its head ref (GitHub and Gitea both
-- publish refs/pull/N/head) into <remote>/pr/N.
local function review(pr)
	local f, n = pr.forge, tostring(pr.number)
	local head = f.remote .. "/pr/" .. n
	if not run({ "git", "fetch", f.remote, pr.base, "+refs/pull/" .. n .. "/head:refs/remotes/" .. head }) then
		return
	end
	current = pr
	vim.cmd("DiffviewOpen " .. f.remote .. "/" .. pr.base .. "..." .. head)
end

-- Old behaviour, for when you want LSP and tests on the PR: check it out as a branch.
local function checkout(pr)
	if run(cmd(pr.forge, "checkout", tostring(pr.number))) then
		current = pr
		run({ "git", "fetch", pr.forge.remote, pr.base })
		vim.cmd("DiffviewOpen " .. pr.forge.remote .. "/" .. pr.base .. "...HEAD")
	end
end

-- A Gitea PR goes to the gitea plugin (PR buffer, inline review); GitHub stays on gh.
local function gitea(pr, action)
	local g = require("gitea")
	g.open({ login = pr.forge.login, slug = pr.forge.slug, remote = pr.forge.remote, number = pr.number })
	if action and g.current and g.current.pr then
		action(g, g.current)
	end
end

local function with_pr(pr, fn)
	pr = pr or current
	if not pr then
		return vim.notify("No PR under review: open one with <leader>gpl", vim.log.levels.WARN)
	end
	fn(pr, pr.forge, tostring(pr.number))
end

-- Description, review state and comments, rendered by the forge CLI.
local function view(pr)
	with_pr(pr, function(p, f, n)
		if f.kind == "tea" then
			return gitea(p)
		end
		terminal(f.kind == "tea" and cmd(f, n) or cmd(f, "view", n, "--comments"))
	end)
end

local function approve(pr)
	with_pr(pr, function(p, f, n)
		if f.kind == "tea" then
			return gitea(p, function(g, ctx)
				g.submit(ctx, "APPROVED")
			end)
		end
		vim.ui.input({ prompt = "Approve #" .. n .. " (comment, optional): " }, function(msg)
			if msg == nil then
				return
			end
			local argv = f.kind == "tea" and cmd(f, "approve", n, msg ~= "" and msg or nil)
				or cmd(f, "review", n, "--approve", "--body", msg)
			if run(argv) then
				vim.notify("Approved #" .. n .. " " .. p.title)
			end
		end)
	end)
end

local function request_changes(pr)
	with_pr(pr, function(p, f, n)
		if f.kind == "tea" then
			return gitea(p, function(g, ctx)
				g.submit(ctx, "REQUEST_CHANGES")
			end)
		end
		vim.ui.input({ prompt = "Request changes on #" .. n .. ": " }, function(msg)
			if not msg or msg == "" then
				return
			end
			local argv = f.kind == "tea" and cmd(f, "reject", n, msg)
				or cmd(f, "review", n, "--request-changes", "--body", msg)
			if run(argv) then
				vim.notify("Requested changes on #" .. n)
			end
		end)
	end)
end

local function merge(pr)
	with_pr(pr, function(p, f, n)
		if f.kind == "tea" then
			return gitea(p, function(g, ctx)
				g.merge(ctx)
			end)
		end
		vim.ui.select({ "merge", "squash", "rebase" }, { prompt = "Merge #" .. n .. " " .. p.title }, function(style)
			if not style then
				return
			end
			local argv = f.kind == "tea" and cmd(f, "merge", "--style", style, n) or cmd(f, "merge", n, "--" .. style)
			if run(argv) then
				vim.notify("Merged #" .. n)
			end
		end)
	end)
end

-- Telescope picker: open PRs. <CR> Gitea: the PR buffer (gitea plugin); GitHub: diff in diffview, <C-g> check out then diff, <C-v> view,
-- <C-a> approve, <C-r> request changes, <C-o> browser.
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
					local pr = action_state.get_selected_entry().value
					if pr.forge.kind == "tea" then
						gitea(pr)
					else
						review(pr)
					end
				end)
				for key, fn in pairs({
					["<C-g>"] = checkout,
					["<C-v>"] = view,
					["<C-a>"] = approve,
					["<C-r>"] = request_changes,
					["<C-o>"] = function(pr)
						vim.ui.open(pr.url)
					end,
				}) do
					map({ "i", "n" }, key, function()
						local pr = action_state.get_selected_entry().value
						actions.close(prompt_bufnr)
						fn(pr)
					end)
				end
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
	{ "<leader>gpv", function() view() end, desc = "PR under review: description and comments" },
	{ "<leader>gpa", function() approve() end, desc = "PR under review: approve" },
	{ "<leader>gpx", function() request_changes() end, desc = "PR under review: request changes" },
	{ "<leader>gpm", function() merge() end, desc = "PR under review: merge" },
}

return M
