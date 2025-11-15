local T = MiniTest.new_set()
local expect, finally = MiniTest.expect, MiniTest.finally

local function acquire_api()
	package.loaded["aoc.api"] = nil
	local api = require "aoc.api"
	api._session_file = "./session.txt"
	return api
end
local function remove_fake_cookie()
	vim.fn.delete(require("aoc.api")._session_file)
end

T["session manipulation"] = MiniTest.new_set()

T["session manipulation"]["raises error when there is no file"] = function()
	local api = acquire_api()
	expect.error(api.get_session)
end

T["session manipulation"]["returns a string when there is a file"] = function()
	local api = acquire_api()
	expect.error(api.get_session)

	vim.fn.writefile({ "Fake Cookie" }, api._session_file)
	finally(remove_fake_cookie)

	expect.equality(api.get_session(), "Fake Cookie")
end

T["session manipulation"]["set session edits file"] = function()
	local api = acquire_api()
	expect.error(api.get_session)

	local result = api.set_session "Fake Cookie"
	expect.equality(result, 0)
	finally(remove_fake_cookie)

	expect.equality(api.get_session(), "Fake Cookie")

	local result2 = api.set_session "Even Faker Cookie"
	expect.equality(result2, 0)

	expect.equality(api.get_session(), "Even Faker Cookie")
end

T["is logged in"] = MiniTest.new_set()

T["is logged in"]["returns false when no session file exists"] = function()
	local api = acquire_api()
	expect.equality(api.is_logged_in(), false)
end

T["is logged in"]["returns true when session file does exist"] = function()
	local api = acquire_api()
	expect.equality(api.is_logged_in(), false)

	local result = api.set_session "doo doo"
	finally(remove_fake_cookie)
	expect.equality(result, 0)

	expect.equality(api.is_logged_in(), true)
end

local last_request = {
	url = nil,
	opts = nil,
	cookie = nil,
}
local mock_curl = {
	get = function(url, opts)
		last_request.url = url
		last_request.opts = opts
		last_request.cookie = opts.headers["Cookie"]
		return {
			body = "This is a fake response",
		}
	end,
}
local plenary_curl
T["Challenge Data"] = MiniTest.new_set {
	hooks = {
		pre_case = function()
			plenary_curl = package.loaded["plenary.curl"]
			package.loaded["plenary.curl"] = mock_curl
		end,
		post_case = function()
			package.loaded["plenary.curl"] = plenary_curl
			remove_fake_cookie()
		end,
	},
}

T["Challenge Data"]["getting challenge information"] = function()
	local api = acquire_api()
	-- takes <day>, <year>
	local og_system = vim.system
	vim.system = function(cmd, _opts, _on_exit)
		expect.equality(cmd, { "xdg-open", "https://adventofcode.com/2025/day/1" })
		return nil -- will make this a fake one with time im not sure
	end
	finally(function()
		vim.system = og_system
	end)
	api.open_challenge_info(1, 2025)
end

T["Challenge Data"]["getting challenge input"] = function()
	local api = acquire_api()
	api.set_session "Fake Cookie"
	local challenge_input = api.get_challenge_input(1, 2025)
	expect.equality(last_request.url, "https://adventofcode.com/2025/day/1/input")
	expect.equality(last_request.cookie, "Fake Cookie")
	expect.equality(challenge_input.body, "This is a fake response")
end

return T
