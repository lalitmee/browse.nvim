describe("pcall test", function()
    it("should work with writefile mock", function()
        -- Setup mock
        _G.vim = _G.vim or {}
        _G.vim.fn = _G.vim.fn or {}
        
        _G.vim.fn.writefile = function(lines, path)
            print("Mock writefile called with:", #lines, "lines to", path)
            return 0
        end
        
        -- Test direct call
        local result = vim.fn.writefile({"test"}, "test.txt")
        print("Direct call result:", result)
        assert.equals(0, result)
        
        -- Test pcall
        local ok, res = pcall(vim.fn.writefile, {"test"}, "test.txt")
        print("pcall result:", ok, res)
        assert.is_true(ok)
        assert.equals(0, res)
        
        -- Test the actual logic from save_to_file
        local success = ok and (res == 0 or res == nil)  -- writefile can return 0 or nil on success
        local error_msg = success and nil or "Failed to write file"
        print("Final logic:", success, error_msg)
        
        assert.is_true(success)
        assert.is_nil(error_msg)
    end)
end)
