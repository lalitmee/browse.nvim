local helpers = require("helpers")
helpers.setup_mocks()

describe("browse.picker.mini_pick", function()
    local started
    local adapter
    local chosen_item
    local current_query

    local function stub_minipick()
        _G.MiniPick = {
            start = function(opts)
                started = opts
                return chosen_item
            end,
            get_picker_query = function()
                return vim.split(current_query or "", "")
            end,
            set_picker_query = function(tokens)
                current_query = table.concat(tokens)
            end,
        }
    end

    before_each(function()
        started = nil
        chosen_item = nil
        current_query = ""
        package.loaded["browse.picker.mini_pick"] = nil
        stub_minipick()
        adapter = require("browse.picker.mini_pick")
    end)

    it("should be available only when MiniPick is initialized", function()
        assert.is_true(adapter.available())
        _G.MiniPick = nil
        assert.is_false(adapter.available())
    end)

    it("should build text/value items and start the picker", function()
        adapter.pick({
            { value = "mdn", display = "MDN Web Docs", ordinal = "mdn" },
        }, {
            title = "Browse",
            on_select = function() end,
        })
        assert.is_not_nil(started)
        assert.equal("MDN Web Docs", started.source.items[1].text)
        assert.equal("mdn", started.source.items[1].value)
        assert.equal("Browse", started.source.name)
    end)

    it("should invoke on_select with value and query inside choose", function()
        local value
        local query
        adapter.pick({
            { value = "url", display = "A Bookmark", ordinal = "ord" },
        }, {
            on_select = function(v, q)
                value = v
                query = q
            end,
        })
        current_query = "search term"
        started.source.choose({ text = "A Bookmark", value = "url" })
        assert.equal("url", value)
        assert.equal("search term", query)
    end)

    it("should prefill the query via scheduled set_picker_query", function()
        local scheduled
        vim.schedule = function(fn)
            scheduled = fn
        end
        adapter.pick({
            { value = "x", display = "X", ordinal = "x" },
        }, {
            on_select = function() end,
            default_text = "prefill",
        })
        assert.is_function(scheduled)
        scheduled()
        assert.equal("prefill", current_query)
    end)

    it("should fire on_cancel when start returns nil", function()
        local cancelled = false
        adapter.pick({
            { value = "x", display = "X", ordinal = "x" },
        }, {
            on_select = function() end,
            on_cancel = function()
                cancelled = true
            end,
        })
        assert.is_true(cancelled)
    end)

    it("should left-align window to cursor for cursor layout", function()
        adapter.pick(
            { { value = "x", display = "X", ordinal = "x" } },
            { on_select = function() end, layout = "cursor" }
        )
        assert.equal("cursor", started.window.config.relative)
    end)
end)
