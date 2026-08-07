local picker = require("browse.picker")

local search_bookmarks = require("browse.bookmarks").search_bookmarks
local search_input = require("browse.input").search_input
local devdocs = require("browse.devdocs")
local mdn = require("browse.mdn")
local defaults = require("browse.config")

local browse = function(config)
    config = config or {}
    local visual_text = config["visual_text"] or ""

    picker.pick(
        {
            { value = "manual_bookmarks", display = "Manual Bookmarks", ordinal = "manual_bookmarks" },
            { value = "browser_bookmarks", display = "Browser Bookmarks", ordinal = "browser_bookmarks" },
            { value = "devdocs", display = "Devdocs Search", ordinal = "devdocs" },
            { value = "devdocs_file", display = "Devdocs Search with filetype", ordinal = "devdocs_file" },
            { value = "input", display = "Input Search", ordinal = "input" },
            { value = "mdn", display = "MDN Web Docs", ordinal = "mdn" },
        },
        {
            title = "Browse",
            layout = defaults.opts.layouts.browse,
            default_text = config.default_text,
            on_select = function(value, _)
                if value == "manual_bookmarks" then
                    search_bookmarks({
                        source = "manual",
                        visual_text = visual_text,
                        cache_picker = { num_pickers = defaults.opts.cache_pickers },
                    })
                elseif value == "browser_bookmarks" then
                    search_bookmarks({
                        source = "browser",
                        visual_text = visual_text,
                        cache_picker = { num_pickers = defaults.opts.cache_pickers },
                    })
                elseif value == "input" then
                    search_input(visual_text)
                elseif value == "devdocs" then
                    devdocs.search(visual_text)
                elseif value == "devdocs_file" then
                    devdocs.search_with_filetype(visual_text)
                elseif value == "mdn" then
                    mdn.search(visual_text)
                end
            end,
        }
    )
end

local M = {
    browse = browse,
    input_search = search_input,
    open_manual_bookmarks = function(config)
        config = config or {}
        config.source = "manual"
        config.cache_picker = { num_pickers = defaults.opts.cache_pickers }
        search_bookmarks(config)
    end,
    open_browser_bookmarks = function(config)
        config = config or {}
        config.source = "browser"
        config.cache_picker = { num_pickers = defaults.opts.cache_pickers }
        search_bookmarks(config)
    end,
    devdocs = devdocs,
    mdn = mdn,
}

function M._get_visual_selection()
    local _, start_row, start_col, _ = unpack(vim.fn.getpos("'<"))
    local _, end_row, end_col, _ = unpack(vim.fn.getpos("'>"))
    if start_row > end_row or (start_row == end_row and start_col > end_col) then
        start_row, end_row = end_row, start_row
        start_col, end_col = end_col, start_col
    end
    local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
    if #lines == 0 then return "" end
    lines[#lines] = string.sub(lines[#lines], 1, end_col)
    lines[1] = string.sub(lines[1], start_col)
    return table.concat(lines, "\n")
end

function M._command_dispatcher(args)
    local subcommand = args.fargs[1]
    local visual_text = ""
    if args.range > 0 then
        visual_text = M._get_visual_selection()
    end

    if subcommand == nil then
        M.browse()
    elseif subcommand == "input" then
        M.input_search(visual_text)
    elseif subcommand == "mdn" then
        M.mdn.search(visual_text)
    elseif subcommand == "mdn_ft" then
        M.mdn.search_with_filetype(visual_text)
    elseif subcommand == "devdocs" then
        M.devdocs.search(visual_text)
    elseif subcommand == "devdocs_ft" then
        M.devdocs.search_with_filetype(visual_text)
    elseif subcommand == "bookmarks" then
        require("browse.bookmarks").search_bookmarks({ source = "all", visual_text = visual_text })
    elseif subcommand == "bookmarks_manual" then
        M.open_manual_bookmarks()
    elseif subcommand == "bookmarks_browser" then
        M.open_browser_bookmarks()
    else
        vim.notify("Unknown browse.nvim subcommand: " .. subcommand, vim.log.levels.ERROR)
    end
end

function M.setup(opts)
    defaults.setup(opts)

    if defaults.opts.create_commands then
        vim.api.nvim_create_user_command(
            "Browse",
            function(args) M._command_dispatcher(args) end,
            { nargs = "*", range = true, complete = "customlist,v:lua.require'browse.utils'.command_completer" }
        )
    end
end

return M
