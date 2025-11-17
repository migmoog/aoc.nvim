local expect = MiniTest.expect
local og_inputsecret, og_confirm = vim.fn.inputsecret, vim.fn.confirm

local aoc, api
local T = MiniTest.new_set {
	hooks = {
		pre_case = function ()
			aoc = require "aoc"
			aoc.setup()
			api = require "aoc.api"
			api._session_file = "session.txt"
		end,
		post_case = function()
			vim.fn.inputsecret = og_inputsecret
			vim.fn.confirm = og_confirm
			vim.fn.delete(api._session_file)
		end,
	},
}

local function mock_inputsecret(_prompt, _text)
	return "Fake Cookie"
end

T["logging in without pre-defined cookie sets file"] = function()
	expect.equality(api.is_logged_in(), false)

	vim.fn.inputsecret = mock_inputsecret
	vim.cmd "AocLogin"

	expect.equality(api.is_logged_in(), true)
	expect.equality(api.get_session(), "Fake Cookie")
end

T["login with pre-defined cookie file asks for confirmation"] = function()
	vim.fn.writefile({ "cookie already exists" }, api._session_file)
	expect.equality(api.is_logged_in(), true)

	vim.fn.inputsecret = mock_inputsecret
	local asked_to_confirm = false
	vim.fn.confirm = function(_prompt, _options)
		asked_to_confirm = true
		return 1
	end

	vim.cmd "AocLogin"

	expect.equality(asked_to_confirm, true)
	expect.equality(api.get_session(), "Fake Cookie")
end

return T
