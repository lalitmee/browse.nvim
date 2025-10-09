describe("debug test 2", function()
    it("should understand ternary logic", function()
        local function test_ternary(condition)
            -- Correct way to do this in Lua
            if condition then
                return nil
            else
                return "Failed to write file"
            end
        end
        
        local r1 = test_ternary(true)   -- Should be nil
        local r2 = test_ternary(false)  -- Should be "Failed to write file"
        
        print("r1 type:", type(r1), "r1 value:", r1)
        print("r2 type:", type(r2), "r2 value:", r2)
        
        assert.is_nil(r1)
        assert.equals("Failed to write file", r2)
        
        -- Test the full logic step by step
        local ok_val = true
        local res_val = 0
        local success = ok_val and (res_val == 0 or res_val == nil)
        print("success:", success, type(success))
        
        local error_msg
        if success then
            error_msg = nil
        else
            error_msg = "Failed to write file"
        end
        print("error_msg:", error_msg, type(error_msg))
        
        assert.is_true(success)
        assert.is_nil(error_msg)
    end)
end)
