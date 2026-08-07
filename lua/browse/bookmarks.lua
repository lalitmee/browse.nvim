local picker = require("browse.picker")

local utils = require("browse.utils")
local defaults = require("browse.config")
local bookmark_manager = require("browse.bookmark_manager")

local M = {}

local bookmark_history = {}

local function flatten_bookmarks(bookmarks)
    local flat_list = {}
    for k, v in pairs(bookmarks) do
        if k ~= "name" then
            if type(v) == "table" and v.url == nil then -- It's a group
                local nested_bookmarks = flatten_bookmarks(v)
                for _, nested_v in ipairs(nested_bookmarks) do
                    table.insert(flat_list, nested_v)
                end
            else -- It's a bookmark
                if type(k) == "string" then
                    table.insert(flat_list, { k, v })
                else
                    table.insert(flat_list, v)
                end
            end
        end
    end
    return flat_list
end

function M.get_bookmark_entries(bookmarks, show_nested, level)
    local bookmarks_list = {}
    local bookmarks_copy = vim.deepcopy(bookmarks)

    if not show_nested then
        bookmarks_copy = flatten_bookmarks(bookmarks_copy)
    end

    if level > 0 then
        table.insert(bookmarks_list, { "<- Back", "back" })
    end

    if not show_nested then
        for _, v in ipairs(bookmarks_copy) do
            table.insert(bookmarks_list, v)
        end
    else
        for k, v in pairs(bookmarks_copy) do
            if type(k) == "string" then
                table.insert(bookmarks_list, { k, v })
            else
                table.insert(bookmarks_list, v)
            end
        end
    end

    return bookmarks_list
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

local function remove_element(tbl, key)
    local new_tbl = {}
    for k, v in pairs(tbl) do
        if k ~= key then
            new_tbl[k] = v
        end
    end
    return new_tbl
end

local function build_entry(entry, max_len, icons)
    local value, display, ordinal
    local name = entry[1]

    if type(entry) == "string" then
        value = entry
        display = entry
        ordinal = entry
    elseif type(entry) == "table" and entry[2] == "back" then
        value = "back"
        display = entry[1]
        ordinal = "back"
    elseif type(entry) == "table" and type(entry[2]) ~= "table" then
        if type(name) ~= "string" then
            name = ""
        end
        local formatted_name =
            string.format("%-" .. max_len .. "s", name)
        value = entry[2]

        if type(value) == "table" and value.url then -- It's a browser bookmark
            local icon = icons[value.source] or icons.default_browser
            display = icon
                .. " "
                .. formatted_name
                .. " "
                .. icons.bookmark_alias
                .. " "
                .. value.url
            ordinal = name .. value.url
        else -- It's a regular bookmark
            display = formatted_name
                .. " "
                .. icons.bookmark_alias
                .. " "
                .. value
            ordinal = name .. value
        end
    elseif type(entry) == "table" and type(entry[2]) == "table" then
        if type(name) ~= "string" then
            name = ""
        end
        local formatted_name =
            string.format("%-" .. max_len .. "s", name)
        local group_table = entry[2]
        local count = count_items(group_table)
        local group_name = group_table.name or entry[1] -- Use inner name or fall back to key
        display = formatted_name
            .. " -> "
            .. group_name
            .. " ("
            .. count
            .. ")"
        ordinal = entry[1]
        value = group_table
    end

    return {
        value = value,
        display = display,
        ordinal = ordinal,
    }
end

M.search_bookmarks = function(config)
    config = config or {}

    local level = config.level or 0
    local source = config.source or "manual"
    local icons = config["icons"] or defaults.opts["icons"] or {}
    local persist_grouped_bookmarks_query =
        defaults.opts.persist_grouped_bookmarks_query
    local show_nested = defaults.opts.bookmark_picker.show_nested

    -- Use bookmark manager based on the source
    local bookmarks

    if config["bookmarks"] and not vim.tbl_isempty(config["bookmarks"]) then
        bookmarks = config["bookmarks"]
    elseif source == "browser" then
        bookmarks = bookmark_manager.get_browser_bookmarks()
    else
        bookmarks = bookmark_manager.get_manual_bookmarks()
    end

    if level == 0 then
        bookmark_history = { bookmarks }
    else
        table.insert(bookmark_history, bookmarks)
    end

    local visual_text = config["visual_text"]
    local bookmarks_list = M.get_bookmark_entries(bookmarks, show_nested, level)
    local picker_name = source == "browser" and "browser_bookmarks"
        or "manual_bookmarks"

    local max_len = 0
    for _, entry in ipairs(bookmarks_list) do
        local name = entry[1]
        if type(name) == "string" and #name > max_len then
            max_len = #name
        end
    end

    local entries = {}
    for _, entry in ipairs(bookmarks_list) do
        table.insert(entries, build_entry(entry, max_len, icons))
    end

    local prompt_title = icons.bookmarks_prompt .. "Bookmarks"
    if source == "browser" then
        prompt_title = icons.bookmarks_prompt .. "Browser Bookmarks"
    else
        prompt_title = icons.bookmarks_prompt .. "Manual Bookmarks"
    end

    local layout = defaults.opts.layouts and defaults.opts.layouts[picker_name]

    picker.pick(entries, {
        title = prompt_title,
        layout = layout,
        default_text = config.default_text or "",
        cache_picker = config.cache_picker,
        on_select = function(value, query)
            if value == "back" then
                table.remove(bookmark_history)
                local parent_bookmarks = table.remove(bookmark_history)
                M.search_bookmarks({
                    bookmarks = parent_bookmarks,
                    visual_text = visual_text,
                    level = level - 1,
                    cache_picker = config.cache_picker,
                    source = source,
                    default_text = persist_grouped_bookmarks_query and query or "",
                })
            elseif type(value) == "table" then
                -- copy table to avoid mutation
                local tbl_copy = vim.deepcopy(value)

                local list = remove_element(tbl_copy, "name")

                M.search_bookmarks({
                    bookmarks = list,
                    visual_text = visual_text,
                    level = level + 1,
                    cache_picker = config.cache_picker,
                    source = source,
                    default_text = persist_grouped_bookmarks_query and query or "",
                })
            elseif
                type(value) == "string"
                or (type(value) == "table" and value.url)
            then
                local url = type(value) == "string" and value
                    or value.url
                -- checking for `%%` in the url
                if string.match(url, "%%") then
                    utils.format_search(
                        url,
                        { prompt = "Enter query: " }
                    )(visual_text)
                else
                    utils.default_search(url)
                end
            else
                -- handle other types
                print("else", value)
            end
        end,
    })
end

return M