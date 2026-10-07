-- oil.nvim adapter for running containers: oil-docker://<container>/<abs path>
-- Reuses oil's ssh filesystem layer (a persistent shell running ls/mv/rm/cp), but the shell is
-- `docker exec -it <container>` instead of ssh, and file transfer is `docker cp` instead of scp.
-- ponytail: leans on oil's undocumented ssh internals; if an oil update breaks this, fork ssh.lua.
local config = require("oil.config")
local files = require("oil.adapters.files")
local fs = require("oil.fs")
local loading = require("oil.loading")
local pathutil = require("oil.pathutil")
local shell = require("oil.shell")
local SSHConnection = require("oil.adapters.ssh.connection")
local sshfs = require("oil.adapters.ssh.sshfs")
local util = require("oil.util")

local create_ssh_command = SSHConnection.create_ssh_command
SSHConnection.create_ssh_command = function(url)
	if url.docker then
		return { "docker", "exec", "-it", url.host }
	end
	return create_ssh_command(url)
end

local M = {}

M.parse_url = function(oil_url)
	local scheme, rest = util.parse_url(oil_url)
	local host, path = (rest or ""):match("^([^/]+)(.*)$")
	if not host then
		error("Malformed docker url: " .. oil_url)
	end
	return { scheme = scheme, host = host, path = path }
end

local function url_to_str(url)
	return url.scheme .. url.host .. url.path
end

-- `docker cp` endpoint for an oil url (docker or local files)
local function cp_arg(oil_url)
	if config.get_adapter_by_scheme(oil_url) == M then
		local res = M.parse_url(oil_url)
		return res.host .. ":" .. res.path
	end
	local _, path = util.parse_url(oil_url)
	return fs.posix_to_os_path(assert(path))
end

local _connections = {}
local function get_connection(url, allow_retry)
	local host = M.parse_url(url).host
	local conn = _connections[host]
	if not conn or (allow_retry and conn:get_connection_error()) then
		conn = sshfs.new({ scheme = "oil-docker://", host = host, path = "", docker = true })
		_connections[host] = conn
	end
	return conn
end

M.get_column = function(name)
	if name == "size" then
		return require("oil.adapters.ssh").get_column(name)
	end
end

M.get_parent = function(bufname)
	local res = M.parse_url(bufname)
	res.path = pathutil.parent(res.path)
	return url_to_str(res)
end

M.normalize_url = function(url, callback)
	local res = M.parse_url(url)
	get_connection(url, true):realpath(res.path == "" and "/" or res.path, function(err, abspath)
		if not err then
			res.path = abspath
		end
		callback(url_to_str(res))
	end)
end

M.list = function(url, column_defs, callback)
	get_connection(url):list_dir(url, M.parse_url(url).path, callback)
end

M.is_modifiable = function()
	return true
end

M.render_action = function(action)
	if action.type == "create" or action.type == "delete" then
		return string.format("%s %s", action.type:upper(), action.url)
	end
	return string.format("  %s %s -> %s", action.type:upper(), cp_arg(action.src_url), cp_arg(action.dest_url))
end

M.perform_action = function(action, cb)
	if action.type == "create" then
		local res = M.parse_url(action.url)
		local conn = get_connection(action.url)
		if action.entry_type == "directory" then
			conn:mkdir(res.path, cb)
		elseif action.entry_type == "link" and action.link then
			conn:mklink(res.path, action.link, cb)
		else
			conn:touch(res.path, cb)
		end
	elseif action.type == "delete" then
		get_connection(action.url):rm(M.parse_url(action.url).path, cb)
	elseif action.type == "move" or action.type == "copy" then
		local both_docker = config.get_adapter_by_scheme(action.src_url) == M
			and config.get_adapter_by_scheme(action.dest_url) == M
		if not both_docker then
			-- container <-> local disk (oil only asks for "copy" here, see supported_cross_adapter_actions)
			return shell.run({ "docker", "cp", cp_arg(action.src_url), cp_arg(action.dest_url) }, cb)
		end
		local src, dest = M.parse_url(action.src_url), M.parse_url(action.dest_url)
		if src.host ~= dest.host then
			return cb("Copying between containers isn't supported; go via a local directory")
		end
		local conn = get_connection(action.src_url)
		if action.type == "move" then
			conn:mv(src.path, dest.path, cb)
		else
			conn:cp(src.path, dest.path, cb)
		end
	else
		cb("Bad action type: " .. action.type)
	end
end

M.supported_cross_adapter_actions = { files = "copy" }

local function tmpfile()
	local dir = fs.join(vim.fn.stdpath("cache"), "oil")
	fs.mkdirp(dir)
	local fd, path = vim.uv.fs_mkstemp(fs.join(dir, "docker_XXXXXX"))
	if fd then
		vim.uv.fs_close(fd)
	end
	return path
end

M.read_file = function(bufnr)
	loading.set_loading(bufnr, true)
	local bufname = vim.api.nvim_buf_get_name(bufnr)
	local tmp = tmpfile()
	shell.run({ "docker", "cp", cp_arg(bufname), tmp }, function(err)
		loading.set_loading(bufnr, false)
		vim.bo[bufnr].modifiable = true
		vim.cmd.doautocmd({ args = { "BufReadPre", bufname }, mods = { silent = true } })
		if err then
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, vim.split(err, "\n"))
		else
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, vim.fn.readfile(tmp, "b"))
		end
		vim.uv.fs_unlink(tmp)
		vim.bo[bufnr].modified = false
		local ft = vim.filetype.match({ buf = bufnr, filename = pathutil.basename(bufname) })
		if ft then
			vim.bo[bufnr].filetype = ft
		end
		vim.cmd.doautocmd({ args = { "BufReadPost", bufname }, mods = { silent = true } })
	end)
end

M.write_file = function(bufnr)
	local bufname = vim.api.nvim_buf_get_name(bufnr)
	local res = M.parse_url(bufname)
	vim.cmd.doautocmd({ args = { "BufWritePre", bufname }, mods = { silent = true } })
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
	-- stream through `cat >` rather than `docker cp` so the file keeps its owner and mode
	local cmd = { "docker", "exec", "-i", res.host, "sh", "-c", 'cat > "$1"', "sh", res.path }
	vim.system(cmd, { stdin = table.concat(lines, "\n") .. "\n" }, vim.schedule_wrap(function(out)
		if out.code ~= 0 then
			return vim.notify("Error writing file: " .. out.stderr, vim.log.levels.ERROR)
		end
		vim.bo[bufnr].modified = false
		vim.cmd.doautocmd({ args = { "BufWritePost", bufname }, mods = { silent = true } })
	end))
end

return M
