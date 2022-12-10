local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local themes = require("telescope.themes")
local action_state = require("telescope.actions.state")

local utils = require("browse.utils")

local M = {}

-- search bookmarks
M.search_bookmarks = function(config, folder, prev_dirs)
  local bookmarks = folder or config["bookmarks"] or {}
  local theme = themes.get_dropdown()
  local opts = vim.tbl_deep_extend("force", config, theme or {})

  local search = {}
  
  if folder then
    table.insert(search, "..")
  end
  
  for k, v in pairs(bookmarks) do
    if type(k) == "string" then
      table.insert(search, {k, v})
    else
      table.insert(search, v)
    end
  end
  
  pickers
    .new(opts, {
      prompt_title = "Bookmarks",
      finder = finders.new_table({
        results = search,
        entry_maker = function(entry)
          -- Entry is a URL
          if type(entry) == "string" then
            return {
              value = entry,
              display = entry,
              ordinal = entry,
            }
          end
          
          -- Entry is an alias
          if type(entry[2]) == "string" then
            return {
              value = entry,
              display = entry[1],
              ordinal = entry[2],
            }
          end
            
          -- Entry is a folder
          return {
              value = entry,
              display = entry[1],
              ordinal = entry[1],
          }
        end,
      }),

      sorter = conf.generic_sorter(opts),

      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()

          if not selection then
            return
          end
            
          if selection["ordinal"] == ".." then
            local dir = table.remove(prev_dirs, 1)
            M.search_bookmarks(config, dir, prev_dirs)
            return
          end
            
          if bookmarks[selection["ordinal"]] then
            prev_dirs = prev_dirs or {}
            table.insert(prev_dirs, folder)
            M.search_bookmarks(config, bookmarks[selection["ordinal"]], prev_dirs)
            return
          end
            
          utils.default_search(selection["ordinal"])
        end)
        return true
      end,
    })
    :find()
end

return M
