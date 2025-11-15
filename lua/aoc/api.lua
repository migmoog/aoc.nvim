--- Makes api calls to advent of code and stuff

local M = {}
M._session = nil
local data_dir = vim.fn.stdpath "data" .. "/aoc.nvim/"
M._session_file = data_dir .. "session.txt"

---Checks if the cookie file for advent of code exists
---@return boolean
function M.is_logged_in()
	return vim.fn.filereadable(M._session_file) == 1
end

function M.set_session(session_value)
	if vim.fn.isdirectory(data_dir) == 0 then
		vim.fn.mkdir(data_dir, "p")
	end
	return vim.fn.writefile({ session_value }, M._session_file)
end

--- Returns the cookie, if the file doesn't exist it throws an error
--- Check if if the cookie is retrievable with `is_logged_in()`
---@return string
function M.get_session()
	return vim.fn.readfile(M._session_file)[1]
end

local function challenge_url(day, year, attach)
	local out = string.format("https://adventofcode.com/%d/day/%d", year, day)
	if attach then
		return out .. "/" .. attach
	end
	return out
end

function M.open_challenge_info(day, year)
	vim.system { "xdg-open", challenge_url(day, year) }
end

function M.get_challenge_input(day, year)
	local curl = require "plenary.curl"

	local response = curl.get(challenge_url(day, year, "input"), {
		headers = {
			["Cookie"] = M.get_session(),
		},
	})
	return response.body
end

return M
