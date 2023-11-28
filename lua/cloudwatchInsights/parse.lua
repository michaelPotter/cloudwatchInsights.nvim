M = {}

local function parseDate(dateString)
	return vim.fn.system("date +%s -d \"" .. dateString .. "\"")
end

-- Parse the query yaml string into an object
local function parseQueryYaml(yamlString)

	-- TODO replace with luarocks ryaml?
	-- TODO add parsing error handling
	local log_group  = vim.fn.system("yq -r .log_group",  yamlString)
	local start_time = vim.fn.system("yq -r .start_time", yamlString)
	local end_time   = vim.fn.system("yq -r .end_time",   yamlString)
	local query      = vim.fn.system("yq -r .query",      yamlString)
	local profile    = vim.fn.system("yq -r .profile",    yamlString)
	local format     = vim.fn.system("yq -r .format",     yamlString)

	return {
		profile    = vim.fn.trim(profile),
		log_group  = vim.fn.trim(log_group),
		start_time = vim.fn.trim(parseDate(start_time)),
		end_time   = vim.fn.trim(parseDate(end_time)),
		query      = vim.fn.trim(query),
		format     = vim.fn.trim(format),
	}
end

-- Parses the contents of the current buffer to get the query
function M.parseQueryFromCurrentBuffer()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local queryText = vim.fn.join(lines, '\n')
	local queryFields = parseQueryYaml(queryText)

	return queryFields
end

-- Runs the given query on the given input string.
-- Returns a tuple of 1. the output of jq and 2. the return code of jq
function M.jq(inputString, query)
	local result = vim.fn.system({"jq", "-r", query}, inputString)
	return vim.fn.trim(result), vim.v.shell_error
end


return M
