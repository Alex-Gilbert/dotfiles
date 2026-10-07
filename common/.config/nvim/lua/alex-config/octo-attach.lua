local M = {}
local uploading = {}

function M.attach(path)
	local buffer = require("octo.utils").get_current_buffer()
	if not buffer or not buffer:isPullRequest() then
		vim.notify("Open a PR in Octo first", vim.log.levels.WARN)
		return
	end
	local bufnr = buffer.bufnr
	if vim.bo[bufnr].modified then
		vim.notify("Save your Octo edits with :w before attaching an image", vim.log.levels.WARN)
		return
	end
	if uploading[bufnr] then
		vim.notify("An attachment is already uploading for this buffer", vim.log.levels.WARN)
		return
	end
	if not path or path == "" then
		vim.ui.input({ prompt = "Attach image/video to PR description (uploads now): ", completion = "file" }, function(value)
			if value and value ~= "" and vim.api.nvim_buf_is_valid(bufnr) then
				vim.api.nvim_buf_call(bufnr, function()
					M.attach(value)
				end)
			end
		end)
		return
	end
	path = vim.fn.fnamemodify(vim.fs.normalize(path, { expand_env = false }), ":p")
	if path:find("#", 1, true) then
		vim.notify("Rename the file without #: gh uses # to separate attachment alt text", vim.log.levels.ERROR)
		return
	end
	if vim.fn.filereadable(path) ~= 1 then
		vim.notify("Cannot read attachment: " .. path, vim.log.levels.ERROR)
		return
	end
	local url = buffer:pullRequest().url
	if not url or not url:match("^https://[^/]+/[^/]+/[^/]+/pull/%d+$") then
		vim.notify("Cannot determine the open PR's URL", vim.log.levels.ERROR)
		return
	end
	local tick = vim.api.nvim_buf_get_changedtick(bufnr)
	uploading[bufnr] = true
	vim.notify("Uploading attachment to " .. url)
	local ok, err = pcall(vim.system, { "gh", "pr", "edit", url, "--attach", path }, { text = true }, function(result)
		vim.schedule(function()
			uploading[bufnr] = nil
			if result.code ~= 0 then
				vim.notify("Attachment failed: " .. vim.trim(result.stderr or "") .. "\nCheck the PR before retrying; gh may have updated it.", vim.log.levels.ERROR)
				return
			end
			if not vim.api.nvim_buf_is_valid(bufnr) then
				vim.notify("Attachment uploaded to " .. url)
				return
			end
			if vim.bo[bufnr].modified or vim.api.nvim_buf_get_changedtick(bufnr) ~= tick then
				vim.notify("Attachment uploaded, but the buffer changed. Copy your edits, then :Octo pr reload before saving again.", vim.log.levels.WARN)
				return
			end
			require("octo").load_buffer({ bufnr = bufnr })
			vim.notify("Attachment uploaded to PR description")
		end)
	end)
	if not ok then
		uploading[bufnr] = nil
		vim.notify("Could not start gh: " .. tostring(err), vim.log.levels.ERROR)
	end
end

return M
