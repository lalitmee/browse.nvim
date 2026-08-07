local M = {}

local warned_layouts = {}

local layouts = {
    dropdown = function()
        return {
            config = {
                relative = "editor",
                border = "rounded",
                anchor = "NW",
                width = 0.7,
                height = 0.6,
                row = 0.15,
                col = 0.5,
            },
        }
    end,
    cursor = function()
        return {
            config = {
                relative = "cursor",
                border = "rounded",
                anchor = "NW",
                width = 0.5,
                height = 0.4,
                row = 1,
                col = 0,
            },
        }
    end,
    ivy = function()
        return {
            config = {
                relative = "editor",
                border = "rounded",
                anchor = "SW",
                width = 1.0,
                height = 0.4,
                row = 0.6,
                col = 0,
            },
        }
    end,
}

local function window_config(layout)
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
                    .. "' for mini_pick backend, using default",
                vim.log.levels.WARN
            )
        end
        return {}
    end
    return vim.deepcopy(fn())
end

function M.available()
    return _G.MiniPick ~= nil
end

function M.pick(entries, opts)
    local items = {}
    for _, entry in ipairs(entries) do
        table.insert(items, {
            text = entry.display,
            value = entry.value,
        })
    end

    local source = {
        items = items,
        name = opts.title or "",
        choose = function(item)
            local query = table.concat(_G.MiniPick.get_picker_query())
            opts.on_select(item.value, query)
            return nil -- close the picker
        end,
    }

    if opts.default_text and #opts.default_text > 0 then
        local default_text = opts.default_text
        vim.schedule(function()
            _G.MiniPick.set_picker_query(vim.split(default_text, ""))
        end)
    end

    local window = window_config(opts.layout)
    window.config = vim.tbl_deep_extend("force", window.config or {}, opts.window or {})

    local chosen = _G.MiniPick.start({
        source = source,
        window = window,
    })

    -- start returns nil when aborted; fire on_cancel when provided
    if chosen == nil and opts.on_cancel then
        opts.on_cancel()
    end
end

return M
