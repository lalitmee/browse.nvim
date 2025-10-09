local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local themes = require("telescope.themes")
local action_state = require("telescope.actions.state")

local utils = require("browse.utils")
local defaults = require("browse.config")
local bookmark_manager = require("browse.bookmark_manager")

local M = {}

M.search_bookmarks = function(config)
    config = config or {}
    local level = config.level or 0
    local icons = config["icons"] or defaults.opts["icons"] or {}
    local persist_grouped_bookmarks_query = config["persist_grouped_bookmarks_query"]
        or defaults.opts["persist_grouped_bookmarks_query"]
        or false

    -- Use bookmark manager if no specific bookmarks provided
    local bookmarks
    if config["bookmarks"] and not vim.tbl_isempty(config["bookmarks"]) then
        bookmarks = config["bookmarks"]
    else
        bookmarks = bookmark_manager.get_bookmarks()
    end

    local visual_text = config["visual_text"]
    local bookmarks_copy = vim.deepcopy(bookmarks)
    local theme = themes.get_dropdown()
    local opts = vim.tbl_deep_extend("force", config, theme or {})

    local bookmarks_list = {}

    if level > 0 then
        table.insert(bookmarks_list, { "<- Back", "back" })
    end

    for k, v in pairs(bookmarks_copy) do
        if type(k) == "string" then
            table.insert(bookmarks_list, { k, v })
        else
            table.insert(bookmarks_list, v)
        end
    end

    local function count_items(tbl)
        local count = 0
        for k, _ in pairs(tbl) do
            if k ~= "name" then
                count = count + 1
            end
        end
        return count
    end

    local max_len = 0
    for _, entry in ipairs(bookmarks_list) do
        local name = entry[1]
        if type(name) == "string" and #name > max_len then
            max_len = #name
        end
    end

    local function entry_maker(entry)
        local value, display, ordinal
        local name = entry[1]
        local formatted_name = string.format("%-" .. max_len .. "s", name)

        if type(entry) == "string" then
            value = entry
            display = entry
            ordinal = entry
        elseif type(entry) == "table" and entry[2] == "back" then
            value = "back"
            display = entry[1]
            ordinal = "back"
        elseif type(entry) == "table" and type(entry[2]) ~= "table" then
            value = entry[2]
            display = formatted_name .. " " .. icons.bookmark_alias .. " " .. value
            ordinal = entry[1] .. entry[2]
        elseif type(entry) == "table" and type(entry[2]) == "table" then
            local count = count_items(entry[2])
            display = formatted_name .. " " .. icons.grouped_bookmarks .. " " .. count
            ordinal = entry[1]
            value = entry[2]
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

    local sorter
    if defaults.opts.sort_results then
        sorter = conf.generic_sorter(opts)
    else
        sorter = conf.generic_sorter(opts)
        sorter.tiebreak = function() return false end
    end

    pickers
        .new(opts, {
            prompt_title = icons.bookmarks_prompt .. "Bookmarks",
            finder = create_finder(),
            sorter = sorter,
            attach_mappings = function(prompt_bufnr, _) 
                actions.select_default:replace(function()
                    local selection = action_state.get_selected_entry()
                    if not selection then
                        actions.close(prompt_bufnr)
                        return
                    end

                    local value = selection["value"]
                    actions.close(prompt_bufnr)

                    if value == "back" then
                        require("telescope.builtin").resume({ cache_index = 2 })
                    elseif type(value) == "table" then
                        -- copy table to avoid mutation
                        local tbl_copy = vim.deepcopy(value)

                        local list = remove_element(tbl_copy, "name")

                        local search_bookmarks_opts = {
                            bookmarks = list,
                            visual_text = visual_text,
                            level = level + 1,
                            cache_picker = opts.cache_picker,
                        }

                        if persist_grouped_bookmarks_query then
                            local query = action_state.get_current_line()

                            search_bookmarks_opts.default_text = query
                        end

                        -- search bookmarks with the new list
                        M.search_bookmarks(search_bookmarks_opts)
                    elseif type(value) == "string" then
                        -- checking for `%%` in the url
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
