local M = {
	_today = os.date "*t",
	_project_config = nil,
}

local function err(msg)
	vim.notify(msg, vim.log.levels.ERROR)
end

function M._test_today(day, month, year)
	M._today = os.date(
		"*t",
		os.time {
			day = day,
			month = month,
			year = year,
		}
	)
end

function M._path_to_input(fname)
	local inputs_dir = "inputs"
	if M._project_config and M._project_config.inputs_dir then
		inputs_dir = M._project_config.inputs_dir
	end

	return inputs_dir .. "/" .. fname
end

function M._search_for_config()
	local config_path = vim.fn.getcwd() .. "/aoc-config.lua"

	if vim.fn.filereadable(config_path) == 0 then
		-- not gonna print this as an error bc it would happen
		-- for every project
		return
	end
	M._project_config = dofile(config_path)
end

--- Sets up the advent of code plugin
function M.setup()
	-- loads project config on start
	local auid = vim.api.nvim_create_augroup("AdventOfCode", { clear = true })
	vim.api.nvim_create_autocmd("VimEnter", {
		group = auid,
		callback = M._search_for_config,
	})
	vim.api.nvim_create_autocmd("DirChanged", {
		group = auid,
		callback = M._search_for_config,
	})

	-- :Aoc (no args) to pull up today's challenge. Will tell user if Aoc isn't currently going on
	-- :Aoc DD to pull up challenge for specific day this year.
	-- :Aoc DD YY to pull up challenge for a specific day on a specific year
	vim.api.nvim_create_user_command("Aoc", function(args)
		local day = tonumber(args.fargs[1] or M._today.day)
		local month = M._today.month
		local year = tonumber(args.fargs[2] or M._today.year)
		if M._project_config and M._project_config.year then
			year = M._project_config.year
		end

		if year == M._today.year then
			if month < 12 then
				vim.print "Advent of Code is not available yet. Wait for December!"
				return
			end

			if day > 25 then
				vim.print "Advent of Code has ended. Try a specific day."
				return
			end
		end

		local api = require "aoc.api"
		if not api.is_logged_in() then
			err "Cannot send request without cookie"
			return
		end

		-- setup the input storage and download
		local inputs_dir = "inputs"
		if M._project_config and M._project_config.inputs_dir then
			inputs_dir = M._project_config.inputs_dir
		end

		if vim.fn.isdirectory(inputs_dir) == 0 then
			vim.fn.mkdir(inputs_dir)
		end
		local challenge_input = api.get_challenge_input(day, year)
		local fname = string.format(inputs_dir .. "/d%d_%d.txt", day, year)
		vim.fn.writefile({ challenge_input }, fname)

		api.open_challenge_info(day, year)
	end, {
		nargs = "*",
	})

	vim.api.nvim_create_user_command("AocLogin", function(_args)
		local instructions = [[
		1. Log into AOC in your web browser
		2. Run `:AocLogin` to give the plugin your cookie 
		3. Find the cookie and copy it into the field
		4. Work on from there!]]

		local api = require "aoc.api"
		if
			api.is_logged_in()
			and vim.fn.confirm("Cookie already exists. Do you want to replace it?", "&Yes\n&No") == 2
		then
			return
		end
		local session = vim.fn.inputsecret(instructions .. "\nPaste new cookie: ")
		api.set_session(session)
	end, {})

	vim.api.nvim_create_user_command("AocTest", function(args)
		-- error checks
		local pc = M._project_config
		if not pc then
			err "No aoc-config.lua present"
			return
		elseif not (pc.command or pc.callback) then
			err "aoc-config.lua has neither `callback` or `command` defined."
			return
		elseif pc.command and pc.callback then
			err "aoc-config.lua has both `callback` and `command` defined."
		end

		if args.fargs[1] == "all" then
			return
		end

		local day = tonumber(args.fargs[1] or M._today.day)
		local year = M._today.year -- i'd love some function chaining in lua
		if pc and pc.year then
			year = pc.year
		end
		local fname = string.format("d%d_%d.txt", day, year)
		local input_path = M._path_to_input(fname)
		if vim.fn.filereadable(input_path) == 0 then
			local msg = string.format('There is no input file for day %d. Open it with ":Aoc %d"', day, day)
			err(msg)
			return
		end

		local input = ''
		for _, line in ipairs(vim.fn.readfile(input_path)) do
			input = input .. line
		end

		-- running with command
		if pc.command then
			local command = {}
			for _, token in ipairs(pc.command) do
				local formatted = string.gsub(token, "{day}", tostring(day))
				formatted = string.gsub(formatted, "{year}", tostring(year))
				formatted = string.gsub(formatted, "{input}", input)
				table.insert(command, formatted)
			end
			vim.system(command)
			return
		end
		
		-- running with callback
		if pc.callback then
			pc.callback(day, input, year)
		end
	end, {
		nargs = "?",
	})
end

return M
