-- Run from dotfiles: nvim --headless -u NONE -i NONE -l scripts/tests/test_octo_attach.lua
vim.opt.rtp:prepend(vim.fn.getcwd() .. "/common/.config/nvim")
local buf = vim.api.nvim_get_current_buf()
local target = {
	bufnr = buf,
	isPullRequest = function() return true end,
	pullRequest = function() return { url = "https://github.com/example/repo/pull/42" } end,
}
local calls, reloads, notices = {}, {}, {}
package.loaded["octo.utils"] = { get_current_buffer = function() return target end }
package.loaded["octo"] = { load_buffer = function(opts) table.insert(reloads, opts.bufnr) end }
vim.notify = function(message) table.insert(notices, message) end
vim.system = function(argv, opts, callback)
	table.insert(calls, { argv = argv, opts = opts, callback = callback })
	return {}
end
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
local path = dir .. "/screen $(literal) shot.png"
vim.fn.writefile({ "test" }, path)
local ok, attach = pcall(require, "alex-config.octo-attach")
assert(ok, "Attachment integration must load: " .. tostring(attach))
local function finish(code, err)
	calls[#calls].callback({ code = code, stdout = "", stderr = err or "" })
	vim.wait(50, function() return false end)
end

vim.bo[buf].modified = true
attach.attach(path)
assert(#calls == 0 and notices[#notices]:find("Save"), "Unsaved edits must block uploads")
vim.bo[buf].modified = false
attach.attach(path .. ".missing")
assert(#calls == 0, "Missing files must not invoke gh")
local valid = target
target = nil
attach.attach(path)
assert(#calls == 0, "Require an Octo PR buffer")
target = valid

attach.attach(path)
assert(vim.deep_equal(calls[1].argv, {
	"gh", "pr", "edit", "https://github.com/example/repo/pull/42", "--attach", path,
}), "Use the open PR URL and literal path; never overwrite its body")
attach.attach(path)
assert(#calls == 1, "Block duplicate uploads")
local other = vim.api.nvim_create_buf(true, false)
vim.api.nvim_set_current_buf(other)
finish(0)
assert(reloads[1] == buf, "Reload the original PR, not the newly focused buffer")
assert(vim.api.nvim_get_current_buf() == other, "Do not steal focus")

vim.api.nvim_set_current_buf(buf)
attach.attach(path)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "new local edit" })
finish(0)
assert(#reloads == 1, "Do not reload over edits made during upload")
assert(vim.api.nvim_buf_get_lines(buf, 0, -1, false)[1] == "new local edit")
assert(notices[#notices]:find("changed"), "Explain why automatic reload was skipped")

vim.bo[buf].modified = false
attach.attach(path)
finish(1, "upload permission denied")
assert(#reloads == 1 and notices[#notices]:find("permission denied"), "Surface gh failure without discarding edits")
attach.attach(path)
finish(0)
assert(#reloads == 2, "Failures must release the upload lock")
vim.fn.delete(dir, "rf")
print("PASS: PR targeting, literal filenames, unsaved edits, async focus/edit safety, duplicate prevention, and failures")
