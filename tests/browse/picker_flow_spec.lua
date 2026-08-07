local helpers = require("helpers")
helpers.setup_mocks()

describe("Picker Flow", function()
    before_each(function()
        helpers.mock_picker()
        package.loaded["browse.bookmarks"] = nil
        package.loaded["browse.bookmark_manager"] = nil
        package.loaded["browse.config"] = nil
    end)

    it("should preserve source when navigating into a group", function()
        local browse_bookmarks = require("browse.bookmarks")

        browse_bookmarks.search_bookmarks({
            source = "manual",
            bookmarks = {
                group1 = {
                    name = "Group 1",
                    bookmark1 = "https://bookmark1.com",
                },
            },
        })

        local calls = helpers.get_picker_calls()
        assert.equal(1, #calls)
        assert.match("Manual Bookmarks", calls[1].opts.title)

        local group_entry
        for _, entry in ipairs(calls[1].entries) do
            if type(entry.value) == "table" then
                group_entry = entry.value
            end
        end
        assert.is_not_nil(group_entry)

        helpers.simulate_select(group_entry, "", 1)
        calls = helpers.get_picker_calls()
        assert.equal(2, #calls)
        assert.match("Manual Bookmarks", calls[2].opts.title)
    end)
end)