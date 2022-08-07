local utils = require("browse.utils")

local M = {}

M.search = utils.generic_search_for("https://developer.mozilla.org/en-US/search?q=%s")

return M
