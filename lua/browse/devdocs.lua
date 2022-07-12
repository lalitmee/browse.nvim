local utils = require("browse.utils")

local M = {}

M.search_with_filetype = function()
  vim.ui.input("Search String: ", function(input)
    if input == nil or input == "" then
      return
    end
    local open_cmd = utils.get_open_cmd()
    local input_with_filetype = vim.bo.filetype .. " " .. input
    local url = string.format('https://devdocs.io/#q=%s', input_with_filetype)
    if utils.is_mac_os() then
      url = utils.urlencode(url)
    end
    vim.fn.jobstart(string.format("%s %s", open_cmd, url))
  end)
end

M.search = function()
  vim.ui.input("Search String: ", function(input)
    if input == nil or input == "" then
      return
    end
    local open_cmd = utils.get_open_cmd()
    local url = string.format('https://devdocs.io/#q=%s', input)
    if utils.is_mac_os() then
      url = utils.urlencode(url)
    end
    vim.fn.jobstart(string.format("%s %s", open_cmd, url))
  end)
end

return M
