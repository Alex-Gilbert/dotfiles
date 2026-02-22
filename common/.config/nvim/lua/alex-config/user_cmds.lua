vim.api.nvim_create_user_command("ProcessMarkdown", function()
	-- Replace $...$ with *...*
	vim.cmd([[%s/\$\(.\{-}\)\$/\*\1\*/ge]])

	-- Replace subscripts
	vim.cmd([[%s/_0/₀/ge]])
	vim.cmd([[%s/_1/₁/ge]])
	vim.cmd([[%s/_2/₂/ge]])
	vim.cmd([[%s/_3/₃/ge]])
	vim.cmd([[%s/_4/₄/ge]])
	vim.cmd([[%s/_5/₅/ge]])
	vim.cmd([[%s/_6/₆/ge]])
	vim.cmd([[%s/_7/₇/ge]])
	vim.cmd([[%s/_8/₈/ge]])
	vim.cmd([[%s/_9/₉/ge]])
	vim.cmd([[%s/_i/ᵢ/ge]])
end, { desc = "this was a niche thing to turn latex subtext into markdown" })

vim.api.nvim_create_user_command("AddIncludeGuards", function()
	local filename = vim.fn.expand("%:t") -- Get the current file name
	if filename == "" then
		print("No file name detected. Save the file first.")
		return
	end

	-- Generate a unique macro name based on the file name
	local macro_name = filename:upper():gsub("[^A-Z0-9]", "_") .. "_H"

	-- Read the current buffer content
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	-- Check if guards already exist
	for _, line in ipairs(lines) do
		if line:find("#ifndef " .. macro_name) or line:find("#define " .. macro_name) then
			print("Include guards already present.")
			return
		end
	end

	-- Add the include guards
	table.insert(lines, 1, "#ifndef " .. macro_name)
	table.insert(lines, 2, "#define " .. macro_name)
	table.insert(lines, "#endif -- " .. macro_name)

	-- Write the updated content back to the buffer
	vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

	print("Include guards added.")
end, { desc = "Add include guards to the current file" })

vim.api.nvim_create_user_command("ObsTaskCreate", function()
	-- Get the current line
	local line = vim.api.nvim_get_current_line()

	-- Check if the line is already a task
	if line:match("^%s*%-%s*%[%s*[%s%+xX]%s*%]") then
		print("Line is already a task")
		return
	end

	-- Remove leading whitespace for processing
	local indentation = line:match("^(%s*)")
	local content = line:gsub("^%s*", "")

	-- Don't convert empty lines
	if content == "" then
		print("Cannot convert empty line to task")
		return
	end

	-- Create task format: "- [ ] task content"
	local task_line = indentation .. "- [ ] " .. content

	-- Replace the current line with the task line
	vim.api.nvim_set_current_line(task_line)
	print("Converted line to task")
end, { desc = "make a line in an obsidian note a task" })

