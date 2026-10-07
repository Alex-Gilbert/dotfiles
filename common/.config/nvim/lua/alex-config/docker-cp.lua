-- docker cp helpers around dockyard.nvim (which can browse container files but not pull them to the host)
local M = {}

local function running_containers()
	local out = vim.system({ "docker", "ps", "--format", "{{.Names}}" }, { text = true }):wait()
	return out.code == 0 and vim.split(vim.trim(out.stdout), "\n", { trimempty = true }) or {}
end

local function pick_container(cb)
	local names = running_containers()
	if #names == 0 then
		return vim.notify("No running containers", vim.log.levels.WARN)
	end
	vim.ui.select(names, { prompt = "Container" }, function(c)
		if c then
			cb(c)
		end
	end)
end

-- Work out {container, path} from where the cursor is: an open dockyard:// file, or the dockyard file browser.
function M.source_from_buffer()
	local name = vim.api.nvim_buf_get_name(0)
	local container, path = name:match("^dockyard://([^/]+)(/.*)$")
	if not container then
		container, path = name:match("^oil%-docker://([^/]+)(/.*)$")
		local entry = vim.bo.filetype == "oil" and container and require("oil").get_cursor_entry()
		if entry then
			path = path .. entry.name
		end
	end
	if container then
		return container, path
	end
	if vim.bo.filetype == "dockyard-files" then
		container = vim.api.nvim_buf_get_name(0):match("^dockyard://([^/]+)$")
		-- reuse the browser's own `y` (yank path) so we don't parse its table layout
		local yank = vim.fn.maparg("y", "n", false, true).callback
		if container and yank then
			local saved = vim.fn.getreg('"')
			yank()
			path = vim.fn.getreg('"')
			vim.fn.setreg('"', saved)
			return container, path
		end
	end
end

function M.copy(container, src, dest)
	vim.system({ "docker", "cp", container .. ":" .. src, dest }, { text = true }, function(res)
		vim.schedule(function()
			if res.code == 0 then
				vim.notify(("Copied %s:%s -> %s"):format(container, src, dest))
			else
				vim.notify("docker cp failed: " .. vim.trim(res.stderr), vim.log.levels.ERROR)
			end
		end)
	end)
end

-- Pull a file/dir out of a running container to the host.
function M.pull()
	local function ask_dest(container, src)
		local default = vim.fn.getcwd() .. "/" .. vim.fs.basename(src)
		vim.ui.input({ prompt = "Copy to: ", default = default, completion = "file" }, function(dest)
			if dest and dest ~= "" then
				M.copy(container, src, vim.fn.expand(dest))
			end
		end)
	end
	local container, src = M.source_from_buffer()
	if container then
		return ask_dest(container, src)
	end
	pick_container(function(c)
		vim.ui.input({ prompt = c .. ":" }, function(p)
			if p and p ~= "" then
				ask_dest(c, p)
			end
		end)
	end)
end

function M.browse()
	pick_container(function(c)
		require("dockyard.files").open(c, "/")
	end)
end

-- Browse a running container in oil
function M.oil()
	pick_container(function(c)
		require("oil").open("oil-docker://" .. c .. "/")
	end)
end

-- Images aren't running, so start a throwaway idle container from one and browse that.
-- ponytail: needs /bin/sh in the image (no distroless/scratch)
local scratch = {}
function M.oil_image()
	local out = vim.system({ "docker", "images", "--format", "{{.Repository}}:{{.Tag}}" }, { text = true }):wait()
	local images = vim.tbl_filter(function(i)
		return not i:find("<none>", 1, true)
	end, vim.split(out.stdout or "", "\n", { trimempty = true }))
	vim.ui.select(images, { prompt = "Image" }, function(image)
		if not image then
			return
		end
		local name = scratch[image] or ("oil-img-%s-%d"):format((image:gsub("[^%w_.-]", "_")), vim.fn.getpid())
		local function open()
			scratch[image] = name
			require("oil").open("oil-docker://" .. name .. "/")
		end
		if scratch[image] then
			return open()
		end
		vim.notify("Starting scratch container for " .. image)
		local cmd = { "docker", "run", "-d", "--rm", "--name", name, "--entrypoint", "/bin/sh", image, "-c", "while :; do sleep 3600; done" }
		vim.system(cmd, { text = true }, vim.schedule_wrap(function(res)
			if res.code ~= 0 then
				return vim.notify("docker run failed: " .. vim.trim(res.stderr), vim.log.levels.ERROR)
			end
			open()
		end))
	end)
end

vim.api.nvim_create_autocmd("VimLeavePre", {
	callback = function()
		local names = vim.tbl_values(scratch)
		if #names > 0 then
			vim.system(vim.list_extend({ "docker", "rm", "-f" }, names)):wait()
		end
	end,
})

function M.shell()
	pick_container(function(c)
		Snacks.terminal({ "docker", "exec", "-it", c, "sh", "-c", "command -v bash >/dev/null && exec bash || exec sh" })
	end)
end

return M
