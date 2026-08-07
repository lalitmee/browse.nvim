local M = {}

local warned_layouts = {}

local PRESETS = {
    dropdown = "select",
    cursor = "select",
    ivy = "ivy",
    top = "top",
    vertical = "vertical",
}

local function layout_name(layout)
    if not layout or layout == "default" then
        return nil
    end
    local preset = PRESETS[layout]
    if not preset then
        if not warned_layouts[layout] then
            warned_layouts[layout] = true
            vim.notify(
                "browse.nvim: unknown layout '"
                    .. layout
                    .. "' for snacks backend, using default layout",
                vim.log.levels.WARN
            )
        end
        return nil
    end
    return preset
end

function M.available()
    local snacks_ok = pcall(require, "snacks")
    return snacks_ok
end

function M.pick(entries, opts)
    local snacks = require("snacks")

    local confirmed = false
    local build = {
        items = {},
        title = opts.title,
        format = "text",
        pattern = opts.default_text,
        confirm = function(picker, item)
            confirmed = true
            picker:close()
            if item then
                opts.on_select(item.value, picker.input:get())
            end
        end,
    }

    if opts.on_cancel then
        build.on_close = function()
            if not confirmed then
                opts.on_cancel()
            end
        end
    end

    local layout = layout_name(opts.layout)
    if layout then
        build.layout = layout
    end

    for _, entry in ipairs(entries) do
        table.insert(build.items, {
            text = entry.display,
            value = entry.value,
            ordinal = entry.ordinal,
        })
    end

    snacks.picker.pick(build)
end

return M