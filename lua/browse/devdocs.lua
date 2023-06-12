local utils = require("browse.utils")

local M = {}

M.search_with_filetype = utils.callback_search(function(input)
    local input_with_filetype = vim.bo.filetype .. "%20" .. input

    return string.format("https://devdocs.io/#q=%s", input_with_filetype)
end, { prompt = "devdocs.io filetype search:" })

M.search = utils.format_search(
    "https://devdocs.io/#q=%s",
    { prompt = "devdocs.io query search:" }
)

return M
