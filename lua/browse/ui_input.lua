local M = {}

M.search_ui_input = function()
  vim.ui.input({ prompt = "Search String: " }, function(input)
    if input == nil then
      return
    end
    vim.fn.jobstart(string.format("xdg-open 'https://www.google.com/search?q=%s'", input))
  end)
end

return M
