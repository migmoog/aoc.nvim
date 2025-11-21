local M = {}

M._answers_file = vim.fn.stdpath "data" .. "/answers.json"

function M.is_initialized()
	return vim.fn.filereadable(M._answers_file) == 1
end

local function load_answers()
	local lines = vim.fn.readfile(M._answers_file)
	local out = ""
	for _, v in ipairs(lines) do
		out = out .. v
	end
	return vim.json.decode(out)
end

---Get the answer for for a specific part of a challenge
---@param day integer
---@param year integer
---@param level 1|2
---@return string
function M.get_answer(day, year, level)
	return load_answers()[tostring(year)][tostring(day)][tostring(level)]
end

local function add_or_insert(tbl, value, ...)
	local keys = { ... }
	local node = tbl
	local i, k = 1, tostring(keys[1])
	while i < #keys do
		if not node[k] then
			node[k] = {}
			node = node[k]
		end
		i = i + 1
		k = tostring(keys[i])
	end
	node[k] = value
end

function M.set_answer(day, year, level, answer)
	local current_answers = {}
	if M.is_initialized() then
		current_answers = load_answers()
	end

	-- current_answers[year][day][level] = answer
	add_or_insert(current_answers, answer, year, day, level)

	vim.fn.writefile({
		vim.json.encode(current_answers),
	}, M._answers_file)
end

return M
