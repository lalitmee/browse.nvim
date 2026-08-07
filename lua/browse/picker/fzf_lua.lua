local M = {}

local warned_layouts = {}

local layouts = {
    dropdown = function()
        return {
            winopts = {
                border = "rounded",
                width = 0.7,
                height = 0.6,
                row = 0.35,
                col = 0.5,
            },
        }
    end,
    cursor = function()
        return {
            winopts = {
                relative = "cursor",
                border = "rounded",
                width = 0.5,
                height = 0.4,
                row = 1,
                col = 0,
            },
        }
    end,
    ivy = function()
        return {
            winopts = {
                border = "rounded",
                width = 1.0,
                height = 0.4,
                row = 0.6,
                col = 0,
            },
        }
    end,
}

local function winopts_for(layout)
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
                    .. "' for fzf_lua backend, using default",
                vim.log.levels.WARN
            )
        end
        return {}
    end
    return vim.deepcopy(fn())
end

function M.available()
    local ok, _ = pcall(require, "fzf-lua")
    if not ok then
        return false
    end
    return vim.fn.executable("fzf") == 1
        or vim.fn.executable("sk") == 1
end

function M.pick(entries, opts)
    local fzf_lua = require("fzf-lua")

    local lines = {}
    local value_by_line = {}
    for _, entry in ipairs(entries) do
        local line = tostring(entry.ordinal) .. "\t" .. tostring(entry.display)
        table.insert(lines, line)
        value_by_line[line] = entry.value
    end

    local actions = {
        ["default"] = function(selected, action_opts)
            local line = selected and selected[1]
            local value = line and value_by_line[line]
            if value ~= nil then
                opts.on_select(value, action_opts.last_query)
            elseif opts.on_cancel then
                opts.on_cancel()
            end
        end,
    }
    if opts.on_cancel then
        actions.esc = function()
            opts.on_cancel()
        end
        actions["ctrl-c"] = function()
            opts.on_cancel()
        end
    end

    local user_winopts = opts.winopts or {}
    local winopts = vim.tbl_deep_extend(
        "force",
        winopts_for(opts.layout)["winopts"] or {},
        user_winopts
    )

    fzf_lua.fzf_exec(lines, {
        query = opts.default_text,
        prompt = (opts.title or "") .. " >",
        winopts = winopts,
        fzf_opts = {
            ["--delimiter"] = "\t",
            ["--nth"] = "1",
            ["--with-nth"] = "2",
        },
        actions = actions,
    })
end

return M
