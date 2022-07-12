local M = {}

M.urlencode = function (str)
   str = string.gsub (str, "([^0-9a-zA-Z :/#!'()*._~-])",
      function (c) return string.format ("%%%02X", string.byte(c)) end)
   str = string.gsub (str, " ", "+")
   return str
end

-- get os name
M.get_os_name = function()
  local os = vim.loop.os_uname()
  local os_name = os.sysname
  return os_name
end

M.is_mac_os = function()
  local os_name = M.get_os_name()
  return os_name == "Darwin"
end

-- get open command
M.get_open_cmd = function()
  local os_name = M.get_os_name()
  -- vim.cmd("echo '"..os_name.."'")
  local open_cmd = nil
  if os_name == "Windows_NT" or os_name == "Windows" then
    open_cmd = "start"
  elseif os_name == "Darwin" then
    open_cmd = "open -u"
  else
    open_cmd = "xdg-open"
  end
  return open_cmd
end

return M
