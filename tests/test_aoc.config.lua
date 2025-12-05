local eq, fin = MiniTest.expect.equality, MiniTest.finally

local conf

local T = MiniTest.new_set {
	hooks = {
		pre_once = function ()
			conf = require "aoc.config"
		end,
		post_once = function ()
			conf._config = nil
		end,
		pre_case = function ()
			conf._config = nil
		end
	},
}

T["Searching for config"] = function ()
	local cwd = vim.fn.getcwd()
	fin(function ()
		vim.fn.chdir(cwd)
	end)

	eq(conf._config, nil)
	vim.fn.chdir "tests/config_test"

	conf:search()

	eq(conf._config, {
		inputs_dir = "myawesometestinputs",
		year = 2022,
		command = { "python", "main.py", "{day}", "{level}", "{year}", "{input}" },
	})

	-- trying the get wrapper
	eq(conf.get.year, 2022)
	eq(conf.get.command, { "python", "main.py", "{day}", "{level}", "{year}", "{input}" })
	eq(conf.get.inputs_dir, "myawesometestinputs")
	eq(conf.get.callback, nil)
end

return T
