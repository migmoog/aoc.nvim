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

---Writes the provided value to the file that will represent the user's OAuth cookie
---@param session_value string
---@return -1|0
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

---Opens the challenge in the user's browser
---@param day integer
---@param year integer
function M.open_challenge_info(day, year)
	vim.ui.open(challenge_url(day, year))
end

---Retrieves the input for the challenge of a specific day and year.
---@param day integer
---@param year integer
---@return string
function M.get_challenge_input(day, year)
	local curl = require "plenary.curl"

	local response = curl.get(challenge_url(day, year, "input"), {
		headers = {
			["Cookie"] = M.get_session(),
		},
	})
	return response.body
end

function M.submit_answer(day, year, answer, is_second_answer)
	local curl = require "plenary.curl"

	local formdata = string.format("level=%d&answer=%s", is_second_answer and 2 or 1, answer)

	local response = curl.post(challenge_url(day, year, "answer"), {
		headers = {
			["Content-Type"] = "application/x-www-form-urlencoded",
			["Cookie"] = M.get_session(),
		},
		body = formdata
	})

	local res_fname = vim.fn.tempname() .. ".html"
	vim.fn.writefile({response.body}, res_fname)

	vim.ui.open(res_fname)
end

return M
