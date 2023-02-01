local M = {}

local defaults = {
    provider = "google",
}

M.opts = defaults

function M.setup(opts)
    opts = opts or {}
    M.opts = vim.tbl_deep_extend("force", M.opts, opts)
end

return M
