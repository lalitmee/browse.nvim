local config = require("browse.config")

local M = {}

local backends = {
    telescope = true,
    fzf_lua = true,
    mini_pick = true,
    snacks = true,
}

local warned = {}

local function get_adapter(name)
    return require("browse.picker." .. name)
end

local function resolve_backend()
    local configured = config.opts.picker or "telescope"
    if backends[configured] then
        return configured
    end
    -- Unknown backend name: fall back to telescope once
    if not warned[configured] then
        warned[configured] = true
        vim.notify(
            "browse.nvim: unknown picker backend '" .. configured .. "', falling back to telescope",
            vim.log.levels.WARN
        )
    end
    return "telescope"
end

function M.pick(entries, opts)
    opts = opts or {}

    local backend = resolve_backend()
    local adapter = get_adapter(backend)

    -- Unavailable configured backend: one-time WARN + telescope fallback.
    if not adapter.available() then
        if not warned[backend .. ":unavailable"] then
            warned[backend .. ":unavailable"] = true
            vim.notify(
                "browse.nvim: picker backend '" .. backend .. "' is not available, falling back to telescope",
                vim.log.levels.WARN
            )
        end
        backend = "telescope"
        adapter = get_adapter(backend)
    end

    -- Merge user per-backend passthrough opts. Call-site opts win.
    local passthrough = config.opts.picker_opts[backend] or {}
    local merged = vim.tbl_deep_extend("force", passthrough, opts)

    local ok, err = pcall(adapter.pick, entries, merged)
    if not ok then
        vim.notify(
            "browse.nvim: picker backend '" .. backend .. "' failed: " .. tostring(err),
            vim.log.levels.WARN
        )
        local fallback = get_adapter("telescope")
        pcall(fallback.pick, entries, merged)
    end
end

return M
