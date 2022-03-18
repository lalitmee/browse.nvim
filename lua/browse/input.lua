local utils = require("browse.utils")

local M = {}

M.search_input = function()
  vim.ui.input("Search String: ", function(input)
    if input == nil or input == "" then
      return
    end
    local open_cmd = utils.get_open_cmd()
    local cmd = open_cmd.." https://www.google.com/search?q="..input
    vim.cmd(":silent ! "..cmd)
    -- vim.fn.jobstart(string.format("%s 'https://www.google.com/search?q=%s'", open_cmd, input))
  end)
end

return M
