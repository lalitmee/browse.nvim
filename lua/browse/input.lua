local M = {}

M.search_input = function()
  local input = vim.fn.input("Search String: ")
  if input == nil then
    return
  end
  vim.fn.jobstart(string.format("xdg-open 'https://www.google.com/search?q=%s'", input))
end

return M
