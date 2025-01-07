local utils = require("heirline.utils")
local conditions = require("heirline.conditions")
local lib = require("heirline-components.all")
local harpoon = require("harpoon")

-- The easy way.
local Navic = {
	condition = function()
		return require("nvim-navic").is_available()
	end,
	provider = function()
		return require("nvim-navic").get_location({ highlight = true })
	end,
	update = "CursorMoved",
}

-- Component for displaying the current file
local CurrentBuffer = {
	provider = function()
		local current_file = vim.fn.expand("%:t") or "[No File]"
		local mode = '%-5{%v:lua.vim.fn.expand("%:.")%}'
		return " " .. mode .. " "
	end,

	hl = "Comment",
}

local TablineBufnr = {
	provider = function(self)
		return tostring(self.bufnr) .. "."
	end,
	hl = "Comment",
}

-- we redefine the filename component, as we probably only want the tail and not the relative path
local TablineFileName = {
	provider = function(self)
		-- self.filename will be defined later, just keep looking at the example!
		local filename = self.filename
		filename = filename == "" and "[No Name]" or vim.fn.fnamemodify(filename, ":t")
		return filename
	end,
	hl = function(self)
		return { bold = self.is_active or self.is_visible, italic = true }
	end,
}

-- Here the filename block finally comes together
local TablineFileNameBlock = {
	init = function(self)
		local list = harpoon:list()
		local items = list.items

		self.filename = items[self.bufnr].value
	end,
	hl = function(self)
		if self.is_active then
			return "TabLineSel"
		else
			return "TabLine"
		end
	end,
	TablineBufnr,
	TablineFileName,
}

-- The final touch!
local TablineBufferBlock = utils.surround({ "", " " }, function(self)
	return utils.get_highlight("TabLineSel").bg
end, { TablineFileNameBlock })

local function create_table(n)
	local tbl = {}
	for i = 1, n do
		table.insert(tbl, i)
	end
	return tbl
end

-- and here we go
local BufferLine = {
	init = function(self)
		local harpoon_number = #harpoon:list().items
		self.active_child = false
		local bufs = create_table(harpoon_number)

		self.buffers = bufs
		self.number = harpoon_number

		for i, bufnr in ipairs(bufs) do
			local child = self[i]
			if not (child and child.bufnr == bufnr) then
				self[i] = self:new(TablineBufferBlock, i)
				child = self[i]
				child.bufnr = bufnr
			end

			self.active_child = -1
			child.is_active = false
			child.is_visible = true
		end

		if #self > #bufs then
			for i = #bufs + 1, #self do
				self[i] = nil
			end
		end
	end,
	update = function(self)
		local harpoon_number = #harpoon:list().items
		if self.number ~= harpoon_number then
			return true
		end
		return false
	end,
}

local M = {}

M.Statusline = {
	hl = { fg = "fg", bg = "bg" },
	lib.component.mode(),
	lib.component.git_branch(),
	lib.component.file_info({ file_icon = {}, filetype = false, filename = {}, file_modified = false }),
	Navic,
	lib.component.fill(),
	lib.component.git_diff(),
	lib.component.diagnostics(),
	lib.component.fill(),
	lib.component.cmd_info(),
	lib.component.fill(),
	lib.component.nav(),
	lib.component.mode({ surround = { separator = "right" } }),
}

-- Define the Winbar component
M.TabLine = {
	{
		hl = { fg = "fg", bg = "bg" },
		CurrentBuffer,
		lib.component.fill(),
		BufferLine,
	},
}

return M
