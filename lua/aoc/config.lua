-- default values. If it's not in this table it must be defined by the user
-- in their config
local DEFAULTS = {
	year = function ()
		return require("aoc.time"):today().year
	end,
	inputs_dir = "inputs",
}

local M = {
	_config = nil,
}

local function __index_config (tb, k)
	local prop = tb._config[k]
	if not prop then
		local default = DEFAULTS[k]
		if default then
			if type( default ) == "function" then
				return default()
			end
			return default
		end

		-- Err(string.format('There is no default value for "%s"', k))
		return nil
	end

	return prop
end

-- pseudo interface for accessing properties
M.get = setmetatable(M, {
	__index = __index_config,
})

function M:_test_config (c)
	self._config = c
end

---Validates the current user's config.
---Throws errors if:
--- 1. No config file is present
--- 2. The config doesn't define callback or command
--- 3. The config defines *both* callback and command
---@return boolean
function M:check ()
	local c = self._config
	if not c then
		Err "No aoc-config.lua present"
		return false
	end

	if c.callback and c.command then
		Err "aoc-config.lua has both `callback` and `command` defined"
		return false
	end

	if not (c.callback or c.command) then
		Err "aoc-config.lua has neither `callback` or `command` defined"
		return false
	end

	return true
end

---Searches for an `aoc-config.lua` file in cwd, then sets the project settings accordingly
function M:search ()
	local config_path = vim.fn.getcwd() .. "/aoc-config.lua"

	if vim.fn.filereadable(config_path) == 0 then
		-- not gonna print this as an error bc it would happen
		-- for every project
		self._config = nil
		return
	end

	self._config = dofile(config_path)
end

return M
