local eq, er = MiniTest.expect.equality, MiniTest.expect.error

local time, conf, api, aoc, cmd

local test_results = {}
local submitted_answer_stack = {}
local T = MiniTest.new_set {
	hooks = {
		pre_case = function ()
			time = require "aoc.time"
			time:_test_today(1, 12, 2015)

			conf = require "aoc.config"

			api = require "aoc.api"
			api.get_challenge_input = function (day, year)
				return string.format("Fake Input: D%dY%d", day, year)
			end
			api.submit_answer = function (day, year, answer, is_second_answer)
				table.insert(submitted_answer_stack, { day, year, answer, is_second_answer })
			end

			cmd = require "aoc.commands"
			cmd.present_results = function (day, year, results)
				table.insert(test_results, results)
			end

			aoc = require "aoc"
			aoc.setup()
		end,

		post_case = function ()
			test_results = {}
			submitted_answer_stack = {}
		end,
	},
}

T["Errors"] = MiniTest.new_set {}

T["Errors"]["callback and command are both defined"] = function ()
	conf:_test_config {
		command = {},
		callback = function (_day, _level, _input, _year) end,
	}

	er(vim.cmd, "both `callback` and `command` defined$", "AocTest")
end

T["Errors"]["callback and command are both undefined"] = function ()
	conf:_test_config {}

	er(vim.cmd, "neither `callback` or `command` defined$", "AocTest")
end

local test_choice
local choice_step = 1
local og_confirm = vim.fn.confirm
T["Run Tests"] = MiniTest.new_set {
	hooks = {
		pre_case = function ()
			vim.fn.confirm = function (_, _)
				local cs = choice_step
				choice_step = choice_step + 1
				return test_choice[cs]
			end
		end,
		post_case = function ()
			vim.fn.delete(conf.get.inputs_dir, "rf")
			vim.fn.confirm = og_confirm
			choice_step = 1
		end,
	},
	parametrize = {
		{ 1 },
		{ 2 },
	},
}


local function t(lvl, a)
	test_choice = {lvl, 1}
	vim.cmd("AocTest" .. a)
	choice_step = 1
end
T["Run Tests"]["Runs callback"] = function (lvl)
	local call_stack = {}
	conf:_test_config {
		callback = function (day, level, input, year)
			table.insert(call_stack, { day, level, input, year })
			return "Result " .. tostring(lvl)
		end,
	}

	t(lvl, "")
	eq(call_stack[1], { 1, lvl, "Fake Input: D1Y2015", 2015 })

	t(lvl, "13")
	eq(call_stack[2], { 13, lvl, "Fake Input: D13Y2015", 2015 })

	t(lvl, "9 2022")
	eq(call_stack[3], { 9, lvl, "Fake Input: D9Y2022", 2022 })

	local ls = tostring(lvl)
	eq(submitted_answer_stack, {
		{1, 2015, "Result " .. ls, lvl},
		{13, 2015, "Result " .. ls, lvl},
		{9, 2022, "Result " .. ls, lvl}
	})
end

T["Run Tests"]["Runs vim.system with formatted command"] = function (lvl)
	test_choice = {lvl, 1}
	local cmd_stack = {}
	conf:_test_config {
		command = { "{day}", "{level}", "{input}", "{year}" },
	}
	local og_system = vim.system
	MiniTest.finally(function ()
		vim.system = og_system
	end)

	vim.system = function (cmd, _on_exit)
		table.insert(cmd_stack, cmd)
		return {
			wait = function ()
				return { stdout = string.format("Result %d", lvl) }
			end,
		}
	end

	local is = tostring(lvl)
	t(lvl, "")
	eq(cmd_stack[1], { "1", is, "Fake Input: D1Y2015", "2015" })

	t(lvl, "25")
	eq(cmd_stack[2], { "25", is, "Fake Input: D25Y2015", "2015" })

	t(lvl, "19 2025")
	eq(cmd_stack[3], { "19", is, "Fake Input: D19Y2025", "2025" })

	for _, v in ipairs(test_results) do
		eq(v, { "Result " .. tostring(lvl) })
	end

	test_choice = 1
	local ls = tostring(lvl)
	eq(submitted_answer_stack, {
		{1, 2015, "Result " .. ls, lvl},
		{25, 2015, "Result " .. ls, lvl},
		{19, 2025, "Result " .. ls, lvl}
	})
