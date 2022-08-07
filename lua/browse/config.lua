local M = {}

local defaults = {
  provider = "google",
}

M.options = defaults

function M.setup(opts)
  M.options = vim.tbl_extend("keep", defaults, opts or {})
end

return M
