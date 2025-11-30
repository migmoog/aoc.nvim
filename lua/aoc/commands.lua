local M = {}

local function input_fname (day, year)
	return string.format("/d%d_%d.txt", day, year)
end

local function download_input (api, day, year, inputs_dir)
	if vim.fn.isdirectory(inputs_dir) == 0 then
		vim.fn.mkdir(inputs_dir)
	end

	local challenge_input = api.get_challenge_input(day, year)
	local fname = inputs_dir .. input_fname(day, year)
	vim.fn.writefile({ challenge_input }, fname)
end

local function has_input (day, year, inputs_dir)
	return vim.fn.filereadable(inputs_dir .. input_fname(day, year)) == 1
end

M.has_input = has_input

function M.download_input (day, year, inputs_dir)
	return download_input(require "aoc.api", day, year, inputs_dir)
end

function M.load_input (day, year, inputs_dir)
	local lines = vim.fn.readfile(inputs_dir .. input_fname(day, year))
	local input = ""
	local i = 1
	while i < #lines do
		input = input .. lines[i] .. "\n"
	end
	input = input .. lines[#lines]

	return input
end

---Opens the challenge for a specific day and downloads the user's input
---@param day integer The day index of the challenge. [1, 25] if doing years [2015, 2025). Otherwise it's [1, 12]
---@param year integer The year index of the challenge. Challenges are from 2015 onward.
---@param inputs_dir string The path where the input files will be saved.
function M.pull_up_challenge (day, year, inputs_dir)
	local api = require "aoc.api"
	if not api.is_logged_in() then
		Err "Cannot send request without cookie"
		return
	end

	if not has_input(day, year, inputs_dir) then
		download_input(api, day, year, inputs_dir)
	end
	api.open_challenge_info(day, year)
end

---Runs a command with vim.system with arguments about the year and challenge.
---@param day integer
---@param year integer
---@param level 1|2
---@param input string
---@param command string[]
---@return string?
function M.test_challenge_with_command (day, year, level, input, command)
	local syscmd = {}
	for _, token in ipairs(command) do
		local formatted = token
		for argument, value in pairs {
			["{day}"] = day,
			["{year}"] = year,
			["{level}"] = level,
			["{input}"] = input,
		} do
			formatted = string.gsub(formatted, argument, tostring(value))
		end

		table.insert(syscmd, formatted)
	end

	local obj = vim.system(syscmd):wait() -- NOTE: might need to add an on_exit
	return obj.stdout
end

function M.present_results (day, year, results)
	local prompt = string.format("Day %d %d\n", day, year)
	local part1, part2 = unpack(results)

	if part1 then
		prompt = prompt .. string.format("Part 1: %s\n", part1)
	end
	if part2 then
		prompt = prompt .. string.format("Part 2: %s\n", part2)
	end

	vim.print(prompt)
end

return M
