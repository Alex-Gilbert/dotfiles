-- Gitea pull requests in Neovim, after octo.nvim: a PR buffer (description, CI, reviews,
-- comments), diffview with the review threads inline, and line comments held as a pending
-- review until you send them together with Comment, Approve or Request changes.
--
-- A ctx is one PR: { login, slug = "owner/repo", remote, number } plus what load() fetches.
local api = require("gitea.api")
local M = {}

local ns = vim.api.nvim_create_namespace("gitea")
local ERROR, WARN = vim.log.levels.ERROR, vim.log.levels.WARN
local state_dir = vim.fn.stdpath("state") .. "/gitea"
local EVENTS = {
	{ event = "COMMENT", label = "Comment" },
	{ event = "APPROVED", label = "Approve" },
	{ event = "REQUEST_CHANGES", label = "Request changes" },
}

M.current = nil -- the PR open in diffview, for the <leader>gr keys

local function notify(msg, level)
	vim.notify(msg, level or vim.log.levels.INFO, { title = "Gitea" })
end

local function ep(ctx, path)
	return ("repos/%s/pulls/%d%s"):format(ctx.slug, ctx.number, path or "")
end

local function split(s)
	return vim.split((s or ""):gsub("\r", ""), "\n", { plain = true })
end

local function when(t)
	return ((t or ""):sub(1, 16):gsub("T", " "))
end

-- Pending comments live on disk until sent, so a crash or :qa does not lose a review.
local function pending_file(ctx)
	return ("%s/%s-%d.json"):format(state_dir, ctx.slug:gsub("/", "-"), ctx.number)
end

local function load_pending(ctx)
	local f = io.open(pending_file(ctx))
	if not f then
		return {}
	end
	local ok, data = pcall(vim.json.decode, f:read("a"))
	f:close()
	return ok and data or {}
end

local function save_pending(ctx)
	vim.fn.mkdir(state_dir, "p")
	if #ctx.pending == 0 then
		os.remove(pending_file(ctx))
		return
	end
	local f = assert(io.open(pending_file(ctx), "w"))
	f:write(vim.json.encode(ctx.pending))
	f:close()
end

local function load(ctx)
	local d, err = api.batch(ctx.login, {
		pr = ep(ctx),
		reviews = ep(ctx, "/reviews"),
		comments = ("repos/%s/issues/%d/comments"):format(ctx.slug, ctx.number),
	})
	if not d then
		return notify(err, ERROR)
	end
	-- the second round needs the head sha and the review ids from the first
	local more = { status = ("repos/%s/commits/%s/status"):format(ctx.slug, d.pr.head.sha) }
	for _, r in ipairs(d.reviews) do
		if (r.comments_count or 0) > 0 then
			more["r" .. r.id] = ep(ctx, "/reviews/" .. r.id .. "/comments")
		end
	end
	local d2, err2 = api.batch(ctx.login, more)
	if not d2 then
		return notify(err2, ERROR)
	end
	ctx.pr, ctx.reviews, ctx.issue_comments, ctx.status = d.pr, d.reviews, d.comments, d2.status
	ctx.threads = {}
	for _, r in ipairs(d.reviews) do
		r.threads = d2["r" .. r.id] or {}
		for _, c in ipairs(r.threads) do
			-- Gitea: position is the line in the new file, original_position the line in the old one
			c.side = (c.position or 0) > 0 and "new" or "old"
			c.line = c.side == "new" and c.position or c.original_position
			c.state = r.state
			table.insert(ctx.threads, c)
		end
	end
	ctx.pending = ctx.pending or load_pending(ctx)
	return true
end

-- A markdown buffer to write a comment in. :w sends it; q closes without sending.
-- on_send returns false when sending failed, and the text stays for another try.
local function compose(title, on_send)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].buftype = "acwrite"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].filetype = "markdown"
	vim.api.nvim_buf_set_name(buf, "gitea://compose/" .. buf)
	local w, h = math.min(90, vim.o.columns - 4), math.min(14, vim.o.lines - 6)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = w,
		height = h,
		row = math.floor((vim.o.lines - h) / 2),
		col = math.floor((vim.o.columns - w) / 2),
		border = "rounded",
		title = " " .. title .. " · :w sends · q cancels ",
		title_pos = "center",
	})
	vim.api.nvim_create_autocmd("BufWriteCmd", {
		buffer = buf,
		callback = function()
			local text = vim.trim(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"))
			if on_send(text) ~= false then
				vim.bo[buf].modified = false
				vim.api.nvim_win_close(win, true)
			end
		end,
	})
	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(win, true)
	end, { buffer = buf })
	vim.cmd.startinsert()
end

---------------------------------------------------------------------------
-- The PR buffer
---------------------------------------------------------------------------