vim.api.nvim_create_user_command("ObsTaskID", function()
	-- Get the current line
	local line = vim.api.nvim_get_current_line()

	-- Check if the line is a task
	if not line:match("^%s*%-%s*%[%s*[%s%+xX]%s*%]") then
		print("Current line is not a task")
		return
	end

	-- Generate a task ID in the format "🆔 9562kk" (emoji + space + 6 alphanumeric chars)
	-- This creates a shorter, more readable ID format as requested
	local function generate_task_id()
		local chars = "0123456789abcdefghijklmnopqrstuvwxyz"
		local id = ""

		-- Generate 6 random alphanumeric characters
		for _ = 1, 6 do
			local rand_index = math.random(1, #chars)
			id = id .. string.sub(chars, rand_index, rand_index)
		end

		-- Return the ID with the ID emoji prefix
		return "🆔 " .. id
	end

	local task_id = generate_task_id()

	-- Check if the task already has an ID
	if line:match("🆔%s+[%w]+") then
		-- Replace the existing ID
		line = line:gsub("(🆔%s+[%w]+)", task_id)
	else
		-- Append the ID at the end of the line
		line = line .. " " .. task_id
	end

	-- Update the current line
	vim.api.nvim_set_current_line(line)
	print("Added ID to task: " .. task_id)
end, { desc = "make a line in an obsidian note a task" })

vim.api.nvim_create_user_command("ObsTaskDue", function()
	-- Get the current line
	local line = vim.api.nvim_get_current_line()

	-- Check if the line is a task
	if not line:match("^%s*%-%s*%[%s*[%s%+xX]%s*%]") then
		print("Current line is not a task")
		return
	end

	-- Prompt the user for number of days from now
	vim.ui.input({
		prompt = "Due in how many days? (0 for today, 1 for tomorrow, etc.): ",
		default = "1", -- Default to tomorrow
	}, function(days_input)
		-- Early return if user cancels the prompt
		if not days_input then
			print("Date addition cancelled")
			return
		end

		-- Convert input to number and validate
		local days = tonumber(days_input)
		if not days then
			print("Invalid input: Please enter a number")
			return
		end

		-- Get the future date in YYYY-MM-DD format
		local function get_future_date(days_offset)
			-- Get current time and add the specified days (86400 seconds per day)
			local current_time = os.time()
			local future_time = current_time + (days_offset * 86400)

			-- Format the date as YYYY-MM-DD
			return os.date("%Y-%m-%d", future_time)
		end

		local future_date = get_future_date(days)
		local date_tag = "📅 " .. future_date

		-- Check if the task already has a date tag
		if line:match("📅%s+%d%d%d%d%-%d%d%-%d%d") then
			-- Replace the existing date
			line = line:gsub("(📅%s+%d%d%d%d%-%d%d%-%d%d)", date_tag)
		else
			-- Append the date at the end of the line
			line = line .. " " .. date_tag
		end

		-- Update the current line
		vim.api.nvim_set_current_line(line)

		-- Provide meaningful feedback based on the input
		if days == 0 then
			print("Added today's date to task: " .. future_date)
		elseif days == 1 then
			print("Added tomorrow's date to task: " .. future_date)
		else
			print("Added date " .. days .. " days from now to task: " .. future_date)
		end
	end)
end, { desc = "Set a due date for an obsidian task" })

vim.api.nvim_create_user_command("ObsTaskPriority", function()
	-- Get the current line
	local line = vim.api.nvim_get_current_line()

	-- Check if the line is a task
	if not line:match("^%s*%-%s*%[%s*[%s%+xX]%s*%]") then
		print("Current line is not a task")
		return
	end

	-- Define priority levels and their corresponding emojis
	local priorities = {
		["1"] = "🔽", -- Low
		["2"] = "🔼", -- Medium (default)
		["3"] = "⏫", -- High
		["4"] = "🔺", -- Highest
	}

	-- Create the prompt message
	local prompt_message = "Select priority level:\n"
		.. "1 - Low (🔽)\n"
		.. "2 - Medium (🔼)\n"
		.. "3 - High (⏫)\n"
		.. "4 - Highest (🔺)\n"
		.. "Priority (1-4): "

	-- Prompt the user for priority level
	vim.ui.input({
		prompt = prompt_message,
		default = "2", -- Default to Medium
	}, function(priority_input)
		-- Early return if user cancels the prompt
		if not priority_input then
			print("Priority setting cancelled")
			return
		end

		-- Validate input and get the corresponding emoji
		local priority_emoji = priorities[priority_input]
		if not priority_emoji then
			print("Invalid input: Please enter a number between 1 and 4")
			return
		end

		-- Check if the task already has a priority emoji
		if line:match("[🔽🔼⏫🔺]") then
			-- Replace the existing priority
			line = line:gsub("([🔽🔼⏫🔺])", priority_emoji)
		else
			-- Add priority after the task marker but before the task text
			local prefix, rest = line:match("^(%s*%-%s*%[%s*[%s%+xX]%s*%])(.*)$")
			if prefix and rest then
				line = prefix .. " " .. priority_emoji .. rest
			end
		end

		-- Update the current line
		vim.api.nvim_set_current_line(line)

		-- Provide feedback
		local priority_names = {
			["🔽"] = "Low",
			["🔼"] = "Medium",
			["⏫"] = "High",
			["🔺"] = "Highest",
		}
		print("Set task priority to " .. priority_names[priority_emoji] .. " (" .. priority_emoji .. ")")
	end)
end, { desc = "set the priority on an obsidian task" })
