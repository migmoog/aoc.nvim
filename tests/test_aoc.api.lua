local api
local T = MiniTest.new_set {
	hooks = {
		pre_case = function()
			package.loaded["aoc.api"] = nil
			api = require "aoc.api"
			api._session_file = "session.txt"
		end,
		post_case = function()
			vim.fn.delete(api._session_file)
		end,
	},
}

local expect, finally = MiniTest.expect, MiniTest.finally

T["session manipulation"] = MiniTest.new_set()
T["session manipulation"]["raises error when there is no file"] = function()
	expect.error(api.get_session)
end

T["session manipulation"]["returns a string when there is a file"] = function()
	expect.error(api.get_session)

	vim.fn.writefile({ "Fake Cookie" }, api._session_file)

	expect.equality(api.get_session(), "Fake Cookie")
end

T["session manipulation"]["set session edits file"] = function()
	expect.error(api.get_session)

	local result = api.set_session "Fake Cookie"
	expect.equality(result, 0)

	expect.equality(api.get_session(), "Fake Cookie")

	local result2 = api.set_session "Even Faker Cookie"
	expect.equality(result2, 0)

	expect.equality(api.get_session(), "Even Faker Cookie")
end

T["is logged in"] = MiniTest.new_set()

T["is logged in"]["returns false when no session file exists"] = function()
	expect.equality(api.is_logged_in(), false)
end

T["is logged in"]["returns true when session file does exist"] = function()
	expect.equality(api.is_logged_in(), false)

	local result = api.set_session "doo doo"
	finally(function()
		vim.fn.delete(api._session_file)
	end)
	expect.equality(result, 0)

	expect.equality(api.is_logged_in(), true)
end

local last_request = {}
local mock_curl = {
	get = function(url, opts)
		last_request.url = url
		last_request.opts = opts
		return {
			body = "This is a fake response",
		}
	end,

	post = function(url, opts)
		last_request.url = url
		last_request.opts = opts
		return {
			body = "<html>fake html</html>",
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
			for k, _ in pairs(last_request) do
				last_request[k] = nil
			end
			package.loaded["plenary.curl"] = plenary_curl
		end,
	},
}

T["Challenge Data"]["getting challenge information"] = function()
	local og_open = vim.ui.open
	vim.ui.open = function(path, _opts)
		expect.equality(path, "https://adventofcode.com/2025/day/1")
	end
	finally(function()
		vim.ui.open = og_open
	end)
	api.open_challenge_info(1, 2025)
end

T["Challenge Data"]["getting challenge input"] = function()
	api.set_session "Fake Cookie"
	local challenge_input = api.get_challenge_input(1, 2025)
	expect.equality(last_request.url, "https://adventofcode.com/2025/day/1/input")
	expect.equality(last_request.opts.headers.Cookie, "Fake Cookie")
	expect.equality(challenge_input, "This is a fake response")
end

T["Challenge Data"]["submitting answers"] = function()
	api.set_session "Fake Cookie"
	local og_open = vim.ui.open
	local file_ending
	vim.ui.open = function(path, _opts)
		-- should save the html response and open it in the broswer
		file_ending = string.match(path, "%.html$")
	end
	finally(function()
		vim.ui.open = og_open
	end)

	api.submit_answer(1, 2025, "6969")
	expect.equality(last_request.url, "https://adventofcode.com/2025/day/1/answer")
	expect.equality(last_request.opts.body, "level=1&answer=6969")
	expect.equality(last_request.opts.headers["Content-Type"], "application/x-www-form-urlencoded")
	expect.equality(file_ending, ".html")

	api.submit_answer(7, 2020, "8008135", true)
	expect.equality(last_request.opts.headers["Content-Type"], "application/x-www-form-urlencoded")
	expect.equality(last_request.url, "https://adventofcode.com/2020/day/7/answer")
	expect.equality(last_request.opts.body, "level=2&answer=8008135")
	expect.equality(file_ending, ".html")
end

return T
