local browser = require("browse.browser")

local M = {}

M.search = browser.generic_search_for("https://developer.mozilla.org/en-US/search?q=%s")

return M
