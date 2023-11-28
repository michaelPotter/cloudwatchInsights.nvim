local parse = require('cloudwatchInsights.parse')

M = {}
M.last_query = {};


-- Build an arguments string for setting the aws profile in an aws cli command
local function getProfileString(profile)
	if profile then
		return "--profile " .. profile
	end
	return ""
end

-- Build the cli query command
local function buildQueryCommand(queryFields)
	-- TODO validate that profile is provided or AWS_PROFILE is set
	-- TODO validate that required fields exist

	local profileString = getProfileString(queryFields.profile)

	local queryCommand = string.format([[
		aws logs start-query %s \
			 --log-group-name %s \
			 --start-time %s \
			 --end-time %s \
			 --query-string "%s"
	]],
		profileString,
		queryFields.log_group,
		queryFields.start_time,
		queryFields.end_time,
		queryFields.query
	)
	return queryCommand
end

-- Continuously check if results are ready, then run the callback when end
local function doQueryResultCheck(queryResultCommand, data, callback)
	-- Do api call
	-- print("checking for results...")  -- TODO DELETE ME
	local resultResponseRaw = vim.fn.system(queryResultCommand)
	if vim.v.shell_error ~= 0 then
		data.error = resultResponseRaw
		return vim.schedule_wrap(function() callback(data) end)()
	end

	-- This should always be json if the shell command was successful
	local resultResponse = vim.json.decode(resultResponseRaw)
	local status = resultResponse.status

	if status ~= "Running" then
		-- return if success
		data.result = resultResponse
		data.resultRaw = resultResponseRaw
		return vim.schedule_wrap(function()
			callback(data)
		end)()
	else
		-- otherwise sleep and check again
		-- print("sleeping...")  -- TODO DELETE ME
		vim.loop.sleep(1000)
		return doQueryResultCheck(queryResultCommand, data, callback)
	end
end

-- Run a cloudwatch query and run the callback when finished.
function M.cloudwatchQuery(query, callback)
	local data = {
		query = query,
		queryCommand = buildQueryCommand(query),
	}

	local response = vim.fn.system(data.queryCommand)
	-- TODO sheck v:shell_error and handle error
	data.queryResponse = response
	if vim.v.shell_error ~= 0 then
		data.error = data.queryResponse
		callback(data)
		return
	end

	-- e.g. b0908f83-72f7-42f0-a431-c48a63610313
	data.queryId = parse.jq(response, '.queryId')

	local profileString = getProfileString(query.profile)
	local queryResultCommand = string.format("aws %s logs get-query-results --query-id %s", profileString, data.queryId)


	return doQueryResultCheck(queryResultCommand, data, callback)
end

return M
