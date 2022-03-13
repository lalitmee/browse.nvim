local M = {}

-- get os name
M.get_os_name = function()
  local os = vim.loop.os_uname()
  local os_name = os.sysname
  return os_name
end

-- get open command
M.get_open_cmd = function()
  local os_name = M.get_os_name()
  local open_cmd = nil
  if os_name == "Windows" then
    open_cmd = "start"
  elseif os_name == "Darwin" then
    open_cmd = "open"
  else
    open_cmd = "xdg-open"
  end
  return open_cmd
end

return M
