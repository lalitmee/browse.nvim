local helpers = require("helpers")
helpers.setup_mocks()

local browser_bookmarks = require("browse.browser_bookmarks")

describe("browse.browser_bookmarks", function()
    before_each(function()
        helpers.setup_mocks()
    end)

    describe("detect_browsers", function()
        it("should detect available browsers", function()
            -- Mock file existence
            vim.fn.glob = function(pattern)
                if pattern:match("chrome") then
                    return {
                        "/home/user/.config/google-chrome/Default/Bookmarks",
                    }
                end
                return {}
            end

            local available = browser_bookmarks.detect_browsers()
            assert.is_true(available.chrome or false)
        end)

        it("should handle no browsers found", function()
            vim.fn.glob = function()
                return {}
            end

            local available = browser_bookmarks.detect_browsers()
            assert.is_table(available)
        end)
    end)

    describe("get_browser_bookmarks", function()
        it("should parse Chrome bookmark format", function()
            local chrome_data = helpers.create_sample_chrome_bookmarks()

            vim.fn.readfile = function(path)
                return { vim.fn.json_encode(chrome_data) }
            end

            vim.fn.glob = function()
                return { "/path/to/chrome/bookmarks" }
            end

            local bookmarks = browser_bookmarks.get_browser_bookmarks("chrome")
            assert.is_table(bookmarks)
        end)

        it("should handle invalid JSON gracefully", function()
            vim.fn.readfile = function()
                return { "invalid json" }
            end
            vim.fn.glob = function()
                return { "/path/to/bookmarks" }
            end

            local bookmarks = browser_bookmarks.get_browser_bookmarks("chrome")
            assert.equals(0, #bookmarks)
        end)

        it("should handle missing browser", function()
            local bookmarks = browser_bookmarks.get_browser_bookmarks("unknown")
            assert.is_table(bookmarks)
            assert.equals(0, #bookmarks)
        end)

        if vim.fn.has("mac") == 1 then
            it("should parse Safari bookmarks on macOS", function()
                local original_has = vim.fn.has
                local original_executable = vim.fn.executable
                local original_system = vim.fn.system
                local original_json_decode = vim.fn.json_decode

                vim.fn.has = function(feature)
                    return feature == "mac"
                end
                vim.fn.executable = function(cmd)
                    return cmd == "plutil" and 1 or 0
                end
                local mock_plist_data = {
                    {
                        WebBookmarkType = "WebBookmarkTypeList",
                        Title = "Bookmarks Menu",
                        Children = {
                            {
                                WebBookmarkType = "WebBookmarkTypeLeaf",
                                URIDictionary = { title = "GitHub" },
                                URLString = "https://github.com",
                            },
                        },
                    },
                }
                vim.fn.system = function(cmd)
                    return vim.fn.json_encode(mock_plist_data)
                end
                vim.fn.json_decode = function(str)
                    return mock_plist_data
                end

                local bookmarks = browser_bookmarks.get_browser_bookmarks("safari")
                assert.is_table(bookmarks)
                assert.are.equal(1, #bookmarks)
                assert.are.equal("GitHub", bookmarks[1].name)

                vim.fn.has = original_has
                vim.fn.executable = original_executable
                vim.fn.system = original_system
                vim.fn.json_decode = original_json_decode
            end)
        end
    end)

    describe("get_all_browser_bookmarks", function()
        it("should combine bookmarks from multiple browsers", function()
            vim.fn.readfile = function()
                return {
                    vim.fn.json_encode(
                        helpers.create_sample_chrome_bookmarks()
                    ),
                }
            end

            vim.fn.glob = function(pattern)
                if pattern:match("chrome") then
                    return { "/path/to/chrome" }
                elseif pattern:match("firefox") then
                    return { "/path/to/firefox" }
                end
                return {}
            end

            local config = { chrome = true, firefox = true }
            local bookmarks =
                browser_bookmarks.get_all_browser_bookmarks(config)

            assert.is_table(bookmarks)
        end)

        it("should respect browser configuration", function()
            local config = { chrome = false, firefox = true }
            local bookmarks =
                browser_bookmarks.get_all_browser_bookmarks(config)

            -- Should only include firefox bookmarks (if any)
            assert.is_table(bookmarks)
        end)
    end)

    describe("convert_to_browse_format", function()
        it("should convert to grouped format", function()
            local sample_bookmarks = {
                {
                    name = "GitHub",
                    url = "https://github.com",
                    folder = "Development",
                    source = "chrome",
                },
            }

            local converted = browser_bookmarks.convert_to_browse_format(
                sample_bookmarks,
                true
            )
            assert.is_table(converted)
            assert.is_not_nil(converted["Development"])
        end)

        it("should convert to flat format", function()
            local sample_bookmarks = {
                {
                    name = "GitHub",
                    url = "https://github.com",
                    folder = "Development",
                    source = "chrome",
                },
            }

            local converted = browser_bookmarks.convert_to_browse_format(
                sample_bookmarks,
                false
            )
            assert.is_table(converted)
            assert.is_string(converted["Development / GitHub"])
        end)
    end)

    describe("deduplicate_bookmarks", function()
        it("should remove duplicate URLs", function()
            local bookmarks = {
                {
                    name = "GitHub 1",
                    url = "https://github.com",
                },
                {
                    name = "GitHub 2",
                    url = "https://github.com",
                },
                {
                    name = "Google",
                    url = "https://google.com",
                },
            }

            local unique = browser_bookmarks.deduplicate_bookmarks(bookmarks)
            assert.equals(2, #unique)
        end)

        it("should handle empty bookmark list", function()
            local unique = browser_bookmarks.deduplicate_bookmarks({})
            assert.equals(0, #unique)
        end)
    end)
end)
