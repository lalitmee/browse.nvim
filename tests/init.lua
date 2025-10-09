-- Test runner for browse.nvim
-- Minimal init to avoid loading user config
vim.o.loadplugins = false
vim.cmd('set rtp&')

local plenary_dir = os.getenv("PLENARY_DIR") or "/tmp/plenary.nvim"
local browse_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")

-- Add paths to runtime path
vim.opt.rtp:prepend(plenary_dir)
vim.opt.rtp:prepend(browse_dir)

-- Add tests directory to package path
package.path = package.path .. ";" .. browse_dir .. "/?.lua"
package.path = package.path .. ";" .. browse_dir .. "/tests/?.lua"
package.path = package.path .. ";" .. browse_dir .. "/tests/helpers/?.lua"

require("plenary.busted")
