-- This is the start of a plugin to query cloudwatch logs insights from vim.
-- The idea is to describe the query in a yaml file, and run the main function. The results will open in a new buffer.
--
-- Dependencies:
-- 	- aws cli
-- 	- jq
-- 	- yq

-- Example yaml query file:
-- log_group: /aws/lambda/foo-app-dev
-- start_time: 1678809733
-- end_time: 1678813343
-- query: |
--     fields @timestamp, @message, @logStream, @log
--     | sort @timestamp desc
--     | limit 20

-- TODO think through the organization of this as a plugin a little more... should the vim command be under plugin/ so it is always available?

local utils = require('cloudwatchInsights.util')
local parse = require('cloudwatchInsights.parse')
local cw = require('cloudwatchInsights.cloudwatch')

M = {}
M.last_query = {};

-- Open the query results in a new buffer
local function displayResults(data)
	-- print("displaying results")  -- TODO DELETE ME
	local buftext

	-- Format the query results depending on user format arg
	-- TODO show statistics somehow?
	if data.error then
		buftext = data.error
	else
		if data.query.format == "raw" then
			buftext = vim.inspect(data)
		else
			local formatted = parse.jq(data.resultRaw, ".results|map(map({key: .field, value})| from_entries)")
			if data.query.format == "json" then
				buftext = formatted
			else
				-- data.query.format probably equals "lines"
				local results = vim.json.decode(formatted)
				for i, entry in ipairs(results) do
					local entry_modified = ""
					for field_name, field in pairs(entry) do
						if field_name ~= "@ptr" then
							entry_modified = entry_modified .. "\t" .. field
						end
					end
					results[i] = vim.fn.trim(entry_modified)
				end
				buftext = results
			end
		end
	end

	-- nvim_buf_set_lines takes a list of strings
	if type(buftext) == "string" then
		buftext = vim.fn.split(buftext, "\n")
	end

	local buf = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, buftext)
	vim.api.nvim_buf_set_option(buf, 'modifiable', false)
	vim.api.nvim_command('split')
	vim.api.nvim_command('buffer ' .. buf)
end

-- NOTE: not used atm
M.openCloudwatchQueryInConsole = function()
	-- TODO make region configurable
	local region = 'us-west-2'

	local query_fields = parse.parseQueryFromCurrentBuffer()
	local encoded_query = utils.star_encode(query_fields.query)

	local encoded_log_group = query_fields.log_group:gsub('/', '*2f')
	local url = 'https://' .. region .. '.console.aws.amazon.com/cloudwatch/home'
	url = url .. '?region=' .. region
	-- TODO support start/end times
	url = url .. [[#logsV2:logs-insights$3FqueryDetail$3D~(end~0~start~-3600~timeType~'RELATIVE~unit~'seconds~editorString~']] .. encoded_query .. [[~queryId~'f0e8c9d1791a2a5-617893cc-4755097-9ef74b23-c5aa4e44e115f8bb7e9f9dff~source~(~']] .. encoded_log_group .. [[))]]


	vim.api.nvim_set_current_line(url)
	-- TODO make this open in the browser
-- https://us-west-2.console.aws.amazon.com/cloudwatch/home
--
-- ?region=us-west-2#logsV2:logs-insights$3FqueryDetail$3D~(end~0~start~-3600~timeType~'RELATIVE~unit~'seconds~editorString~'fields*20*40timestamp*2c*20*40message*2c*20*40logStream*2c*20*40log*0a*7c*20sort*20*40timestamp*20desc*0a*7c*20limit*2020~queryId~'f0e8c9d1791a2a5-617893cc-4755097-9ef74b23-c5aa4e44e115f8bb7e9f9dff~source~(~'*2foo*2fconsolidated))

end

-- Main function
function M.doCloudwatchQuery()
	local query = parse.parseQueryFromCurrentBuffer()
	cw.cloudwatchQuery(query, displayResults)
end

function M.devhook()
	vim.keymap.set('n', '<leader>cw', ':CloudwatchQuery<cr>')
end

return M
