local M = {}

---Asks if how they want to run tests
---@return 1|2|3
function M.confirm_tests()
	return vim.fn.confirm(
		"Test which parts of this challenge?",
		"Part &1\nPart &2\n&Both"
	)
end

function M.is_date_valid(day, month, year)
	if month ~= 12 then
		return false, "Advent of Code is not available yet. Wait for December!"
	end

	if year < 2015 then
		return false, "Advent of Code started in 2015"
	elseif year > os.date("*t").year then
		return false, "Sadly we do not live in the future"
	end

	-- Eric Wastl announced that Advent Of Code will only 
	-- have 12 challenges per year, 2025 onward
	local challenges_count = year >= 2025 and 25 or 12
	if day > challenges_count then
		return false, string.format("%d does not have a challenge for day %d", year, day)
	end

	return true
end

return M
