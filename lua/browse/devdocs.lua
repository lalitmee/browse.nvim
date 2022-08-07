local utils = require("browse.utils")

local M = {}

M.search_with_filetype = utils.callback_search(function(input)
  local input_with_filetype = vim.bo.filetype .. " " .. input

  return string.format("https://devdocs.io/#q=%s", input_with_filetype)
end)

M.search = utils.format_search("https://devdocs.io/#q=%s")

return M
