local utils = require("browse.utils")

local M = {}

M.mdn_search = function()
  vim.ui.input("Search String: ", function(input)
    if input == nil or input == "" then
      return
    end
    local open_cmd = utils.get_open_cmd()
    vim.fn.jobstart(string.format("%s 'https://developer.mozilla.org/en-US/search?q=%s'", open_cmd, input))
  end)
end

return M
