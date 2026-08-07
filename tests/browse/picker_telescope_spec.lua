local helpers = require("helpers")
helpers.setup_mocks()

describe("browse.picker.telescope", function()
    local adapter
    local current_pick

    local function stub_telescope()
        package.loaded["telescope.pickers"] = {
            new = function(opts, picker_opts)
                current_pick = { opts = opts, picker_opts = picker_opts }
                return { find = function() end }
            end,
        }
        package.loaded["telescope.finders"] = {
            new_table = function(opts)
                return opts
            end,
        }
        package.loaded["telescope.config"] = {
            values = {
                generic_sorter = function()
                    return { tiebreak = function() return true end }
                end,
            },
        }
        package.loaded["telescope.themes"] = {
            get_dropdown = function(opts)
                return { theme = "dropdown", theme_opts = opts }
            end,
            get_cursor = function(opts)
                return { theme = "cursor", theme_opts = opts }
            end,
            get_ivy = function(opts)
                return { theme = "ivy", theme_opts = opts }
            end,
        }
        package.loaded["telescope.actions"] = {
            close = function() end,
            select_default = {
                replace = function(_, fn)
                    fn()
                end,
            },
        }
        package.loaded["telescope.actions.state"] = {
            get_selected_entry = function()
                return current_pick.selected
            end,
            get_current_line = function()
                return current_pick.line
            end,
        }
    end

    before_each(function()
        current_pick = { opts = nil, picker_opts = nil }
        stub_telescope()
        package.loaded["browse.picker.telescope"] = nil
        adapter = require("browse.picker.telescope")
    end)

    it("should be available when telescope modules load", function()
        assert.is_true(adapter.available())
    end)

    it("should not be available when telescope is missing", function()
        package.loaded["telescope.pickers"] = nil
        package.loaded["browse.picker.telescope"] = nil
        adapter = require("browse.picker.telescope")
        assert.is_false(adapter.available())
    end)

    it("should pass through entries and title to the picker", function()
        local entries = {
            { value = "mdn", display = "MDN Web Docs", ordinal = "mdn" },
        }
        adapter.pick(entries, { title = "Browse", on_select = function() end })
        assert.are.same(entries, current_pick.picker_opts.finder.results)
    end)

    it("should apply the default_text prefill", function()
        adapter.pick({ { value = "x", display = "x", ordinal = "x" } }, {
            title = "Bookmarks",
            default_text = "query",
            on_select = function() end,
        })
        assert.are.equal("query", current_pick.opts.default_text)
    end)

    it("should call on_select with value and current line", function()
        local selected_value
        local selected_query
        adapter.pick({ { value = "url", display = "A", ordinal = "ord" } }, {
            title = "Bookmarks",
            on_select = function(value, query)
                selected_value = value
                selected_query = query
            end,
        })
        -- simulate the entry_maker and selection
        local finder = current_pick.picker_opts.finder
        local picked = finder.entry_maker
            and finder.entry_maker({ value = "url", display = "A", ordinal = "ord" })
        assert.are.equal("url", picked.value)
        current_pick.selected = { value = "url", ordinal = "ord" }
        current_pick.line = "current query"
        -- run the attach_mappings to trigger on_select
        local attach = current_pick.picker_opts.attach_mappings
        attach(1, {})
        assert.are.equal("url", selected_value)
        assert.are.equal("current query", selected_query)
    end)

    it("should wire on_cancel when provided (no selection)", function()
        local cancelled = false
        adapter.pick({ { value = "x", display = "x", ordinal = "x" } }, {
            on_select = function() end,
            on_cancel = function()
                cancelled = true
            end,
        })
        current_pick.selected = nil
        current_pick.line = ""
        current_pick.picker_opts.attach_mappings(1, {})
        assert.is_true(cancelled)
    end)

    it("should map layout dropdown to theme dropdown", function()
        adapter.pick({ { value = "x", display = "x", ordinal = "x" } }, {
            title = "T",
            layout = "dropdown",
            on_select = function() end,
        })
        assert.are.equal("dropdown", current_pick.opts.theme)
    end)
end)
