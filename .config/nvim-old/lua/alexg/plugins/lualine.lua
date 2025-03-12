local function buffer_name()
    local mode = "%-5{%v:lua.vim.fn.expand(\"%:.\")%}"
    local buf_nr = "[%n]"

    return string.format(
        "%s%s",
        mode,
        buf_nr
    )
end

local function jsonpath()
    local jsonpath = require('jsonpath')
    local jsonpath_str = jsonpath.get()

    return string.format(" %s", jsonpath_str)
end

function lualine_config()
    require('lualine').setup {
        options = {
            icons_enabled = true,
            theme = 'ayu_mirage',
            component_separators = { left = '', right = '' },
            section_separators = { left = '', right = '' },
            disabled_filetypes = {
                statusline = {},
                winbar = {},
            },
            ignore_focus = {},
            always_divide_middle = true,
            globalstatus = false,
            refresh = {
                statusline = 1000,
                tabline = 1000,
                winbar = 1000,
            }
        },
        sections = {
            lualine_a = { 'mode' },
            lualine_b = { 'branch', 'diff', 'diagnostics' },
            lualine_c = { 'filename', jsonpath },
            lualine_x = { 'encoding', 'fileformat', 'filetype' },
            lualine_y = { 'progress' },
            lualine_z = { 'location' }
        },
        inactive_sections = {
            lualine_a = {},
            lualine_b = {},
            lualine_c = { 'filename' },
            lualine_x = { 'location' },
            lualine_y = {},
            lualine_z = {}
        },
        tabline = {},
        winbar = {
            lualine_a = {},
            lualine_b = {},
            lualine_c = {buffer_name},
            lualine_x = {},
            lualine_y = {},
            lualine_z = {}
        },

        inactive_winbar = {
            lualine_a = {},
            lualine_b = {},
            lualine_c = {{buffer_name}},
            lualine_x = {},
            lualine_y = {},
            lualine_z = {}
        },
        extensions = {}
    }
end

return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = lualine_config,
}
