local utils = require("browse.utils")

local M = {}

M.search = utils.format_search("https://developer.mozilla.org/en-US/search?q=%s")

return M
