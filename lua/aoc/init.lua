local M = {
	_today = os.date "*t",
}

---@class Challenge
---@field desc1 Description
---@field desc2 Description|nil
M.Challenge = {}

---Represents a challenge in Advent of Code.
---@param desc1 Description
---@param desc2 Description|nil
---@return Challenge
function M.Challenge:new(desc1, desc2)
	local c = {
		desc1 = desc1,
		desc2 = desc2,
		answers = {
			nil, nil
		}
	}

	function c:get_completed_challenges()
		local out = 0
		for i=1,#self.answers do
			out = out + self.answers[i] and 1 or 0
		end
	end

	return c
end

---@alias HlDesc ["AocEm"|"AocStar"|"AocCode", number, number, number]

---@class Description
---@field header string
---@field paragraphs [string]
---@field hls [HlDesc]
M.Description = {}

---Constructor for a n Advent of Code challenge description
---@param header string
---@param paragraphs [string]
---@param hls [HlDesc]
---@return Description
function M.Description:new(header, paragraphs, hls)
	local d = {
		header = header,
		paragraphs = paragraphs,
		hls = hls,
	}

	return d
end

--- Sets up the advent of code plugin
--- @param settings table|nil
function M.setup(settings)
	if not settings then
		settings = {}
	end
	
	-- :Aoc (no args) to pull up today's challenge. Will tell user if Aoc isn't currently going on
	-- :Aoc DD to pull up challenge for specific day this year.
	-- :Aoc DD YY to pull up challenge for a specific day on a specific year
	vim.api.nvim_create_user_command("Aoc", function(args)
		local day = args.fargs[1] or M._today.day
		local month = M._today.month
		local year = args.fargs[2] or M._today.year

		if year == M._today.year then
			if month < 12 then
				vim.print "Advent of Code is not available yet. Wait for December!"
				return
			end

			if day > 25 then
				vim.print "Advent of Code has ended. Try a specific day."
				return
			end
		end

		local api = require "aoc.api"
		if not api.is_logged_in() then
			vim.notify("Cannot send request without cookie", vim.log.levels.ERROR)
			return
		end
	
		-- setup the input storage and download
		local inputs_dir = settings.inputs_dir or "inputs"
		if vim.fn.isdirectory(inputs_dir) == 0 then
			vim.fn.mkdir(inputs_dir)
		end
		local challenge_input = api.get_challenge_input(day, year)
		local fname = string.format(inputs_dir .. "/d%d_%d.txt", day, year)
		vim.fn.writefile({ challenge_input }, fname)

		api.open_challenge_info(day, year)
	end, {
		nargs = "*",
	})

	vim.api.nvim_create_user_command("AocLogin", function(args)
		local instructions = [[
		1. Log into AOC in your web browser
		2. Run `:AocLogin` to give the plugin your cookie 
		3. Find the cookie and copy it into the field
		4. Work on from there!]]

		local api = require "aoc.api"
		if
			api.is_logged_in()
			and vim.fn.confirm("Cookie already exists. Do you want to replace it?", "&Yes\n&No") == 2
		then
			return
		end
		vim.ui.input({ prompt = instructions .. "\nPaste new cookie: " }, api.set_session)
	end, {})
end

return M
