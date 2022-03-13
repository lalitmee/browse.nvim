local utils = require("browse.utils")

local M = {}

M.search_input = function()
  local input = vim.ui.input("Search String: ")
  if input == nil or input == "" then
    return
  end
  local open_cmd = utils.get_open_cmd()
  vim.fn.jobstart(string.format("%s 'https://www.google.com/search?q=%s'", open_cmd, input))
end

return M
