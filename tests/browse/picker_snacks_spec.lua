local helpers = require("helpers")
helpers.setup_mocks()

describe("browse.picker.snacks", function()
    local pick_opts
    local adapter

    local function stub_snacks()
        package.loaded["snacks"] = {
            picker = {
                pick = function(opts)
                    pick_opts = opts
                end,
            },
        }
    end

    before_each(function()
        pick_opts = nil
        stub_snacks()
        package.loaded["browse.picker.snacks"] = nil
        adapter = require("browse.picker.snacks")
    end)

    it("should be available when snacks loads", function()
        assert.is_true(adapter.available())
        package.loaded["snacks"] = nil
        package.loaded["browse.picker.snacks"] = nil
        adapter = require("browse.picker.snacks")
        assert.is_false(adapter.available())
    end)

    it("should build items, set format text and prefill pattern", function()
        adapter.pick({
            { value = "mdn", display = "MDN Web Docs", ordinal = "mdn" },
        }, {
            title = "Browse",
            on_select = function() end,
            default_text = "search",
        })
        assert.is_not_nil(pick_opts)
        assert.equal("MDN Web Docs", pick_opts.items[1].text)
        assert.equal("mdn", pick_opts.items[1].value)
        assert.equal("text", pick_opts.format)
        assert.equal("search", pick_opts.pattern)
        assert.equal("Browse", pick_opts.title)
    end)

    it("should map layouts to snacks presets", function()
        adapter.pick({ { value = "x", display = "X", ordinal = "x" } }, {
            on_select = function() end,
            layout = "ivy",
        })
        assert.equal("ivy", pick_opts.layout)
    end)

    it("should close the picker and call on_select on confirm", function()
        local selected_value
        local selected_query
        adapter.pick({
            { value = "url", display = "A", ordinal = "ord" },
        }, {
            on_select = function(v, q)
                selected_value = v
                selected_query = q
            end,
        })
        local closed = false
        local fake_picker = {
            close = function()
                closed = true
            end,
            input = { get = function() return "cur" end },
        }
        pick_opts.confirm(fake_picker, { value = "url", text = "A" })
        assert.is_true(closed)
        assert.equal("url", selected_value)
        assert.equal("cur", selected_query)
    end)

    it("should fire on_cancel via on_close when not confirmed", function()
        local cancelled = false
        adapter.pick({
            { value = "x", display = "X", ordinal = "x" },
        }, {
            on_select = function() end,
            on_cancel = function()
                cancelled = true
            end,
        })
        pick_opts.on_close({ close = function() end, input = { get = function() return "" end } })
        assert.is_true(cancelled)
    end)

    it("should not fire on_cancel after a confirm", function()
        local cancelled = false
        adapter.pick({
            { value = "x", display = "X", ordinal = "x" },
        }, {
            on_select = function() end,
            on_cancel = function()
                cancelled = true
            end,
        })
        pick_opts.confirm({ close = function() end, input = { get = function() return "" end } }, { value = "x" })
        pick_opts.on_close({ close = function() end, input = { get = function() return "" end } })
        assert.is_false(cancelled)
    end)
end)