local helpers = require("helpers")
helpers.setup_mocks()

describe("Picker Query Flow", function()
    before_each(function()
        helpers.mock_picker()
        package.loaded["browse.bookmarks"] = nil
        package.loaded["browse.bookmark_manager"] = nil
        package.loaded["browse.config"] = nil
    end)

    local function find_group_value(entries)
        for _, entry in ipairs(entries) do
            if type(entry.value) == "table" then
                return entry.value
            end
        end
    end

    local function setup_test(persist_query)
        local browse_bookmarks = require("browse.bookmarks")
        local config = require("browse.config")
        config.opts.persist_grouped_bookmarks_query = persist_query

        local bookmarks = {
            group1 = {
                name = "Group 1",
                bookmark1 = "https://bookmark1.com",
                nested_group = {
                    name = "Nested Group",
                    bookmark2 = "https://bookmark2.com",
                },
            },
            bookmark3 = "https://bookmark3.com",
        }

        return browse_bookmarks, bookmarks
    end

    it("should persist query when persist_grouped_bookmarks_query is true", function()
        local browse_bookmarks, bookmarks = setup_test(true)

        -- 1. Open bookmarks
        browse_bookmarks.search_bookmarks({ bookmarks = bookmarks })

        -- 2. Select group1 with a query
        local group = find_group_value(helpers.get_picker_calls()[1].entries)
        helpers.simulate_select(group, "group", 1)
        assert.are.equal("group", helpers.get_picker_calls()[2].opts.default_text)

        -- 3. Select nested_group with a query
        local nested = find_group_value(helpers.get_picker_calls()[2].entries)
        helpers.simulate_select(nested, "group", 2)
        assert.are.equal("group", helpers.get_picker_calls()[3].opts.default_text)

        -- 4. Go back
        helpers.simulate_select("back", "group", 3)
        assert.are.equal("group", helpers.get_picker_calls()[4].opts.default_text)

        -- 5. Go back again
        helpers.simulate_select("back", "group", 4)
        assert.are.equal("group", helpers.get_picker_calls()[5].opts.default_text)
    end)

    it("should clear query when persist_grouped_bookmarks_query is false", function()
        local browse_bookmarks, bookmarks = setup_test(false)

        -- 1. Open bookmarks
        browse_bookmarks.search_bookmarks({ bookmarks = bookmarks })

        -- 2. Select group1
        local group = find_group_value(helpers.get_picker_calls()[1].entries)
        helpers.simulate_select(group, "group", 1)
        assert.are.equal("", helpers.get_picker_calls()[2].opts.default_text)

        -- 3. Select nested_group
        local nested = find_group_value(helpers.get_picker_calls()[2].entries)
        helpers.simulate_select(nested, "group", 2)
        assert.are.equal("", helpers.get_picker_calls()[3].opts.default_text)

        -- 4. Go back
        helpers.simulate_select("back", "group", 3)
        assert.are.equal("", helpers.get_picker_calls()[4].opts.default_text)

        -- 5. Go back again
        helpers.simulate_select("back", "group", 4)
        assert.are.equal("", helpers.get_picker_calls()[5].opts.default_text)
    end)
end)