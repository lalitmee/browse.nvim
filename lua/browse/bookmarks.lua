local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local themes = require("telescope.themes")
local action_state = require("telescope.actions.state")

local utils = require("browse.utils")

local M = {}

-- search bookmarks
M.search_bookmarks = function(config)
  local bookmarks = config["bookmarks"] or {}
  local theme = themes.get_dropdown()
  local opts = vim.tbl_deep_extend("force", config, theme or {})
  pickers.new(opts, {
    prompt_title = "Bookmarks",
    finder = finders.new_table({
      results = bookmarks,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        local open_cmd = utils.get_open_cmd()
        local cmd = open_cmd .. " " .. selection[1]
        vim.fn.jobstart(cmd)
      end)
      return true
    end,
  }):find()
end

return M
