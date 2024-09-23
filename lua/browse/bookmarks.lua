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
    local icons = config["icons"] or defaults.opts["icons"] or {}
    local persist_grouped_bookmarks_query = config["persist_grouped_bookmarks_query"]
        or defaults.opts["persist_grouped_bookmarks_query"]
        or false
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

    local function entry_maker(entry)
        local value, display, ordinal

        if type(entry) == "string" then
            value = entry
            display = entry
            ordinal = entry
        elseif type(entry) == "table" and type(entry[2]) ~= "table" then
            value = entry[2]
            display = entry[1] .. " " .. icons.bookmark_alias .. " " .. value
            ordinal = entry[1] .. entry[2]
        elseif type(entry) == "table" and type(entry[2]) == "table" then
            display = entry[1] .. " " .. icons.grouped_bookmarks
            ordinal = entry[1]

            for k, v in pairs(entry[2]) do
                ordinal = ordinal .. k .. v

                if type(k) == "string" then
                    display = display .. " " .. k
                else
                    display = display .. " " .. utils.get_domain(v)
                end
            end

            value = entry[2]
            display = display
            ordinal = ordinal
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
            prompt_title = icons.bookmarks_prompt .. "Bookmarks",
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

                        local search_bookmarks_opts = {
                            bookmarks = list,
                            visual_text,
                        }

                        if persist_grouped_bookmarks_query then
                            local query = action_state.get_current_line()

                            search_bookmarks_opts.default_text = query
                        end

                        -- search bookmarks with the new list
                        M.search_bookmarks(search_bookmarks_opts)
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
