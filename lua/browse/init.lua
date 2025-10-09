local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local themes = require("telescope.themes")

local search_bookmarks = require("browse.bookmarks").search_bookmarks
local search_input = require("browse.input").search_input
local devdocs = require("browse.devdocs")
local mdn = require("browse.mdn")
local defaults = require("browse.config")
local get_visual_text = require("browse.utils").get_visual_text

local browse = function(config)
    config = config or {}

    local bookmarks = config["bookmarks"] or defaults.opts["bookmarks"] or {}
    local visual_text = get_visual_text()

    local theme = themes.get_dropdown()
    local opts = vim.tbl_deep_extend("force", config, theme or {})

    pickers
        .new(opts, {
            prompt_title = "Browse",

            finder = finders.new_table({
                results = {
                    { "Bookmarks Search", "bookmarks" },
                    { "Devdocs Search", "devdocs" },
                    { "Devdocs Search with filetype", "devdocs_file" },
                    { "Input Search", "input" },
                    { "MDN Web Docs", "mdn" },
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
                        search_bookmarks({
                            bookmarks = bookmarks,
                            visual_text = visual_text,
                            cache_picker = { num_pickers = defaults.opts.cache_pickers },
                        })
                    elseif browse_selection == "input" then
                        search_input(visual_text)
                    elseif browse_selection == "devdocs" then
                        devdocs.search(visual_text)
                    elseif browse_selection == "devdocs_file" then
                        devdocs.search_with_filetype(visual_text)
                    elseif browse_selection == "mdn" then
                        mdn.search(visual_text)
                    end
                end)
                return true
            end,
        })
        :find()
end

local M = {
    browse = browse,
    input_search = function()
        search_input(get_visual_text())
    end,
    open_bookmarks = function(config)
        config = config or {}
        config.visual_text = get_visual_text()
        config.cache_picker = { num_pickers = defaults.opts.cache_pickers }
        search_bookmarks(config)
    end,
    devdocs = devdocs,
    mdn = mdn,
}

function M.setup(opts)
    defaults.setup(opts)

    if defaults.opts.create_commands then
        local function command(name, rhs, cmd_opts)
            cmd_opts = cmd_opts or {}
            vim.api.nvim_create_user_command(name, rhs, cmd_opts)
        end

        command("Browse", function() M.browse() end, {})
        command("BrowseBookmarks", function() M.open_bookmarks() end, {})
        command("BrowseSearch", function() M.input_search() end, {})
        command("DevdocsSearch", function() M.devdocs.search() end, {})
        command("DevdocsFiletypeSearch", function() M.devdocs.search_with_filetype() end, {})
        command("MdnSearch", function() M.mdn.search() end, {})
    end
end

return M
