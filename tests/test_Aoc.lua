local expect, finally = MiniTest.expect, MiniTest.finally
local og_system = vim.system

local aoc, api

local function run_for_day(date)
	aoc._test_today(date.day, date.month, date.year)
	vim.cmd "Aoc"
end

local function remove_fake_cookie()
	vim.fn.delete(api._session_file)
end

local params = {}
local T = MiniTest.new_set {
	hooks = {
		pre_case = function()
			aoc = require "aoc"
			aoc.setup()

			api = require "aoc.api"
			api._session_file = "session.txt"
			api.open_challenge_info = function(day, year)
				params.info_day = day
				params.info_year = year
			end
			api.get_challenge_input = function(day, year)
				params.input_day = day
				params.input_year = year
				return "This is a mock input"
			end
			api.set_session "Fake Cookie"
		end,
		post_case = function()
			remove_fake_cookie()
			vim.fn.delete("inputs", "rf")
			aoc = nil
			api = nil
		end,
	},
}

T["raise an error when trying to pull up challenge w/o cookie"] = function()
	remove_fake_cookie()
	expect.equality(api.is_logged_in(), false)

	-- must be proper date
	expect.error(run_for_day, "Cannot send request without cookie", {
		day = 1,
		month = 12,
		year = 2025,
	})
end

T["say there's no challenge today if not in proper date range (no args)"] = function()
	expect.equality(api.is_logged_in(), true)
	local og_print = vim.print

	local printed_message = nil
	vim.print = function(msg)
		og_print(msg)
		printed_message = msg
	end

	finally(function()
		vim.print = og_print
		aoc._today = os.date "*t"
	end)

	-- testing not the right month
	run_for_day {
		day = 12,
		month = 1,
		year = 2025,
	}
	expect.equality(printed_message, "Advent of Code is not available yet. Wait for December!")

	-- testing not the right day
	run_for_day {
		day = 26,
		month = 12,
		year = 2025,
	}
	expect.equality(printed_message, "Advent of Code has ended. Try a specific day.")
end

T["pull up today's challenge (no args)"] = function()
	aoc._test_today(1, 12, 2015)

	-- downloads the challenge input alongside it into a default directory (called inputs)
	expect.equality(vim.fn.isdirectory "inputs", 0)

	vim.cmd "Aoc"
	expect.equality(params.info_day, 1)
	expect.equality(params.info_year, 2015)
	expect.equality(params.input_day, 1)
	expect.equality(params.input_year, 2015)

	expect.equality(vim.fn.isdirectory "inputs", 1)
	expect.equality(vim.fn.readfile "inputs/d1_2015.txt", { "This is a mock input" })
end

T["Pull up specific day's challenge (with args)"] = function()
	vim.cmd "Aoc 9 2019"
	expect.equality(params, {
		info_day = 9,
		info_year = 2019,
		input_day = 9,
		input_year = 2019,
	})

	expect.equality(vim.fn.isdirectory "inputs", 1)
	expect.equality(vim.fn.readfile "inputs/d9_2019.txt", { "This is a mock input" })
end

return T
