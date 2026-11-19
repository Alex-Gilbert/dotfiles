-- This machine's theme, from ~/.config/theme/hosts/<short hostname> (see
-- ~/.config/theme/README). apply() runs ~/.config/theme/<theme>.lua.
local M = { theme = "kanagawa", badge = nil }

local dir = vim.fn.expand("~/.config/theme/")
local host = vim.uv.os_gethostname():gsub("%..*$", "")
local file = io.open(dir .. "hosts/" .. host)
if file then
	for line in file:lines() do
		local key, value = line:match("^%s*(%w+)%s+(.-)%s*$")
		if key == "theme" or key == "badge" then
			M[key] = value
		end
	end
	file:close()
end
M.theme = vim.env.HOST_THEME or M.theme

function M.apply()
	local path = dir .. M.theme .. ".lua"
	if not vim.uv.fs_stat(path) then
		path = dir .. "kanagawa.lua"
	end
	dofile(path)
end

return M
