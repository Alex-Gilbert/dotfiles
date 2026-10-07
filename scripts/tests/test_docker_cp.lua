-- Run from dotfiles (full config, container running):
--   DOCKER_CP_TEST=<container> nvim --headless -i NONE -c "lua require('lazy').load({plugins={'dockyard.nvim'}})" -c "luafile scripts/tests/test_docker_cp.lua" -c qa
local c = assert(os.getenv("DOCKER_CP_TEST"), "set DOCKER_CP_TEST=<running container>")
local cp = require("alex-config.docker-cp")
local dest = vim.fn.tempname()

-- opened dockyard:// file buffer resolves to container + path
vim.api.nvim_buf_set_name(0, "dockyard://" .. c .. "/etc/hostname")
local bc, bp = cp.source_from_buffer()
assert(bc == c and bp == "/etc/hostname", "file buffer source: " .. tostring(bc) .. " " .. tostring(bp))

-- real docker cp lands the file on the host
cp.copy(c, "/etc/hostname", dest)
assert(vim.wait(10000, function() return vim.uv.fs_stat(dest) ~= nil end), "docker cp did not produce " .. dest)

-- dockyard file browser: cursor entry resolves via the plugin's own yank, register restored
require("dockyard.files").open(c, "/etc")
assert(vim.wait(5000, function() return #vim.fn.getline(1, "$") > 3 end), "browser never listed /etc")
vim.fn.cursor(vim.fn.search("hostname"), 1)
vim.fn.setreg('"', "keep")
local fc, fp = cp.source_from_buffer()
assert(fc == c and fp == "/etc/hostname", "browser source: " .. tostring(fc) .. " " .. tostring(fp))
assert(vim.fn.getreg('"') == "keep", "unnamed register clobbered")
print("ok")
