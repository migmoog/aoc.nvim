local M = {
	_project_config = nil,
}

function Err (msg)
	vim.notify(msg, vim.log.levels.ERROR)
end

local function search_for_config ()
	require("aoc.config"):search()
end

local function confirm_challenge_parts ()
	return vim.fn.confirm("Which part of the challenge do you want to run?", "Part &1\nPart &2\n&Both\n&Cancel")
end

--- Sets up the advent of code plugin
function M.setup ()
	-- loads project config on start
	local auid = vim.api.nvim_create_augroup("AdventOfCode", { clear = true })
	local auopts = {
		group = auid,
		callback = search_for_config,
	}
	vim.api.nvim_create_autocmd("VimEnter", auopts)
	vim.api.nvim_create_autocmd("DirChanged", auopts)

	-- :Aoc (no args) to pull up today's challenge. Will tell user if Aoc isn't currently going on
	-- :Aoc DD to pull up challenge for specific day this year.
	-- :Aoc DD YY to pull up challenge for a specific day on a specific year
	vim.api.nvim_create_user_command("Aoc", function (args)
		local time, conf = require "aoc.time", require "aoc.config"
		local td = time:today()
		local day = tonumber(args.fargs[1]) or td.day
		local year = tonumber(args.fargs[2]) or conf.get.year

		local valid, msg = time:is_date_valid(day, year, not #args.fargs)
		if valid then
			require("aoc.commands").pull_up_challenge(day, year, conf.get.inputs_dir)
		else
			Err(msg)
		end
	end, {
		nargs = "*",
	})

	-- :AocLogin takes secret user input and sets a private cookie file
	vim.api.nvim_create_user_command("AocLogin", function (_)
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

	vim.api.nvim_create_user_command("AocTest", function (args)
		local conf = require "aoc.config"
		if not conf:check() then
			return
		end

		local choice = confirm_challenge_parts()
		if choice == 4 then
			return
		end

		local time = require "aoc.time"
		local td = time:today()
		local day = tonumber(args.fargs[1]) or td.day
		local year = tonumber(args.fargs[2]) or conf.get.year

		local cmd = require "aoc.commands"
		local id = conf.get.inputs_dir
		if not cmd.has_input(day, year, id) then
			cmd.download_input(day, year, id)
		end
		local input = cmd.load_input(day, year, id)

		local function action (level)
			if conf.get.command then
				return cmd.test_challenge_with_command(day, year, level, input, conf.get.command)
			end
			return conf.get.callback(day, level, input, year)
		end

		if vim.fn.confirm(
			"Do you want to submit your answers?",
			"&Yes\n&No"
		) ~= 1 then
			return
		end

		local api = require "aoc.api"
		if choice == 3 then
			api.submit_answer(day, year, action(1), 1)
			api.submit_answer(day, year, action(2), 2)
		else
			api.submit_answer(day, year, action(choice), choice)
		end
	end, {
		nargs = "*",
	})
end

return M
