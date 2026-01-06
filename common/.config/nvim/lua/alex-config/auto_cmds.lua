local M = {}

-- Store original cursorline highlight
local original_cursorline = nil

M.set_base_autocmds = function()
	vim.api.nvim_create_autocmd("TextYankPost", {
		desc = "Highlight when yanking (copying) text",
		group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
		callback = function()
			vim.highlight.on_yank()
		end,
	})

	-- Macro recording visual feedback
	local macro_group = vim.api.nvim_create_augroup("macro-recording", { clear = true })

	vim.api.nvim_create_autocmd("RecordingEnter", {
		desc = "Visual feedback when recording macro",
		group = macro_group,
		callback = function()
			-- Get kanagawa colors (samuraiRed for recording)
			local colors = require("kanagawa.colors").setup({ theme = "wave" })
			local palette = colors.palette

			-- Save current cursorline
			original_cursorline = vim.api.nvim_get_hl(0, { name = "CursorLine" })

			-- Set red cursorline while recording
			vim.api.nvim_set_hl(0, "CursorLine", {
				bg = palette.samuraiRed,
				fg = palette.sumiInk0,
				bold = true,
			})

			-- Notify
			vim.notify(
				"Recording @" .. vim.fn.reg_recording(),
				vim.log.levels.WARN,
				{ title = "Macro", timeout = 2000 }
			)
		end,
	})

	vim.api.nvim_create_autocmd("RecordingLeave", {
		desc = "Restore cursorline after recording macro",
		group = macro_group,
		callback = function()
			-- Restore original cursorline
			if original_cursorline ~= nil then
				vim.api.nvim_set_hl(0, "CursorLine", original_cursorline)
			end

			-- Notify with recorded register
			vim.schedule(function()
				vim.notify(
					"Recorded @" .. vim.fn.reg_recorded(),
					vim.log.levels.INFO,
					{ title = "Macro", timeout = 2000 }
				)
			end)
		end,
	})
end

M.set_lsp_autocmds = function(event, client)
	if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
		local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
		vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
			buffer = event.buf,
			group = highlight_augroup,
			callback = vim.lsp.buf.document_highlight,
		})

		vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
			buffer = event.buf,
			group = highlight_augroup,
			callback = vim.lsp.buf.clear_references,
		})

		vim.api.nvim_create_autocmd("LspDetach", {
			group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
			callback = function(event2)
				vim.lsp.buf.clear_references()
				vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
			end,
		})
	end
end

return M
