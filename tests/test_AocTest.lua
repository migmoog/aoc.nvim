local expect, finally = MiniTest.expect, MiniTest.finally
local og_system = vim.system

local aoc, api
local function remove_fake_cookie()
	vim.fn.delete(api._session_file)
end

local test_cmd_stack
local T = MiniTest.new_set {
	hooks = {
		pre_case = function()
			package.loaded["aoc"] = nil
			package.loaded["aoc.api"] = nil

			aoc = require "aoc"
			aoc._test_today(1, 12, 2015)
			aoc.setup()

			api = require "aoc.api"
			api._session_file = "session.txt"
			api.set_session "Fake Cookie"
			api.get_challenge_input = function(_day, _year)
				return "This is a mock input"
			end

			api.open_challenge_info = function(_day, _year) end

			test_cmd_stack = {}
			vim.system = function(cmd, _opts, _on_exit)
				table.insert(test_cmd_stack, cmd)
			end
		end,
		post_case = function()
			remove_fake_cookie()
			vim.fn.delete("inputs", "rf")
			vim.system = og_system
			test_cmd_stack = {}
			aoc._project_config = nil
		end,
	},
}

T["error if there is no config file"] = function()
	expect.equality(aoc._project_config, nil)
	expect.error(vim.cmd, "No aoc%-config%.lua present", "AocTest")
end

T["Error if no input file"] = function()
	aoc._project_config = {
		command = { "{day}", "{input}", "{year}" }, -- bs to make sure it runs
	}
	expect.equality(vim.fn.isdirectory "inputs", 0)

	expect.error(function()
		vim.cmd "AocTest"
	end, 'There is no input file for day 1%. Open it with ":Aoc 1"')

	expect.error(function()
		vim.cmd "AocTest 2"
	end, 'There is no input file for day 2%. Open it with ":Aoc 2"')
end

T["Error if command and callback are defined or undefined"] = function()
	aoc._project_config = {}
	expect.error(function()
		vim.cmd "AocTest"
	end, "aoc%-config%.lua has neither `callback` or `command` defined%.")

	aoc._project_config = {
		command = {},
		callback = function(_day, _input, _year) end,
	}
	expect.error(function()
		vim.cmd "AocTest"
	end, "aoc%-config%.lua has both `callback` and `command` defined%.")
end

T["Runs command in project config"] = function()
	aoc._project_config = {
		command = { "{day}", "{year}", "{input}" },
	}

	for day = 1, 25 do
		vim.cmd(string.format("Aoc %d", day)) -- get the puzzle inputs
	end

	for day = 1, 25 do
		vim.cmd(string.format("AocTest %d", day))
		expect.equality(test_cmd_stack[day], { string.format("%d", day), "2015", "This is a mock input" })
	end
end

T["Runs callback in project config"] = function() 
	local calls = 0
	aoc._project_config = {
		callback = function(day, input, year) 
			calls = calls + 1
		end
	}

	for day = 1, 25 do
		vim.cmd(string.format("Aoc %d", day)) -- get the puzzle inputs
	end


	for day = 1, 25 do
		vim.cmd(string.format("AocTest %d", day))
	end

	expect.equality(calls, 25)
end

T["Running all days"] = function ()
	local calls = {}
	aoc._today.day = 25
	aoc._project_config = {
		callback = function (day, input, year)
			table.insert(calls, {day, input, year})
		end,
		year = 2023
	}

	vim.cmd "AocTest all" -- should implicitly download all inputs up to today
	expect.equality(#calls, 25)
	for day=1,25 do
		expect.equality(calls[day], {day, "This is a mock input", 2023})
	end
end

return T
