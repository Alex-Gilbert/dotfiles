-- Gitea REST through `tea api`: tea holds the token, so nothing here does auth.
local M = {}

local function argv(login, endpoint, method, body)
	local a = { "tea", "api", "--login", login }
	if method then
		vim.list_extend(a, { "-X", method })
	end
	if body then
		vim.list_extend(a, { "-d", "@-" })
	end
	table.insert(a, endpoint)
	return a
end

-- tea api exits 0 on HTTP errors and prints {"message": ..., "url": ".../api/swagger"}.
local function decode(r)
	if r.code ~= 0 then
		return nil, vim.trim(r.stderr ~= "" and r.stderr or r.stdout)
	end
	if vim.trim(r.stdout) == "" then
		return {}
	end
	local ok, data = pcall(vim.json.decode, r.stdout, { luanil = { object = true, array = true } })
	if not ok then
		return nil, "tea api sent something that is not JSON: " .. r.stdout:sub(1, 200)
	end
	if type(data) == "table" and data.message and type(data.url) == "string" and data.url:find("swagger") then
		return nil, data.message
	end
	return data
end

function M.start(login, endpoint, method, body)
	return vim.system(argv(login, endpoint, method, body), {
		text = true,
		stdin = body and vim.json.encode(body) or nil,
	})
end

function M.wait(job)
	return decode(job:wait())
end

function M.request(login, endpoint, method, body)
	return M.wait(M.start(login, endpoint, method, body))
end

-- Several GETs at once: { key = endpoint } -> { key = data }, or nil and the first error.
function M.batch(login, endpoints)
	local jobs, out = {}, {}
	for key, endpoint in pairs(endpoints) do
		jobs[key] = { M.start(login, endpoint), endpoint }
	end
	for key, j in pairs(jobs) do
		local data, err = M.wait(j[1])
		if not data then
			return nil, j[2] .. ": " .. err
		end
		out[key] = data
	end
	return out
end

return M
