local browser = require("browse.browser")

local M = {}

M.search_with_filetype = browser.generic_search_custom(function(input)
  local input_with_filetype = vim.bo.filetype .. " " .. input

  return string.format("https://devdocs.io/#q=%s", input_with_filetype)
end)

M.search = browser.generic_search_for("https://devdocs.io/#q=%s")

return M
