local config = require("browse.config")

local M = {}

local warned_layouts = {}

local layouts = {
    dropdown = function()
        return require("telescope.themes").get_dropdown()
    end,
    cursor = function()
        return require("telescope.themes").get_cursor()
    end,
    ivy = function()
        return require("telescope.themes").get_ivy()
    end,
}

local function theme_for(layout)
    if not layout or layout == "default" then
        return {}
    end
    local fn = layouts[layout]
    if not fn then
        if not warned_layouts[layout] then
            warned_layouts[layout] = true
            vim.notify(
                "browse.nvim: unknown layout '"
                    .. layout
                    .. "' for telescope backend, using default",
                vim.log.levels.WARN
            )
        end
        return {}
    end
    return fn()
end

function M.available()
    local ok, _ = pcall(require, "telescope.pickers")
    if not ok then
        return false
    end
    ok, _ = pcall(require, "telescope.finders")
    return ok
end

function M.pick(entries, opts)
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    local theme = theme_for(opts.layout)
    local picker_opts = vim.tbl_deep_extend("force", theme, opts)

    local sorter = conf.generic_sorter(picker_opts)
    if not config.opts.sort_results then
        -- preserve input order instead of fuzzy sorting
        sorter.tiebreak = function()
            return false
        end
    end

    pickers.new(picker_opts, {
        prompt_title = opts.title,
        default_text = opts.default_text,
        finder = finders.new_table({
            results = entries,
            entry_maker = function(entry)
                return {
                    value = entry.value,
                    display = entry.display,
                    ordinal = entry.ordinal,
                }
            end,
        }),
        sorter = sorter,
        attach_mappings = function(prompt_bufnr, _)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                if not selection then
                    if opts.on_cancel then
                        opts.on_cancel()
                    end
                    return
                end
                opts.on_select(selection.value, action_state.get_current_line())
            end)
            return true
        end,
    }):find()
end

return M