local HELP = "d diff · c comment · s review · a approve · x request changes · m merge · C checkout · o browser · R refresh · q close"

local function render(ctx)
	local pr, L = ctx.pr, {}
	local function add(...)
		for _, s in ipairs({ ... }) do
			vim.list_extend(L, split(s))
		end
	end
	local state = pr.merged and "merged" or pr.state
	add(
		("# #%d %s"):format(pr.number, pr.title),
		"",
		("**%s** · @%s wants to merge `%s` into `%s`"):format(state, pr.user.login, pr.head.ref, pr.base.ref),
		("CI **%s** · mergeable **%s** · %s"):format(
			(ctx.status.total_count or 0) > 0 and ctx.status.state or "none",
			pr.mergeable and "yes" or "no",
			pr.html_url
		)
	)
	for _, s in ipairs(ctx.status.statuses or {}) do
		add(("- %s: **%s** %s"):format(s.context, s.status, s.target_url or ""))
	end

	-- each reviewer's latest verdict
	local verdict, order = {}, {}
	for _, r in ipairs(ctx.reviews) do
		if r.state ~= "COMMENT" and r.state ~= "PENDING" and not r.dismissed then
			if not verdict[r.user.login] then
				table.insert(order, r.user.login)
			end
			verdict[r.user.login] = r.state .. (r.stale and " (stale)" or "")
		end
	end
	if #order > 0 then
		add("", "Reviewers: " .. table.concat(
			vim.tbl_map(function(u)
				return "@" .. u .. " " .. verdict[u]
			end, order),
			" · "
		))
	end

	add("", "---", "", pr.body ~= "" and pr.body or "_No description._")

	-- timeline: conversation comments and reviews, oldest first
	local items = {}
	for _, c in ipairs(ctx.issue_comments) do
		table.insert(items, { t = c.created_at, c = c })
	end
	for _, r in ipairs(ctx.reviews) do
		if r.state ~= "PENDING" then
			table.insert(items, { t = r.submitted_at, r = r })
		end
	end
	table.sort(items, function(a, b)
		return (a.t or "") < (b.t or "")
	end)
	for _, it in ipairs(items) do
		add("", "---", "")
		if it.c then
			add(("### @%s commented · %s"):format(it.c.user.login, when(it.t)), "", it.c.body)
		else
			local r = it.r
			add(("### @%s %s · %s"):format(r.user.login, r.state, when(it.t)))
			if (r.body or "") ~= "" then
				add("", r.body)
			end
			for _, c in ipairs(r.threads) do
				add("", ("> **%s:%d** (%s)"):format(c.path, c.line, c.side))
				for _, l in ipairs(split(c.body)) do
					add("> " .. l)
				end
			end
		end
	end

	if #ctx.pending > 0 then
		add("", "---", "", ("## Your pending review: %d comments (s sends)"):format(#ctx.pending))
		for _, c in ipairs(ctx.pending) do
			add("", ("> **%s:%d** (%s)"):format(c.path, c.line, c.side))
			for _, l in ipairs(split(c.body)) do
				add("> " .. l)
			end
		end
	end
	add("", "---", "", HELP)

	local buf = ctx.buf
	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, L)
	vim.bo[buf].modifiable = false
	vim.bo[buf].modified = false
end

function M.refresh(ctx)
	ctx = ctx or M.current
	if ctx and load(ctx) and ctx.buf and vim.api.nvim_buf_is_valid(ctx.buf) then
		render(ctx)
	end
	M.decorate()
end

local function buffer_keys(ctx)
	local function map(lhs, fn, desc)
		vim.keymap.set("n", lhs, function()
			fn(ctx)
		end, { buffer = ctx.buf, desc = desc, nowait = true })
	end
	map("d", M.diff, "Gitea: review the diff")
	map("c", M.comment, "Gitea: comment on the conversation")
	map("s", M.submit, "Gitea: send review")
	map("a", function(c)
		M.submit(c, "APPROVED")
	end, "Gitea: approve")
	map("x", function(c)
		M.submit(c, "REQUEST_CHANGES")
	end, "Gitea: request changes")
	map("m", M.merge, "Gitea: merge")
	map("C", M.checkout, "Gitea: check out the PR branch")
	map("o", function(c)
		vim.ui.open(c.pr.html_url)
	end, "Gitea: open in browser")
	map("R", M.refresh, "Gitea: refresh")
	map("q", function(c)
		vim.api.nvim_buf_delete(c.buf, { force = true })
	end, "Gitea: close")
end

-- Open the PR buffer. ctx needs login, slug, remote and number.
function M.open(ctx)
	if not load(ctx) then
		return
	end
	local name = ("gitea://%s/pulls/%d"):format(ctx.slug, ctx.number)
	local existing = vim.fn.bufnr(name)
	if existing ~= -1 then
		vim.api.nvim_buf_delete(existing, { force = true })
	end
	ctx.buf = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_buf_set_name(ctx.buf, name)
	vim.bo[ctx.buf].filetype = "markdown"
	vim.bo[ctx.buf].bufhidden = "wipe"
	render(ctx)
	buffer_keys(ctx)
	M.current = ctx
	vim.api.nvim_set_current_buf(ctx.buf)
end

---------------------------------------------------------------------------
-- Actions
---------------------------------------------------------------------------

-- Diff the PR without touching the working tree: Gitea publishes refs/pull/N/head.
function M.diff(ctx)
	local n, pr = tostring(ctx.number), ctx.pr
	local head = ctx.remote .. "/pr/" .. n
	local r = vim.system({
		"git",
		"fetch",
		ctx.remote,
		pr.base.ref,
		"+refs/pull/" .. n .. "/head:refs/remotes/" .. head,
	}, { text = true }):wait()
	if r.code ~= 0 then
		return notify(vim.trim(r.stderr), ERROR)
	end
	M.current = ctx
	vim.cmd("DiffviewOpen " .. ctx.remote .. "/" .. pr.base.ref .. "..." .. head)
end

function M.checkout(ctx)
	local r = vim.system(
		{ "tea", "pulls", "checkout", "--login", ctx.login, "--repo", ctx.slug, tostring(ctx.number) },
		{ text = true }
	):wait()
	if r.code ~= 0 then
		return notify(vim.trim(r.stderr ~= "" and r.stderr or r.stdout), ERROR)
	end
	notify("Checked out #" .. ctx.number)
end

function M.comment(ctx)
	compose("Comment on #" .. ctx.number, function(body)
		if body == "" then
			return false
		end
		local _, err = api.request(ctx.login, ("repos/%s/issues/%d/comments"):format(ctx.slug, ctx.number), "POST", {
			body = body,
		})
		if err then
			notify(err, ERROR)
			return false
		end
		M.refresh(ctx)
	end)
end

-- Send the pending line comments as one review. With no event, ask which.
function M.submit(ctx, event)
	ctx = ctx or M.current
	if not ctx then
		return notify("No Gitea PR open: <leader>gpl picks one", WARN)
	end
	if not event then
		return vim.ui.select(EVENTS, {
			prompt = ("Review #%d (%d pending comments)"):format(ctx.number, #ctx.pending),
			format_item = function(e)
				return e.label
			end,
		}, function(e)
			if e then
				M.submit(ctx, e.event)
			end
		end)
	end
	local label = vim.iter(EVENTS):find(function(e)
		return e.event == event
	end).label
	compose(("%s #%d · %d line comments"):format(label, ctx.number, #ctx.pending), function(body)
		if event ~= "APPROVED" and body == "" and #ctx.pending == 0 then
			notify("Write something: a " .. label:lower() .. " review needs a body", WARN)
			return false
		end
		local comments = vim.tbl_map(function(c)
			return {
				path = c.path,
				body = c.body,
				new_position = c.side == "new" and c.line or 0,
				old_position = c.side == "old" and c.line or 0,
			}
		end, ctx.pending)
		local _, err = api.request(ctx.login, ep(ctx, "/reviews"), "POST", {
			event = event,
			body = body,
			commit_id = ctx.pr.head.sha,
			comments = comments,
		})
		if err then
			notify(err, ERROR)
			return false
		end
		ctx.pending = {}
		save_pending(ctx)
		notify(("%s sent on #%d"):format(label, ctx.number))
		M.refresh(ctx)
	end)
end

function M.merge(ctx)
	ctx = ctx or M.current
	if not ctx then
		return notify("No Gitea PR open: <leader>gpl picks one", WARN)
	end
	vim.ui.select({ "merge", "squash", "rebase", "rebase-merge" }, {
		prompt = ("Merge #%d %s into %s"):format(ctx.number, ctx.pr.title, ctx.pr.base.ref),
	}, function(style)
		if not style then
			return
		end
		local _, err = api.request(ctx.login, ep(ctx, "/merge"), "POST", { Do = style })
		if err then
			return notify(err, ERROR)
		end
		notify(("Merged #%d (%s)"):format(ctx.number, style))
		M.refresh(ctx)
	end)
end

---------------------------------------------------------------------------
-- Threads in diffview
---------------------------------------------------------------------------

-- The diff pane under the cursor: its file path and side ("old" or "new"), or nil.
local function diff_pane(buf)
	local ok, lib = pcall(require, "diffview.lib")
	local view = ok and lib.get_current_view()
	if not (view and view.cur_layout and view.cur_entry) then
		return
	end
	for sym, side in pairs({ a = "old", b = "new" }) do
		local w = view.cur_layout[sym]
		if w and w.file and w.file.bufnr == buf then
			return view.cur_entry.path, side
		end
	end
end

local function decorate_buf(ctx, buf, path, side)
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	local count = vim.api.nvim_buf_line_count(buf)
	local function mark(line, header, hl, body)
		if line < 1 or line > count then
			return
		end
		local virt = { { { "┃ " .. header, hl } } }
		for _, l in ipairs(split(body)) do
			table.insert(virt, { { "┃ " .. l, "Comment" } })
		end
		vim.api.nvim_buf_set_extmark(buf, ns, line - 1, 0, {
			sign_text = "▌",
			sign_hl_group = hl,
			virt_lines = virt,
		})
	end
	for _, c in ipairs(ctx.threads or {}) do
		if c.path == path and c.side == side then
			mark(c.line, ("@%s %s"):format(c.user.login, c.state ~= "COMMENT" and c.state or ""), "DiagnosticInfo", c.body)
		end
	end
	for _, c in ipairs(ctx.pending or {}) do
		if c.path == path and c.side == side then
			mark(c.line, "pending (yours)", "DiagnosticWarn", c.body)
		end
	end
end

-- Draw the threads and pending comments on both panes of the file diffview shows.
function M.decorate()
	local ctx = M.current
	local ok, lib = pcall(require, "diffview.lib")
	local view = ok and lib.get_current_view()
	if not (ctx and view and view.cur_layout and view.cur_entry) then
		return
	end
	for sym, side in pairs({ a = "old", b = "new" }) do
		local w = view.cur_layout[sym]
		local buf = w and w.file and w.file.bufnr
		if buf and vim.api.nvim_buf_is_valid(buf) then
			decorate_buf(ctx, buf, view.cur_entry.path, side)
		end
	end
end

vim.api.nvim_create_autocmd("User", {
	pattern = { "DiffviewDiffBufRead", "DiffviewDiffBufWinEnter" },
	group = vim.api.nvim_create_augroup("gitea_threads", { clear = true }),
	callback = function()
		vim.schedule(M.decorate)
	end,
})

-- Add a line comment to the pending review. In visual mode it sits on the last line and
-- names the range, since Gitea comments hang off one line.
function M.add_comment()
	local ctx = M.current
	if not ctx then
		return notify("No Gitea PR under review: <leader>gpl, then d", WARN)
	end
	local path, side = diff_pane(vim.api.nvim_get_current_buf())
	if not path then
		return notify("Put the cursor in one of the diff panes", WARN)
	end
	local first, last = vim.fn.line("v"), vim.fn.line(".")
	if first > last then
		first, last = last, first
	end
	if vim.fn.mode():find("[vV]") then
		vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
	end
	compose(("%s:%d (%s)"):format(path, last, side), function(body)
		if body == "" then
			return false
		end
		if first ~= last then
			body = ("Lines %d-%d:\n\n%s"):format(first, last, body)
		end
		table.insert(ctx.pending, { path = path, side = side, line = last, body = body })
		save_pending(ctx)
		M.decorate()
		notify(("%d pending comments · <leader>grs sends the review"):format(#ctx.pending))
	end)
end

-- Drop your pending comment on the cursor line.
function M.delete_pending()
	local ctx = M.current
	local path, side = diff_pane(vim.api.nvim_get_current_buf())
	if not (ctx and path) then
		return
	end
	local line = vim.fn.line(".")
	local before = #ctx.pending
	ctx.pending = vim.tbl_filter(function(c)
		return not (c.path == path and c.side == side and c.line == line)
	end, ctx.pending)
	if #ctx.pending < before then
		save_pending(ctx)
		M.decorate()
		notify("Pending comment removed")
	end
end

-- Back to the PR buffer of the PR under review.
function M.show()
	if not M.current then
		return notify("No Gitea PR under review: <leader>gpl picks one", WARN)
	end
	M.open(M.current)
end

M.keys = {
	{ "<leader>grc", M.add_comment, mode = { "n", "x" }, desc = "Gitea review: comment on line(s)" },
	{ "<leader>grd", M.delete_pending, desc = "Gitea review: drop pending comment on line" },
	{ "<leader>grs", function() M.submit() end, desc = "Gitea review: send review" },
	{ "<leader>gra", function() M.submit(nil, "APPROVED") end, desc = "Gitea review: approve" },
	{ "<leader>grx", function() M.submit(nil, "REQUEST_CHANGES") end, desc = "Gitea review: request changes" },
	{ "<leader>grm", function() M.merge() end, desc = "Gitea review: merge" },
	{ "<leader>grp", M.show, desc = "Gitea review: PR description and conversation" },
	{ "<leader>grr", function() M.refresh() end, desc = "Gitea review: refresh threads" },
}

return M
