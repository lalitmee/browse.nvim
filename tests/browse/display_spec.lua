local helpers = require("helpers")
helpers.setup_mocks()

describe("Display Formatting", function()
    before_each(function()
        helpers.mock_picker()
        package.loaded["browse.bookmarks"] = nil
        package.loaded["browse.config"] = nil
    end)

    it("should display the count for grouped bookmarks", function()
        local bookmarks_module = require("browse.bookmarks")

        bookmarks_module.search_bookmarks({
            bookmarks = {
                my_group = {
                    name = "My Test Group",
                    item1 = "https://a.com",
                    item2 = "https://b.com",
                },
            },
        })

        local calls = helpers.get_picker_calls()
        assert.equal(1, #calls)
        local group_entry
        for _, entry in ipairs(calls[1].entries) do
            if type(entry.value) == "table" then
                group_entry = entry
            end
        end
        assert.is_not_nil(group_entry, "Failed to find group entry")
        assert.is_string(group_entry.display)
        assert(string.match(group_entry.display, "%(2%)"), "Display string should contain the count '(2)'")
    end)
end)