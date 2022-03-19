local utils = require("browse.utils")

local M = {}

M.search_input = function()
	vim.ui.input("Search String: ", function(input)
		if input == nil or input == "" then
			return
		end
		local open_cmd = utils.get_open_cmd()
		local cmd = open_cmd .. " https://www.google.com/search?q=" .. input
		vim.fn.jobstart(cmd)
	end)
end

return M
