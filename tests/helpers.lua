local M = {}

-- Mock vim functions for testing
M.setup_mocks = function()
    -- Mock vim.fn functions
    _G.vim = _G.vim or {}
    _G.vim.fn = _G.vim.fn or {}
    _G.vim.loop = _G.vim.loop or {}
    _G.vim.ui = _G.vim.ui or {}
    _G.vim.bo = _G.vim.bo or {}
    _G.vim.notify = _G.vim.notify or function() end

    -- Mock file system operations
    _G.vim.fn.filereadable = function(path)
        return 1 -- assume files exist for testing
    end

    _G.vim.fn.readfile = function(path)
        return {} -- return empty for default
    end

    _G.vim.fn.expand = function(path)
        return path:gsub("~", "/home/testuser")
    end

    _G.vim.fn.trim = function(str)
        return str:match("^%s*(.-)%s*$")
    end

    _G.vim.fn.jobstart = function()
        return 1 -- mock job id
    end

    _G.vim.fn.extend = function(base, extra)
        for _, v in ipairs(extra) do
            table.insert(base, v)
        end
        return base
    end
    
    _G.vim.fn.json_encode = function(data)
        -- Simple JSON encoder for testing
        if type(data) == "table" then
            local result = "{"
            local first = true
            for k, v in pairs(data) do
                if not first then result = result .. "," end
                first = false
                result = result .. '"' .. tostring(k) .. '"'
                if type(v) == "table" then
                    result = result .. ":" .. _G.vim.fn.json_encode(v)
                else
                    result = result .. ':"' .. tostring(v) .. '"'
                end
            end
            result = result .. "}"
            return result
        else
            return '"' .. tostring(data) .. '"'
        end
    end
    
    _G.vim.fn.writefile = function(lines, path)
        -- Mock writefile that succeeds
        return 0
    end
    
    _G.vim.fn.glob = function(pattern, nosuf, list)
        -- Mock glob that returns empty by default
        return list and {} or ""
    end

    -- Mock uname for OS detection
    _G.vim.loop.os_uname = function()
        return { sysname = "Linux" }
    end
    
    _G.vim.loop.now = function()
        return 1000000000 -- Mock current time in nanoseconds
    end

    _G.vim.fn.systemlist = function(cmd)
        if cmd:match("uname") then
            return { "Linux" }
        end
        return {}
    end

    -- Mock UI input
    _G.vim.ui.input = function(opts, callback)
        callback("test query")
    end

    -- Mock buffer options
    _G.vim.bo.filetype = "lua"

    -- Mock table utilities
    _G.vim.tbl_deep_extend = function(behavior, ...)
        local result = {}
        for _, tbl in ipairs({...}) do
            for k, v in pairs(tbl) do
                result[k] = v
            end
        end
        return result
    end

    _G.vim.deepcopy = function(tbl)
        if type(tbl) ~= "table" then return tbl end
        local copy = {}
        for k, v in pairs(tbl) do
            copy[k] = vim.deepcopy(v)
        end
        return copy
    end
    
    _G.vim.tbl_keys = function(tbl)
        local keys = {}
        for k, _ in pairs(tbl) do
            table.insert(keys, k)
        end
        return keys
    end
    
    _G.vim.tbl_isempty = function(tbl)
        return next(tbl) == nil
    end
    
    _G.vim.list_extend = function(dst, src)
        for _, v in ipairs(src) do
            table.insert(dst, v)
        end
        return dst
    end
    
    _G.vim.tbl_count = function(tbl)
        local count = 0
        for _ in pairs(tbl) do
            count = count + 1
        end
        return count
    end
end

-- Create sample bookmark data for testing
M.create_sample_bookmarks = function()
    return {
        -- Direct URLs
        "https://github.com/neovim/neovim",
        "https://github.com/nvim-telescope/telescope.nvim",
        
        -- URLs with aliases
        ["github_search"] = "https://github.com/search?q=%s",
        ["stack_overflow"] = "https://stackoverflow.com/search?q=%s",
        
        -- Grouped bookmarks
        ["development"] = {
            name = "Development Resources",
            ["github_code"] = "https://github.com/search?q=%s&type=code",
            ["github_repos"] = "https://github.com/search?q=%s&type=repositories",
            ["docs"] = "https://devdocs.io/#q=%s"
        },
        
        ["neovim"] = {
            name = "Neovim Ecosystem",
            ["neovim_main"] = "https://github.com/neovim/neovim",
            ["awesome_neovim"] = "https://github.com/rockerBOO/awesome-neovim"
        }
    }
end

-- Sample browser bookmark data (Chrome format)
M.create_sample_chrome_bookmarks = function()
    return {
        roots = {
            bookmark_bar = {
                children = {
                    {
                        name = "GitHub",
                        url = "https://github.com",
                        type = "url"
                    },
                    {
                        name = "Development",
                        type = "folder",
                        children = {
                            {
                                name = "Neovim",
                                url = "https://neovim.io",
                                type = "url"
                            },
                            {
                                name = "Lua",
                                url = "https://lua.org",
                                type = "url"
                            }
                        }
                    }
                }
            }
        }
    }
end

-- Mock telescope for testing
M.mock_telescope = function()
    local telescope = {
        pickers = {
            new = function(opts, picker_opts)
                return {
                    find = function() end
                }
            end
        },
        finders = {
            new_table = function(opts)
                return opts
            end
        },
        themes = {
            get_dropdown = function()
                return { theme = "dropdown" }
            end
        },
        actions = {
            close = function() end,
            select_default = {
                replace = function() end
            }
        },
        action_state = {
            get_selected_entry = function()
                return { value = "test", ordinal = "test" }
            end,
            get_current_line = function()
                return "test query"
            end
        }
    }
    
    package.loaded["telescope.pickers"] = telescope.pickers
    package.loaded["telescope.finders"] = telescope.finders
    package.loaded["telescope.themes"] = telescope.themes
    package.loaded["telescope.actions"] = telescope.actions
    package.loaded["telescope.actions.state"] = telescope.action_state
    package.loaded["telescope.config"] = { values = { generic_sorter = function() end } }
    
    return telescope
end

return M
