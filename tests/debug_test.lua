describe("debug test", function()
    it("should understand the logic", function()
        -- Test different combinations
        local function test_logic(ok_val, res_val)
            local success = ok_val and (res_val == 0 or res_val == nil)
            local error_msg = success and nil or "Failed to write file"
            print(string.format("ok=%s, res=%s => success=%s, error=%s", 
                tostring(ok_val), tostring(res_val), tostring(success), tostring(error_msg)))
            return success, error_msg
        end
        
        test_logic(true, 0)    -- Expected: success=true, error=nil
        test_logic(true, nil)  -- Expected: success=true, error=nil  
        test_logic(true, 1)    -- Expected: success=false, error="Failed to write file"
        test_logic(false, 0)   -- Expected: success=false, error="Failed to write file"
        
        -- Test our specific case
        local success, error_msg = test_logic(true, 0)
        assert.is_true(success)
        assert.is_nil(error_msg)
    end)
end)
