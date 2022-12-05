local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local themes = require("telescope.themes")
local action_state = require("telescope.actions.state")

local utils = require("browse.utils")

local M = {}

-- search bookmarks
M.search_bookmarks = function(config, folder, pre_folders)
  local bookmarks = config["bookmarks"][folder] or config["bookmarks"] or {}
  local theme = themes.get_dropdown()
  local opts = vim.tbl_deep_extend("force", config, theme or {})

  -- Add an entry to the top of folders to go up the directory
  if folder and bookmarks[1] ~= ".." then
    table.insert(bookmarks, 1, "..")
  end
  
  pickers
    .new(opts, {
      prompt_title = "Bookmarks",
      finder = finders.new_table({
        results = bookmarks,
      }),

      sorter = conf.generic_sorter(opts),

      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()

          if not selection then
            return
          end
            
          -- Folders must begin with a "/"
          -- I'm sure there is another way to differentiate
          -- between folders and URLs but this was the simplest
          -- solution I have found.
          if selection[1]:sub(1, 1) ~= "/" and selection[1] ~= ".." then
            utils.default_search(selection[1])
            return
          end
            
          if folder then
            if selection[1] == ".." then
              if pre_folders then 
                local prev_folder = table.remove(pre_folders)
                M.search_bookmarks(config, prev_folder, pre_folders)
                return
              end
              M.search_bookmarks(config)
              return
            end
            pre_folders = pre_folders or {}
            table.insert(pre_folders, folder)  
            M.search_bookmarks(config, selection[1], pre_folders)
            return
          end
            
          M.search_bookmarks(config, selection[1])
        end)
        return true
      end,
    })
    :find()
end

return M
