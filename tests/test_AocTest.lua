local eq, er = MiniTest.expect.equality, MiniTest.expect.error

local time, conf, api, aoc
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

			aoc = require "aoc"
			aoc.setup()
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
local og_confirm
T["Run Tests"] = MiniTest.new_set {
	hooks = {
		pre_case = function ()
			og_confirm = vim.fn.confirm
			vim.fn.confirm = function (_, _)
				return test_choice
			end
		end,
		post_case = function ()
			vim.fn.delete(conf.get.inputs_dir, "rf")
			vim.fn.confirm = og_confirm
		end,
	},
	parametrize = {
		{ 1 },
		{ 2 },
	},
}

T["Run Tests"]["Runs callback"] = function (lvl)
	test_choice = lvl
	local call_stack = {}
	conf:_test_config {
		callback = function (day, level, input, year)
			table.insert(call_stack, { day, level, input, year })
		end,
	}

	vim.cmd "AocTest"
	eq(call_stack[1], { 1, lvl, "Fake Input: D1Y2015", 2015 })

	vim.cmd "AocTest 13"
	eq(call_stack[2], { 13, lvl, "Fake Input: D13Y2015", 2015 })

	vim.cmd "AocTest 9 2022"
	eq(call_stack[3], { 9, lvl, "Fake Input: D9Y2022", 2022 })
end

T["Run Tests"]["Runs vim.system with formatted command"] = function (lvl)
	test_choice = lvl
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
				return { stdout = "TODO" }
			end,
		}
	end

	local is = tostring(lvl)
	vim.cmd "AocTest"
	eq(cmd_stack[1], { "1", is, "Fake Input: D1Y2015", "2015" })

	vim.cmd "AocTest 25"
	eq(cmd_stack[2], { "25", is, "Fake Input: D25Y2015", "2015" })

	vim.cmd "AocTest 19 2025"
	eq(cmd_stack[3], { "19", is, "Fake Input: D19Y2025", "2025" })
end

return T
