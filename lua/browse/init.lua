local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local themes = require("telescope.themes")

local search_bookmarks = require("browse.bookmarks").search_bookmarks
local input_search = require("browse.input").search_input
local devdocs = require("browse.devdocs")
local mdn = require("browse.mdn")
local config_setup = require("browse.config")

local browse = function(config)
	local config = config or {}
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
        { "Devdocs Search", "devdocs" },
        { "Devdocs Search For Filetype", "devdocs_file" },
        { "Input", "input" },
        { "MDN", "mdn" },
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
				elseif browse_selection == "input" then
          input_search()
				elseif browse_selection == "devdocs" then
          devdocs.search()
				elseif browse_selection == "devdocs_file" then
          devdocs.search_with_filetype()
				elseif browse_selection == "mdn" then
          mdn.search()
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
  devdocs = devdocs,
  mdn = mdn,
  setup = config_setup.setup,
}
