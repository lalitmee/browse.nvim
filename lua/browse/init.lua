----------------------------------------------------------------------
-- NOTE: telescope open links {{{
----------------------------------------------------------------------
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local themes = require("telescope.themes")

local search_bookmarks = require("browse.bookmarks").search_bookmarks
local search_ui_input = require("browse.ui_input").search_ui_input
local search_input = require("browse.input").search_input

local browse = function(opts)
  opts = opts or {}
  pickers.new(opts, {
    prompt_title = "Bookmarks",
    finder = finders.new_table({
      results = {
        { "Bookmarks", "bookmarks" },
        { "UI", "ui" },
        { "Input", "input" },
      },
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry[1],
          ordinal = entry[2],
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        local browse_selection = selection["ordinal"]
        if browse_selection == "bookmarks" then
          search_bookmarks()
          return
        end
        if browse_selection == "ui" then
          search_ui_input()
          return
        end
        if browse_selection == "input" then
          search_input()
          return
        end
      end)
      return true
    end,
  }):find()
end

lk.command({
  "Browse",
  function()
    browse(themes.get_dropdown())
  end,
})

-- vim:foldmethod=marker
