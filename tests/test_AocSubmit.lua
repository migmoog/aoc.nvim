local aoc, api
local expect = MiniTest.expect
local eq = expect.equality

local function remove_fake_cookie()
	vim.fn.delete(api._session_file)
end

local day, year, answer, level
local og_confirm = vim.fn.confirm
local asked_to_confirm = false
local T = MiniTest.new_set {
	hooks = {
		pre_once = function ()
			package.loaded["aoc.api"] = nil
			package.loaded["aoc"] = nil
		end,
		pre_case = function ()
			aoc = require "aoc"
			aoc.setup()
			aoc._test_today(1, 12, 2015)
			api = require "aoc.api"
			api.submit_answer = function (d, y, a, i)
				day = d
				year = y
				answer = a
				level = i and 2 or 1
			end
			api.set_session "Fake Cookie"
			vim.fn.confirm = function(prompt, opts)
				asked_to_confirm = true
				return 1
			end
		end,
		post_case = function ()
			vim.fn.confirm = og_confirm
			asked_to_confirm = false
			remove_fake_cookie()
		end
	}
}

T["No args, callback"] = function()
	aoc._project_config = {
		callback = function (d, input, l, y)
			return "6969" -- aoc usually deals in number results
		end
	}
	eq(asked_to_confirm, true)
	vim.cmd "AocSubmit"
	eq(
		{day, year, answer, level},
		{1, 2015, "6969", 1}
	)
end

T["No args, command"] = function ()
	aoc._project_config = {
		command = {"echo", '"Craziest answer EVER"'}
	}
	eq(asked_to_confirm, true)
	vim.cmd "AocSubmit"
	eq(
		{day, year, answer, level},
		{1, 2015, "Craziest answer EVER", 1}
	)
end

T["Give day but unspecified year"] = function ()
	-- TODO
end

return T
