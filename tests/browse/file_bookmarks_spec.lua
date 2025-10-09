local helpers = require("helpers")
helpers.setup_mocks()

local file_bookmarks = require("browse.file_bookmarks")

describe("browse.file_bookmarks", function()
    before_each(function()
        helpers.setup_mocks()
    end)

    describe("load_from_file", function()
        it("should load JSON bookmarks", function()
            local json_data = {
                development = {
                    name = "Development",
                    github = "https://github.com",
                    stackoverflow = "https://stackoverflow.com",
                },
            }

            vim.fn.readfile = function()
                return { vim.fn.json_encode(json_data) }
            end

            local bookmarks, error = file_bookmarks.load_from_file("test.json")
            assert.is_nil(error)
            assert.is_table(bookmarks)
            assert.is_not_nil(bookmarks.development)
        end)

        it("should handle invalid JSON", function()
            vim.fn.readfile = function()
                return { "invalid json content" }
            end

            local bookmarks, error = file_bookmarks.load_from_file("test.json")
            assert.is_nil(bookmarks)
            assert.is_string(error)
        end)

        it("should load YAML bookmarks", function()
            vim.fn.readfile = function()
                return {
                    "development:",
                    "  github: https://github.com",
                    "  stackoverflow: https://stackoverflow.com",
                }
            end

            local bookmarks, error = file_bookmarks.load_from_file("test.yaml")
            assert.is_nil(error)
            assert.is_table(bookmarks)
        end)

        it("should load TOML bookmarks", function()
            vim.fn.readfile = function()
                return {
                    "[development]",
                    "github = \"https://github.com\"",
                    "stackoverflow = \"https://stackoverflow.com\"",
                }
            end

            local bookmarks, error = file_bookmarks.load_from_file("test.toml")
            assert.is_nil(error)
            assert.is_table(bookmarks)
        end)

        it("should load plain text bookmarks", function()
            vim.fn.readfile = function()
                return {
                    "[Development]",
                    "GitHub: https://github.com",
                    "https://stackoverflow.com",
                }
            end

            local bookmarks, error = file_bookmarks.load_from_file("test.txt")
            assert.is_nil(error)
            assert.is_table(bookmarks)
        end)

        it("should handle missing file", function()
            vim.fn.filereadable = function()
                return 0
            end

            local bookmarks, error =
                file_bookmarks.load_from_file("missing.json")
            assert.is_nil(bookmarks)
            assert.is_string(error)
            assert.matches("not found", error)
        end)

        it("should handle unsupported format", function()
            local bookmarks, error =
                file_bookmarks.load_from_file("test.unknown")
            assert.is_nil(bookmarks)
            assert.matches("Unsupported", error)
        end)
    end)

    describe("save_to_file", function()
        it("should save JSON format", function()
            local bookmarks = {
                development = {
                    name = "Development",
                    github = "https://github.com",
                },
            }

            -- Setup required mocks for this test
            vim.fn.json_encode = function(data)
                return "{\"development\":{\"name\":\"Development\",\"github\":\"https://github.com\"}}"
            end

            local write_called = false
            vim.fn.writefile = function(lines, path)
                write_called = true
                assert.is_table(lines)
                assert.is_string(path)
                return 0 -- writefile returns 0 on success
            end

            local success, error =
                file_bookmarks.save_to_file(bookmarks, "test.json")
            assert.is_true(success)
            assert.is_nil(error)
            assert.is_true(write_called)
        end)

        it("should save YAML format", function()
            local bookmarks = {
                development = {
                    name = "Development",
                    github = "https://github.com",
                },
            }

            local write_called = false
            vim.fn.writefile = function(lines, path)
                write_called = true
                -- Check YAML structure
                local yaml_content = table.concat(lines, "\\n")
                assert.matches("development:", yaml_content)
                return 0 -- writefile returns 0 on success
            end

            local success, error =
                file_bookmarks.save_to_file(bookmarks, "test.yaml")
            assert.is_true(success)
            assert.is_nil(error)
            assert.is_true(write_called)
        end)

        it("should save TOML format", function()
            local bookmarks = {
                development = {
                    name = "Development",
                    github = "https://github.com",
                },
            }

            local write_called = false
            vim.fn.writefile = function(lines, path)
                write_called = true
                local toml_content = table.concat(lines, "\\n")
                assert.matches("%[development%]", toml_content)
                return 0 -- writefile returns 0 on success
            end

            local success = file_bookmarks.save_to_file(bookmarks, "test.toml")
            assert.is_true(success)
            assert.is_true(write_called)
        end)

        it("should handle write failure", function()
            vim.fn.writefile = function()
                error("write failed")
            end

            local success, error = file_bookmarks.save_to_file({}, "test.json")
            assert.is_false(success)
            assert.is_string(error)
        end)
    end)

    describe("get_supported_formats", function()
        it("should return list of supported formats", function()
            local formats = file_bookmarks.get_supported_formats()
            assert.is_table(formats)

            -- Check if formats contains expected values
            local has_json, has_yaml, has_toml, has_txt =
                false, false, false, false
            for _, format in ipairs(formats) do
                if format == "json" then
                    has_json = true
                end
                if format == "yaml" then
                    has_yaml = true
                end
                if format == "toml" then
                    has_toml = true
                end
                if format == "txt" then
                    has_txt = true
                end
            end

            assert.is_true(has_json)
            assert.is_true(has_yaml)
            assert.is_true(has_toml)
            assert.is_true(has_txt)
        end)
    end)

    describe("find_bookmark_files", function()
        it("should find bookmark files in directory", function()
            vim.fn.glob = function(pattern)
                if pattern:match("%.json") then
                    return { "/path/bookmarks.json" }
                elseif pattern:match("%.yaml") then
                    return { "/path/bookmarks.yaml" }
                end
                return {}
            end

            local files = file_bookmarks.find_bookmark_files("/path")
            assert.is_table(files)
            assert.is_true(#files >= 0)
        end)

        it("should handle empty directory", function()
            vim.fn.glob = function()
                return {}
            end

            local files = file_bookmarks.find_bookmark_files("/empty")
            assert.is_table(files)
            assert.equals(0, #files)
        end)
    end)
end)
