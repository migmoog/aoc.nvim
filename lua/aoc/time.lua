local M = {
	_today = os.date "*t",
}

function M:_test_today (day, month, year)
	self._today = os.date(
		"*t",
		os.time {
			day = day,
			month = month,
			year = year,
		}
	)
end

function M:is_date_valid (day, year, check_month)
	if check_month and self.month ~= 12 then
		return false, "Advent of Code is not available yet. Wait for December!"
	end
	-- Eric Wastl announced that 2025 onward there would only be 12 challenges
	local challenges = year >= 2025 and 12 or 25
	if day > challenges then
		return false, "Advent of Code has ended. Try a specific day."
	end

	return true
end

function M:today ()
	return self._today
end

return M
