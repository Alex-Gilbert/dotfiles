local M = {}

M.in_current_dir = function(direction)
    local current_path = vim.fn.expand('%:p')
    local adjusted_path

    -- Determine the split command based on direction
    local split_cmd = ""
    if direction == "left" then
        split_cmd = "vertical leftabove split"
    elseif direction == "down" then
        split_cmd = "split"
    elseif direction == "up" then
        split_cmd = "split"
    elseif direction == "right" then
        split_cmd = "vertical rightbelow split"
    end

    -- Execute the split and terminal commands
    vim.cmd(split_cmd)

    -- Check if it's an Oil buffer and adjust the path
    if current_path:match('^oil://') then
        adjusted_path = current_path:gsub('^oil://', '')
    else
        adjusted_path = vim.fn.expand('%:p:h')
    end
    -- Open terminal and change directory
    vim.cmd('terminal')
    vim.cmd('cd ' .. adjusted_path)

    -- For "up" direction, the terminal needs to be moved to the top
    if direction == "up" then
        vim.cmd('wincmd K')
    end
end

return M
