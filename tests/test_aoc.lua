local MiniTest = require "mini.test"
local T = MiniTest.new_set {}
local expect, add_note = MiniTest.expect, MiniTest.add_note

local og_input, og_confirm = vim.ui.input, vim.fn.confirm

local aoc, api

local function setup_test_modules()
	aoc = require "aoc"
	api = require "aoc.api"
	aoc.setup()
	api._session_file = "session.txt"
end

local function remove_fake_cookie()
	vim.fn.delete(api._session_file)
end

local function run_for_day(tbl)
	aoc._today = os.date("*t", os.time(tbl))
	vim.cmd "Aoc"
end

T["AocLogin command"] = MiniTest.new_set {
	hooks = {
		pre_case = setup_test_modules,
		post_case = function()
			remove_fake_cookie()
			vim.ui.input = og_input
			vim.fn.confirm = og_confirm
		end,
	},
}

local function mock_input(_opts, on_confirm)
	add_note "called the input function"
	on_confirm "Fake Cookie"
end

T["AocLogin command"]["logging in without pre-defined cookie sets file"] = function()
	vim.ui.input = mock_input
	expect.equality(api.is_logged_in(), false)

	vim.cmd "AocLogin"

	expect.equality(api.is_logged_in(), true)
	expect.equality(api.get_session(), "Fake Cookie")
end

T["AocLogin command"]["login with pre-defined cookie file asks for confirmation"] = function()
	vim.fn.writefile({ "cookie already exists" }, api._session_file)
	expect.equality(api.is_logged_in(), true)

	vim.ui.input = mock_input
	local asked_to_confirm = false
	vim.fn.confirm = function(_prompt, _options)
		asked_to_confirm = true
		return 1
	end

	-- require("aoc").setup()
	vim.cmd "AocLogin"

	expect.equality(asked_to_confirm, true)
	expect.equality(api.get_session(), "Fake Cookie")
end

T["Aoc command"] = MiniTest.new_set {
	hooks = {
		pre_case = setup_test_modules,
		post_case = remove_fake_cookie,
	},
}

T["Aoc command"]["raise an error when trying to pull up challenge w/o cookie"] = function()
	expect.equality(api.is_logged_in(), false)

	-- must be proper date
	expect.error(run_for_day, "Cannot send request without cookie", {
		day = 1,
		month = 12,
		year = 2025,
	})
end

T["Aoc command"]["say there's no challenge today if not in proper date range (no args)"] = function()
	api.set_session "Fake Cookie"
	expect.equality(api.is_logged_in(), true)
	local og_print = vim.print

	local printed_message = nil
	vim.print = function(msg)
		og_print(msg)
		printed_message = msg
	end

	MiniTest.finally(function()
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

T["Aoc command"]["pull up today's challenge (no args)"] = function()
	aoc._today = os.date(
		"*t",
		os.time {
			day = 1,
			month = 12,
			year = 2015,
		}
	)

	local og_api = package.loaded["aoc.api"]
	og_api.set_session "Fake Cookie"
	local day, year
	package.loaded["aoc.api"] = {
		is_logged_in = og_api.is_logged_in,
		open_challenge_info = function(d, y)
			day = d
			year = y
		end,
	}
	MiniTest.finally(function()
		package.loaded["aoc.api"] = og_api
	end)

	vim.cmd "Aoc"
	expect.equality(day, 1)
	expect.equality(year, 2015)
end

return T
