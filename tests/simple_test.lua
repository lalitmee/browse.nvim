describe("simple test", function()
    it("should work", function()
        assert.equals(1, 1)
    end)
    
    it("should be able to require utils", function()
        -- First setup basic mocks that utils needs
        _G.vim = _G.vim or {}
        _G.vim.fn = _G.vim.fn or {}
        _G.vim.loop = _G.vim.loop or {}
        _G.vim.ui = _G.vim.ui or {}
        _G.vim.bo = _G.vim.bo or {}
        _G.vim.notify = _G.vim.notify or function() end
        
        _G.vim.fn.trim = function(str)
            return str:match("^%s*(.-)%s*$")
        end
        
        _G.vim.fn.jobstart = function()
            return 1
        end
        
        _G.vim.fn.extend = function(base, extra)
            for _, v in ipairs(extra) do
                table.insert(base, v)
            end
            return base
        end
        
        _G.vim.loop.os_uname = function()
            return { sysname = "Linux" }
        end
        
        _G.vim.fn.systemlist = function(cmd)
            if cmd:match("uname") then
                return { "Linux" }
            end
            return {}
        end
        
        _G.vim.ui.input = function(opts, callback)
            callback("test")
        end
        
        _G.vim.bo.filetype = "lua"
        
        local utils = require("browse.utils")
        assert.is_not_nil(utils)
        assert.is_function(utils.get_visual_text)
    end)
end)
