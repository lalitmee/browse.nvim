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
    local visual_text = config["visual_text"]
    local bookmarks_copy = vim.deepcopy(bookmarks)
    local theme = themes.get_dropdown()
    local opts = vim.tbl_deep_extend("force", config, theme or {})

    local bookmarks_list = {}

    for k, v in pairs(bookmarks_copy) do
        if type(k) == "string" then
            table.insert(bookmarks_list, { k, v })
        else
            table.insert(bookmarks_list, v)
        end
    end

    local function get_domain(url)
        return string.match(url, "https?://([^/]+)")
    end

    local function entry_maker(entry)
        local value, display, ordinal

        if type(entry) == "string" then
            value = entry
            display = entry
            ordinal = entry
        elseif type(entry) == "table" and type(entry[2]) ~= "table" then
            value = entry[2]
            display = entry[1] .. " -> " .. value
            ordinal = entry[1] .. entry[2]
        elseif type(entry) == "table" and type(entry[2]) == "table" then
            value = entry[2]
            display = entry[1] .. " -> " .. (entry[2]["name"] or "")
            ordinal = (entry[2]["name"] or "")
        end

        return {
            value = value,
            display = display,
            ordinal = ordinal,
        }
    end

    local function create_finder()
        return finders.new_table({
            results = bookmarks_list,
            entry_maker = entry_maker,
        })
    end

    local function remove_element(tbl, key)
        local new_tbl = {}
        for k, v in pairs(tbl) do
            if k ~= key then
                new_tbl[k] = v
            end
        end
        return new_tbl
    end

    pickers
        .new(opts, {
            prompt_title = "󰂺 Bookmarks",
            finder = create_finder(),
            sorter = conf.generic_sorter(opts),
            attach_mappings = function(prompt_bufnr, _)
                actions.select_default:replace(function()
                    actions.close(prompt_bufnr)

                    local selection = action_state.get_selected_entry()

                    if not selection then
                        return
                    end

                    local value = selection["value"]

                    if type(value) == "table" then
                        -- copy table to avoid mutation
                        local tbl_copy = vim.deepcopy(value)

                        local list = remove_element(tbl_copy, "name")

                        -- search bookmarks with the new list
                        M.search_bookmarks({ bookmarks = list, visual_text })
                    elseif type(value) == "string" then
                        -- checking for `%` in the url
                        if string.match(value, "%%") then
                            utils.format_search(
                                value,
                                { prompt = "Enter query: " }
                            )(visual_text)
                        else
                            utils.default_search(value)
                            vim.notify(string.format("Opening '%s'", value))
                        end
                    else
                        -- handle other types
                        print("else", value)
                    end
                end)

                return true
            end,
        })
        :find()
end

return M
