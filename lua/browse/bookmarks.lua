local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local M = {}

local bookmarks = {}

-- our picker function: colors
M.search_bookmarks = function(opts)
  opts = opts or {}
  pickers.new(opts, {
    prompt_title = "Bookmarks",
    finder = finders.new_table({
      results = bookmarks,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry[2],
          ordinal = entry[2],
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        local search_url = selection["display"]
        -- print(selection["display"])
        vim.fn.jobstart(string.format("xdg-open '%s'", search_url))
      end)
      return true
    end,
  }):find()
end

return M
