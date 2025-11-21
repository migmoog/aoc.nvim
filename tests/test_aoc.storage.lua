local expect = MiniTest.expect
local eq = expect.equality

local storage
local T = MiniTest.new_set {
	hooks = {
		pre_once = function()
			package.loaded["aoc.storage"] = nil
		end,
		pre_case = function()
			storage = require "aoc.storage"
			storage._answers_file = "answers.json"
		end,

		post_case = function()
			vim.fn.delete(storage._answers_file)
		end,
	},
}

T["Storing an answer"] = function()
	eq(storage.is_initialized(), false)
	expect.error(function()
		storage.get_answer(1, 2015)
	end)

	storage.set_answer(1, 2015, 1, "Fake Answer")
	eq(storage.is_initialized(), true)
	eq(storage.get_answer(1, 2015, 1), "Fake Answer")
end

return T
