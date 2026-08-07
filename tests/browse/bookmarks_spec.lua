local helpers = require("helpers")
helpers.setup_mocks()
helpers.mock_picker()

local bookmarks_module = require("browse.bookmarks")

describe("browse.bookmarks", function()
    local nested_bookmarks = {
        Neovim = {
            name = "Neovim",
            ["neovim-dap"] = "https://github.com/mfussenegger/nvim-dap",
            telescope = "https://github.com/nvim-telescope/telescope.nvim",
        },
        Rust = {
            name = "Rust",
            ["rust-book"] = "https://doc.rust-lang.org/book/",
            ["rust-by-example"] = "https://doc.rust-lang.org/rust-by-example/",
        },
    }

    it("should return nested bookmarks when show_nested is true", function()
        local entries = bookmarks_module.get_bookmark_entries(nested_bookmarks, true, 0)
        assert.are.same(2, #entries)
    end)

    it("should return flattened bookmarks when show_nested is false", function()
        local entries = bookmarks_module.get_bookmark_entries(nested_bookmarks, false, 0)
        assert.are.same(4, #entries)
    end)
end)