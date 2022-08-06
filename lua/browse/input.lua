local browser = require("browse.browser")
local config = require("browse.config")

local fmt = string.format

local M = {}

M.search_input = browser.generic_search_custom(function(input)
	local provider = config.options.provider
	local path = fmt("https://%s.com/search?q=%s", provider, input)

	if provider == "google" or provider == "bing" then
		path = fmt("https://%s.com/search?q=%s", provider, input)
	elseif provider == "brave" then
		path = fmt("https://search.%s.com/search?q=%s", provider, input)
	elseif provider == "duckduckgo" then
		path = fmt("https://%s.com/?q=%s", provider, input)
	end

	return path
end)

return M