end

T["Running both tests"] = MiniTest.new_set {
	hooks = {
		pre_once = function ()
			test_choice = {3, 1}
			vim.fn.confirm = function (_, _)
				local cs = choice_step
				choice_step = choice_step + 1
				return test_choice[cs]
			end
		end,
		post_once = function ()
			vim.fn.confirm = og_confirm
		end,
		post_case = function ()
			vim.fn.delete(conf.get.inputs_dir, "rf")
		end,
	},
}

local function tb(a)
	test_choice = {3, 1}
	vim.cmd("AocTest " .. a)
	choice_step = 1
end
T["Running both tests"]["Callback"] = function ()
	local call_stack = {}
	conf:_test_config {
		callback = function (day, level, input, year)
			table.insert(call_stack, { day, level, input, year })
			return "Result"
		end,
	}

	tb ""
	eq(call_stack[1], { 1, 1, "Fake Input: D1Y2015", 2015 })
	eq(call_stack[2], { 1, 2, "Fake Input: D1Y2015", 2015 })

	tb "25"
	eq(call_stack[3], { 25, 1, "Fake Input: D25Y2015", 2015 })
	eq(call_stack[4], { 25, 2, "Fake Input: D25Y2015", 2015 })

	tb "3 2017"
	eq(call_stack[5], { 3, 1, "Fake Input: D3Y2017", 2017 })
	eq(call_stack[6], { 3, 2, "Fake Input: D3Y2017", 2017 })

	for _, v in ipairs(test_results) do
		eq(v, { "Result", "Result" })
	end
	eq(submitted_answer_stack, {
		{1, 2015, "Result", 1},
		{1, 2015, "Result", 2},
		{25, 2015, "Result", 1},
		{25, 2015, "Result", 2},
		{3, 2017, "Result", 1},
		{3, 2017, "Result", 2},
	})
end

T["Running both tests"]["Command"] = function ()
	local cmd_stack = {}
	conf:_test_config {
		command = { "{day}", "{level}", "{input}", "{year}" },
	}
	local og_system = vim.system
	MiniTest.finally(function ()
		vim.system = og_system
	end)

	vim.system = function (cmd, _on_exit)
		table.insert(cmd_stack, cmd)
		return {
			wait = function ()
				return { stdout = "Fake Result" }
			end,
		}
	end

	tb ""
	eq(cmd_stack[1], { "1", "1", "Fake Input: D1Y2015", "2015" })
	eq(cmd_stack[2], { "1", "2", "Fake Input: D1Y2015", "2015" })

	tb "25"
	eq(cmd_stack[3], { "25", "1", "Fake Input: D25Y2015", "2015" })
	eq(cmd_stack[4], { "25", "2", "Fake Input: D25Y2015", "2015" })

	tb "19 2025"
	eq(cmd_stack[5], { "19", "1", "Fake Input: D19Y2025", "2025" })
	eq(cmd_stack[6], { "19", "2", "Fake Input: D19Y2025", "2025" })

	for _, v in ipairs(test_results) do
		eq(v, { "Result 1", "Result 2" })
	end
	eq(submitted_answer_stack, {
		{1, 2015, "Fake Result", 1},
		{1, 2015, "Fake Result", 2},
		{25, 2015, "Fake Result", 1},
		{25, 2015, "Fake Result", 2},
		{19, 2025, "Fake Result", 1},
		{19, 2025, "Fake Result", 2},
	})
end

return T
