local M = {}

-- get os name
local get_os_name = function()
    local os = vim.loop.os_uname()
    local os_name = os.sysname
    return os_name
end

-- WSL 
local is_wsl = function ()
    local output = vim.fn.systemlist "uname -r"
    return not not string.find(output[1] or "", "WSL")
end

-- get open cmd
local get_open_cmd = function()
    local os_name = get_os_name()

    local open_cmd = nil
    if os_name == "Windows_NT" or os_name == "Windows" then
        open_cmd = { "cmd", "/c", "start" }
    elseif os_name == "Darwin" then
        open_cmd = { "open" }
    else
        if is_wsl then
          open_cmd = { "wsl-open" }
        else
          open_cmd = { "xdg-open" }
        end
    end
    return open_cmd
end

local escape_target = function(target)
    local escapes = {
        [" "] = "%20",
        ["<"] = "%3C",
        [">"] = "%3E",
        ["#"] = "%23",
        ["%"] = "%25",
        ["+"] = "%2B",
        ["{"] = "%7B",
        ["}"] = "%7D",
        ["|"] = "%7C",
        ["\\"] = "%5C",
        ["^"] = "%5E",
        ["~"] = "%7E",
        ["["] = "%5B",
        ["]"] = "%5D",
        ["‘"] = "%60",
        [";"] = "%3B",
        ["/"] = "%2F",
        ["?"] = "%3F",
        [":"] = "%3A",
        ["@"] = "%40",
        ["="] = "%3D",
        ["&"] = "%26",
        ["$"] = "%24",
    }

    return target:gsub(".", escapes)
end

-- start the browser job
local open_browser = function(target)
    target = vim.fn.trim(target)
    local open_cmd = vim.fn.extend(get_open_cmd(), { target })

    vim.fn.jobstart(open_cmd, { detach = true })
end

M.default_search = function(input)
    open_browser(input)
end

-- a generic searching function used everywhere
M.search = function(target_fn, opts)
    local prompt = opts and opts.prompt or "Search String:"
    local default = opts and opts.visual_text or ""
    vim.ui.input({ prompt = prompt, default = default, kind = "browse" }, function(input)
        if input == nil or input == "" then
            return
        end

        local escaped_input = escape_target(vim.fn.trim(input))
        M.default_search(target_fn(escaped_input))
    end)
end

-- a generic searching closure util
M.callback_search = function(custom_fn, opts)
    return function(visual_text)
        opts.visual_text = visual_text
        M.search(custom_fn, opts)
    end
end

-- a generic searching for a format
M.format_search = function(format, opts)
    return function(visual_text)
        opts.visual_text = visual_text
        M.search(function(input)
            return string.format(format, input)
        end, opts)
    end
end

-- get selected text from visual mode (via a temp register)
M.get_visual_text = function()
    local reg_bak = vim.fn.getreg("v")
    vim.fn.setreg("v", {})
    vim.cmd([[noau normal! "vy\<esc\>]])
    local sel_text = vim.fn.getreg("v")
    vim.fn.setreg("v", reg_bak)
    return string.gsub(sel_text, "\n", "")
end

return M
