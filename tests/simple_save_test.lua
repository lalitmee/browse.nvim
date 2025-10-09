describe("file_bookmarks save test", function()
    it("should save without error", function()
        -- Setup mocks
        _G.vim = _G.vim or {}
        _G.vim.fn = _G.vim.fn or {}
        _G.vim.tbl_keys = function(tbl)
            local keys = {}
            for k, _ in pairs(tbl) do
                table.insert(keys, k)
            end
            return keys
        end
        
        -- Mock file operations
        _G.vim.fn.json_encode = function(data)
            return '{"development":{"name":"Development","github":"https://github.com"}}'
        end
        
        _G.vim.fn.writefile = function(lines, path)
            -- Just succeed without error
            print("Writing to:", path)
            print("Content lines:", #lines)
            return 0 -- writefile returns 0 on success
        end
        
        local file_bookmarks = require("browse.file_bookmarks")
        
        local bookmarks = {
            development = {
                name = "Development",
                github = "https://github.com"
            }
        }
        
        local success, error = file_bookmarks.save_to_file(bookmarks, "test.json")
        print("Success:", success, "Error:", error)
        
        assert.is_true(success)
        assert.is_nil(error)
    end)
end)
