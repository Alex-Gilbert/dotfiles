-- Run from dotfiles (full config, container running):
--   DOCKER_CP_TEST=<container> nvim --headless -i NONE -c "luafile scripts/tests/test_oil_docker.lua" -c qa
local c = assert(os.getenv("DOCKER_CP_TEST"), "set DOCKER_CP_TEST=<running container>")
local oil = require("oil")
local function wait(what, fn) assert(vim.wait(15000, fn, 50), "timed out: " .. what) end
local function sh(cmd) return vim.trim(vim.system({ "docker", "exec", c, "sh", "-c", cmd }, { text = true }):wait().stdout) end

sh("rm -rf /tmp/oiltest && mkdir /tmp/oiltest && echo hello > /tmp/oiltest/a.txt && chmod 644 /tmp/oiltest/a.txt")

-- listing
oil.open("oil-docker://" .. c .. "/tmp/oiltest/")
wait("listing", function() return vim.bo.filetype == "oil" and oil.get_entry_on_line(0, 1) ~= nil end)
assert(oil.get_entry_on_line(0, 1).name == "a.txt", "expected a.txt in listing")

-- <leader>Dp resolves the oil cursor entry
vim.api.nvim_win_set_cursor(0, { 1, 0 })
local sc, sp = require("alex-config.docker-cp").source_from_buffer()
assert(sc == c and sp == "/tmp/oiltest/a.txt", "oil source: " .. tostring(sc) .. " " .. tostring(sp))

-- open + edit + save a file, mode preserved
vim.cmd.edit("oil-docker://" .. c .. "/tmp/oiltest/a.txt")
local buf = vim.api.nvim_get_current_buf()
wait("read", function() return vim.api.nvim_buf_get_lines(buf, 0, -1, false)[1] == "hello" end)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "edited", "twice" })
vim.cmd.write()
wait("write", function() return sh("cat /tmp/oiltest/a.txt") == "edited\ntwice" end)
assert(sh("stat -c %a /tmp/oiltest/a.txt") == "644", "write changed file mode")

-- cross-adapter copy container -> local disk (the oil yank/paste/:w flow)
local dest = vim.fn.tempname()
vim.fn.mkdir(dest, "p")
local mutator = require("oil.mutator")
local done
mutator.process_actions({ { type = "copy", entry_type = "file",
	src_url = "oil-docker://" .. c .. "/tmp/oiltest/a.txt", dest_url = "oil://" .. dest .. "/a.txt" } },
	function(err) done = err or true end)
wait("copy out", function() return done ~= nil end)
assert(done == true, "copy failed: " .. tostring(done))
assert(vim.fn.readfile(dest .. "/a.txt")[1] == "edited", "copied file content wrong")

sh("rm -rf /tmp/oiltest")
print("ok")
