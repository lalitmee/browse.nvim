local helpers = require("helpers")
helpers.setup_mocks()

local utils = require("browse.utils")

describe("browse.utils", function()
    describe("get_visual_text", function()
        it("should extract visual text", function()
            -- Mock register operations
            local original_getreg = vim.fn.getreg
            local original_setreg = vim.fn.setreg

            vim.fn.getreg = function(reg)
                if reg == "v" then
                    return "selected text"
                end
                return ""
            end

            vim.fn.setreg = function() end

            local result = utils.get_visual_text()
            assert.equals("selected text", result)

            -- Restore original functions
            vim.fn.getreg = original_getreg
            vim.fn.setreg = original_setreg
        end)

        it("should handle newlines in visual text", function()
            local original_getreg = vim.fn.getreg
            local original_setreg = vim.fn.setreg

            vim.fn.getreg = function(reg)
                if reg == "v" then
                    return "line1\nline2\nline3"
                end
                return ""
            end

            vim.fn.setreg = function() end

            local result = utils.get_visual_text()
            assert.equals("line1line2line3", result)

            vim.fn.getreg = original_getreg
            vim.fn.setreg = original_setreg
        end)
    end)

    describe("get_domain", function()
        it("should extract domain from https URL", function()
            local url = "https://github.com/user/repo"
            local domain = utils.get_domain(url)
            assert.equals("github.com", domain)
        end)

        it("should extract domain from http URL", function()
            local url = "http://example.org/path"
            local domain = utils.get_domain(url)
            assert.equals("example.org", domain)
        end)

        it("should handle URLs with ports", function()
            local url = "https://localhost:3000/app"
            local domain = utils.get_domain(url)
            assert.equals("localhost:3000", domain)
        end)

        it("should return nil for invalid URLs", function()
            local domain = utils.get_domain("not-a-url")
            assert.is_nil(domain)
        end)
    end)

    describe("default_search", function()
        it("should open browser with URL", function()
            local job_called = false
            local job_cmd = nil

            vim.fn.jobstart = function(cmd)
                job_called = true
                job_cmd = cmd
                return 1
            end

            utils.default_search("https://example.com")

            assert.is_true(job_called)
            assert.is_not_nil(job_cmd)
        end)
    end)

    describe("search", function()
        it("should handle user input and open URL", function()
            local input_called = false
            local input_callback = nil

            vim.ui.input = function(opts, callback)
                input_called = true
                input_callback = callback
                callback("test query")
            end

            local job_called = false
            vim.fn.jobstart = function()
                job_called = true
                return 1
            end

            local target_function = function(input)
                return "https://example.com/search?q=" .. input
            end

            utils.search(target_function, {})

            assert.is_true(input_called)
            assert.is_true(job_called)
        end)

        it("should handle empty input gracefully", function()
            vim.ui.input = function(opts, callback)
                callback("")
            end

            local job_called = false
            vim.fn.jobstart = function()
                job_called = true
                return 1
            end

            utils.search(function()
                return ""
            end, {})

            assert.is_false(job_called)
        end)
    end)

    describe("format_search", function()
        it("should create a search function with format string", function()
            local search_fn = utils.format_search(
                "https://example.com/q=%s",
                { prompt = "Test:" }
            )
            assert.is_function(search_fn)
        end)

        it("should use visual text when provided", function()
            local input_called = false
            vim.ui.input = function(opts, callback)
                input_called = true
                assert.equals("visual text", opts.default)
                callback("test query")
            end

            vim.fn.jobstart = function()
                return 1
            end

            local search_fn = utils.format_search(
                "https://example.com/q=%s",
                { prompt = "Test:" }
            )
            search_fn("visual text")

            assert.is_true(input_called)
        end)
    end)

    describe("callback_search", function()
        it("should create a callback function", function()
            local custom_fn = function(input)
                return "https://example.com/" .. input
            end
            local callback =
                utils.callback_search(custom_fn, { prompt = "Test:" })
            assert.is_function(callback)
        end)
    end)
end)
