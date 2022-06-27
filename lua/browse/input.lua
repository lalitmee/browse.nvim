local utils = require("browse.utils")

local M = {}

M.search_input = function()
  vim.ui.input("Search String: ", function(input)
    if input == nil or input == "" then
      return
    end
    local open_cmd = utils.get_open_cmd()
    local path = "https://www.google.com/search?q=" .. input
    vim.fn.jobstart({ open_cmd, path }, { detach = true })
  end)
end

return M
