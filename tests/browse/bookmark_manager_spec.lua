local helpers = require("helpers")
helpers.setup_mocks()

local bookmark_manager = require("browse.bookmark_manager")

describe("browse.bookmark_manager", function()
    before_each(function()
        helpers.setup_mocks()
        -- Clear cache before each test
        bookmark_manager.clear_cache()
    end)

    describe("merge_bookmarks", function()
        it("should merge simple bookmark tables", function()
            local bookmarks1 = {
                github = "https://github.com",
                google = "https://google.com",
            }

            local bookmarks2 = {
                stackoverflow = "https://stackoverflow.com",
                reddit = "https://reddit.com",
            }

            local merged =
                bookmark_manager.merge_bookmarks(bookmarks1, bookmarks2)

            assert.is_table(merged)
            assert.equals("https://github.com", merged.github)
            assert.equals("https://stackoverflow.com", merged.stackoverflow)
        end)

        it("should merge grouped bookmarks", function()
            local bookmarks1 = {
                development = {
                    name = "Development",
                    github = "https://github.com",
                },
            }

            local bookmarks2 = {
                development = {
                    name = "Development",
                    stackoverflow = "https://stackoverflow.com",
                },
            }

            local merged =
                bookmark_manager.merge_bookmarks(bookmarks1, bookmarks2)

            assert.is_table(merged.development)
            assert.equals("https://github.com", merged.development.github)
            assert.equals(
                "https://stackoverflow.com",
                merged.development.stackoverflow
            )
        end)

        it("should handle array-style entries", function()
            local bookmarks1 = {
                "https://github.com",
                "https://google.com",
            }

            local bookmarks2 = {
                "https://stackoverflow.com",
            }

            local merged =
                bookmark_manager.merge_bookmarks(bookmarks1, bookmarks2)

            assert.is_table(merged)
            assert.is_true(#merged >= 3)
        end)
    end)

    describe("deduplicate_bookmarks", function()
        it("should remove duplicate URLs", function()
            local bookmarks = {
                github1 = "https://github.com",
                github2 = "https://github.com",
                google = "https://google.com",
            }

            local unique = bookmark_manager.deduplicate_bookmarks(bookmarks)

            -- Should only have 2 unique URLs
            local count = 0
            for _ in pairs(unique) do
                count = count + 1
            end
            assert.equals(2, count)
        end)

        it("should handle grouped bookmarks", function()
            local bookmarks = {
                development = {
                    name = "Development",
                    github1 = "https://github.com",
                    github2 = "https://github.com",
                    google = "https://google.com",
                },
            }

            local unique = bookmark_manager.deduplicate_bookmarks(bookmarks)

            assert.is_table(unique.development)
            -- Should have name + 2 unique URLs
            local count = 0
            for _ in pairs(unique.development) do
                count = count + 1
            end
            assert.equals(3, count) -- name, github, google
        end)
    end)

    describe("validate_bookmarks", function()
        it("should validate correct bookmark structure", function()
            local bookmarks = {
                github = "https://github.com",
                google = "https://google.com",
                search = "https://example.com/search?q=%s",
            }

            local valid, errors = bookmark_manager.validate_bookmarks(bookmarks)
            assert.is_true(valid)
            assert.equals(0, #errors)
        end)

        it("should reject invalid URLs", function()
            local bookmarks = {
                invalid = "not-a-url",
            }

            local valid, errors = bookmark_manager.validate_bookmarks(bookmarks)
            assert.is_false(valid)
            assert.is_true(#errors > 0)
        end)

        it("should validate grouped bookmarks", function()
            local bookmarks = {
                development = {
                    name = "Development",
                    github = "https://github.com",
                    invalid = "not-a-url",
                },
            }

            local valid, errors = bookmark_manager.validate_bookmarks(bookmarks)
            assert.is_false(valid)
            assert.is_true(#errors > 0)
        end)

        it("should reject non-table input", function()
            local valid, errors =
                bookmark_manager.validate_bookmarks("not a table")
            assert.is_false(valid)
            assert.is_true(#errors > 0)
        end)
    end)

    describe("normalize_bookmarks", function()
        it("should convert array entries to named entries", function()
            local bookmarks = {
                "https://github.com",
                "https://google.com",
                named = "https://stackoverflow.com",
            }

            local normalized = bookmark_manager.normalize_bookmarks(bookmarks)

            assert.is_nil(normalized[1])
            assert.is_nil(normalized[2])
            assert.is_string(normalized.named)

            -- Should have domain-based names for array entries
            local has_github = false
            local has_google = false
            for key, value in pairs(normalized) do
                if value == "https://github.com" then
                    has_github = true
                end
                if value == "https://google.com" then
                    has_google = true
                end
            end
            assert.is_true(has_github)
            assert.is_true(has_google)
        end)

        it("should preserve named entries", function()
            local bookmarks = {
                github = "https://github.com",
                development = {
                    name = "Development",
                    stackoverflow = "https://stackoverflow.com",
                },
            }

            local normalized = bookmark_manager.normalize_bookmarks(bookmarks)

            assert.equals("https://github.com", normalized.github)
            assert.is_table(normalized.development)
        end)
    end)

    describe("search_bookmarks", function()
        it("should find bookmarks by name", function()
            local bookmarks = {
                github = "https://github.com",
                google_search = "https://google.com/search?q=%s",
                development = {
                    name = "Development",
                    stackoverflow = "https://stackoverflow.com",
                },
            }

            local results =
                bookmark_manager.search_bookmarks("github", bookmarks)

            assert.is_table(results)
            assert.is_true(#results > 0)

            local found = false
            for _, result in ipairs(results) do
                if result.url == "https://github.com" then
                    found = true
                    break
                end
            end
            assert.is_true(found)
        end)

        it("should find bookmarks by URL", function()
            local bookmarks = {
                github = "https://github.com",
            }

            local results =
                bookmark_manager.search_bookmarks("github.com", bookmarks)
            assert.is_true(#results > 0)
        end)

        it("should handle case insensitive search", function()
            local bookmarks = {
                GitHub = "https://github.com",
            }

            local results =
                bookmark_manager.search_bookmarks("github", bookmarks)
            assert.is_true(#results > 0)
        end)
    end)

    describe("get_stats", function()
        it("should calculate bookmark statistics", function()
            local test_bookmarks = helpers.create_sample_bookmarks()

            -- Mock get_bookmarks to return test data
            bookmark_manager.get_bookmarks = function()
                return test_bookmarks
            end

            local stats = bookmark_manager.get_stats()

            assert.is_table(stats)
            assert.is_number(stats.total_bookmarks)
            assert.is_number(stats.direct_bookmarks)
            assert.is_number(stats.grouped_bookmarks)
            assert.is_number(stats.groups)
            assert.is_table(stats.unique_domains)
            assert.is_true(stats.total_bookmarks > 0)
        end)

        it("should handle empty bookmarks", function()
            bookmark_manager.get_bookmarks = function()
                return {}
            end

            local stats = bookmark_manager.get_stats()

            assert.equals(0, stats.total_bookmarks)
            assert.equals(0, stats.direct_bookmarks)
            assert.equals(0, stats.grouped_bookmarks)
            assert.equals(0, stats.groups)
        end)
    end)

    describe("add_bookmark", function()
        it("should add bookmark to file", function()
            local write_called = false
            local written_data = nil

            vim.fn.writefile = function(lines, path)
                write_called = true
                written_data = table.concat(lines, "")
                return 0 -- writefile returns 0 on success
            end

            vim.fn.readfile = function()
                return { "{}" } -- empty JSON
            end

            vim.fn.stdpath = function()
                return "/config"
            end

            local success =
                bookmark_manager.add_bookmark("test", "https://test.com")

            assert.is_true(success)
            assert.is_true(write_called)
            assert.is_string(written_data)
        end)

        it("should handle write failures", function()
            vim.fn.writefile = function()
                error("write failed")
            end
            vim.fn.readfile = function()
                return { "{}" }
            end
            vim.fn.stdpath = function()
                return "/config"
            end

            local success =
                bookmark_manager.add_bookmark("test", "https://test.com")
            assert.is_false(success)
        end)
    end)

    describe("cache management", function()
        it("should have cache functions", function()
            -- Test that cache functions exist and can be called
            assert.is_function(bookmark_manager.get_bookmarks)
            assert.is_function(bookmark_manager.clear_cache)

            -- Clear cache should not error
            bookmark_manager.clear_cache()

            -- Get bookmarks should return a table
            local bookmarks = bookmark_manager.get_bookmarks()
            assert.is_table(bookmarks)

            -- Force refresh should not error
            local bookmarks2 = bookmark_manager.get_bookmarks(true)
            assert.is_table(bookmarks2)
        end)

        it("should clear cache function work", function()
            -- Just test that clear_cache doesn't error
            bookmark_manager.clear_cache()
            assert.is_true(true) -- If we get here, clear_cache worked
        end)

        it("should get bookmarks work with force refresh", function()
            -- Test that force refresh parameter works
            local bookmarks1 = bookmark_manager.get_bookmarks(false)
            local bookmarks2 = bookmark_manager.get_bookmarks(true)

            assert.is_table(bookmarks1)
            assert.is_table(bookmarks2)
        end)
    end)
end)
