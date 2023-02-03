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
    config = config or {}
    local bookmarks = config["bookmarks"] or defaults.opts["bookmarks"] or {}
    local theme = themes.get_dropdown()
    local opts = vim.tbl_deep_extend("force", config, theme or {})

    local bookmarks_list = {}

    for k, v in pairs(bookmarks) do
        if type(k) == "string" then
            table.insert(bookmarks_list, { k, v })
        else
            table.insert(bookmarks_list, v)
        end
    end

    local function create_finder()
        return finders.new_table({
            results = bookmarks_list,
            entry_maker = function(entry)
                -- when entry is a direct url
                if type(entry) == "string" then
                    return {
                        value = entry,
                        display = entry,
                        ordinal = entry,
                    }
                -- when entry is an alias for either a url or a format url
                elseif type(entry) == "table" and type(entry[2]) ~= "table" then
                    return {
                        value = entry[2],
                        display = entry[1] .. " -> " .. entry[2],
                        ordinal = entry[1] .. " " .. entry[2],
                    }
                -- when entry is a group of bookmarks
                elseif type(entry) == "table" and type(entry[2]) == "table" then
                    return {
                        value = entry[2],
                        display = entry[1]
                            .. " -> "
                            .. (entry[2]["name"] or ""),
                        ordinal = entry[1] .. " " .. (entry[2]["name"] or ""),
                    }
                end
            end,
        })
    end

    pickers
        .new(opts, {
            prompt_title = "Bookmarks",
            finder = create_finder(),
            sorter = conf.generic_sorter(opts),
            attach_mappings = function(prompt_bufnr, _)
                actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()
                    local value = selection["value"]

                    if not selection then
                        return
                    end

                    local function remove_element(tbl, key)
                        local element = tbl[key]
                        local new_tbl = {}
                        for k, v in pairs(tbl) do
                            if k ~= key then
                                new_tbl[k] = v
                            end
                        end
                        return element, new_tbl
                    end

                    if type(value) == "table" then
                        local _, list = remove_element(value, "name")
                        M.search_bookmarks({ bookmarks = list })
                    else
                        -- checking for `%` in the url
                        if string.match(value, "%%") then
                            utils.format_search(value)()
                        else
                            utils.default_search(value)
                            vim.notify(string.format("Opening '%s'", value))
                        end
                    end
                end)
                return true
            end,
        })
        :find()
end

return M
