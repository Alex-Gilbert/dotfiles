local M = {}


M.extract_make_targets = function(makefile_path)
    local targets = {}
    for line in io.lines(makefile_path) do
        local target = line:match("^([%w%-%_]+):")
        if target then
            table.insert(targets, target)
        end
    end
    return targets
end

M.telescope = function()
    local makefile_path = vim.fn.getcwd() .. '/Makefile'
    local targets = M.extract_make_targets(makefile_path)

    require('telescope.pickers').new({}, {
        prompt_title = 'Make Targets',
        finder = require('telescope.finders').new_table({
            results = targets,
        }),
        sorter = require('telescope.config').values.generic_sorter({}),
        attach_mappings = function(_, map)
            map('i', '<CR>', function(prompt_bufnr)
                local selection = require('telescope.actions.state').get_selected_entry(prompt_bufnr)
                require('telescope.actions').close(prompt_bufnr)
                local target = selection[1]
                vim.cmd('belowright split | terminal make ' .. target)
            end)
            return true
        end
    }):find()
end

return M
