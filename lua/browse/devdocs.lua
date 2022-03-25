local utils = require("browse.utils")

local M = {}

M.devdocs_search = function()
  vim.ui.input("Search String: ", function(input)
    if input == nil or input == "" then
      return
    end
    local open_cmd = utils.get_open_cmd()
    local input_with_filetype = vim.bo.filetype .. " " .. input
    vim.fn.jobstart(string.format("%s 'https://devdocs.io/#q=%s'", open_cmd, input_with_filetype))
  end)
end

M.devdocs_search_without_filetype = function()
  vim.ui.input("Search String: ", function(input)
    if input == nil or input == "" then
      return
    end
    local open_cmd = utils.get_open_cmd()
    vim.fn.jobstart(string.format("%s 'https://devdocs.io/#q=%s'", open_cmd, input))
  end)
end

return M
