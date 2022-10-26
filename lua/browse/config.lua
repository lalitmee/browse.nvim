local M = {}

local defaults = {
    provider = "google",
}

M.options = defaults

function M.setup(opts)
    M.options = vim.tbl_extend("keep", opts, opts or defaults)
end

return M
