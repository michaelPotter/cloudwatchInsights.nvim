vim.api.nvim_create_user_command(
	'CloudwatchQuery',
	function() require('cloudwatchInsights').doCloudwatchQuery() end,
	{
		desc = "Run the cloudwatch query",
	}
);
