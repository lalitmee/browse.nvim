local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local themes = require("telescope.themes")
local action_state = require("telescope.actions.state")

local utils = require("browse.utils")
local defaults = require("browse.config")

local M = {}

-- search bookmarks
M.search_bookmarks = function(config)
    local bookmarks = config["bookmarks"] or defaults.opts["bookmarks"] or {}
    local theme = themes.get_dropdown()
    local opts = vim.tbl_deep_extend("force", config, theme or {})

    local search = {}

    for k, v in pairs(bookmarks) do
        if type(k) == "string" then
            table.insert(search, { k, v })
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
                    -- when entry is a direct url
                    if type(entry) == "string" then
                        return {
                            value = entry,
                            display = entry,
                            ordinal = entry,
                        }
                    end

                    -- when entry is an alias for either a url or a format url
                    if type(entry[2]) == "string" then
                        return {
                            value = entry,
                            display = entry[1] .. " -> " .. entry[2],
                            ordinal = entry[2],
                        }
                    end
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

                    local url = selection["ordinal"]

                    if string.find(url, "=") then
                        utils.format_search(url)()
                    else
                        utils.default_search(url)
                    end
                end)
                return true
            end,
        })
        :find()
end

return M
