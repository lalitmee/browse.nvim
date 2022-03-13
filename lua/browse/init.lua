local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local themes = require("telescope.themes")

local search_bookmarks = require("browse.bookmarks").search_bookmarks
local input_search = require("browse.input").search_input

local browse = function(config)
  local bookmarks = config["bookmarks"] or {}
  for k, v in pairs(config) do
    if k == "bookmarks" then
      bookmarks = v
    end
  end
  local theme = themes.get_dropdown()
  local opts = vim.tbl_deep_extend("force", config, theme or {})
  pickers.new(opts, {
    prompt_title = "Browse",
    finder = finders.new_table({
      results = {
        { "Bookmarks", "bookmarks" },
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
          search_bookmarks({ bookmarks = bookmarks })
          return
        end
        if browse_selection == "input" then
          input_search()
          return
        end
      end)
      return true
    end,
  }):find()
end

return {
  browse = browse,
  input_search = input_search,
  open_bookmarks = search_bookmarks,
}
