local helpers = require("helpers")
helpers.setup_mocks()

describe("browse.picker.fzf_lua", function()
    local captured
    local adapter

    local function stub_fzf_lua()
        package.loaded["fzf-lua"] = {
            fzf_exec = function(contents, opts)
                captured = { contents = contents, opts = opts }
            end,
        }
    end

    before_each(function()
        captured = nil
        stub_fzf_lua()
        package.loaded["browse.picker.fzf_lua"] = nil
        adapter = require("browse.picker.fzf_lua")
        vim.fn.executable = function(cmd)
            return cmd == "fzf" and 1 or 0
        end
    end)

    it("should be available when fzf binary exists", function()
        assert.is_true(adapter.available())
    end)

    it("should not be available when neither fzf nor skim exists", function()
        vim.fn.executable = function()
            return 0
        end
        assert.is_false(adapter.available())
    end)

    it("should encode entries as ordinal\\tdisplay", function()
        adapter.pick({
            { value = "mdn", display = "MDN Web Docs", ordinal = "mdn" },
            { value = "open", display = "Open File", ordinal = "open" },
        }, {
            title = "Browse",
            on_select = function() end,
        })
        assert.are.same(
            { "mdn\tMDN Web Docs", "open\tOpen File" },
            captured.contents
        )
    end)

    it("should wire default action to on_select with value and query", function()
        local value
        local query
        adapter.pick({
            { value = "url", display = "My Bookmark", ordinal = "my" },
        }, {
            on_select = function(v, q)
                value = v
                query = q
            end,
        })
        captured.opts.actions["default"]({ "my\tMy Bookmark" }, { last_query = "search" })
        assert.are.equal("url", value)
        assert.are.equal("search", query)
    end)

    it("should set default_text as query prefill", function()
        adapter.pick({
            { value = "x", display = "X", ordinal = "x" },
        }, {
            on_select = function() end,
            default_text = "prefill",
        })
        assert.are.equal("prefill", captured.opts.query)
    end)

    it("should wire esc to on_cancel when provided", function()
        local cancelled = false
        adapter.pick({
            { value = "x", display = "X", ordinal = "x" },
        }, {
            on_select = function() end,
            on_cancel = function()
                cancelled = true
            end,
        })
        captured.opts.actions["esc"]({})
        assert.is_true(cancelled)
    end)

    it("should not wire esc without on_cancel", function()
        adapter.pick({
            { value = "x", display = "X", ordinal = "x" },
        }, {
            on_select = function() end,
        })
        assert.is_nil(captured.opts.actions["esc"])
    end)
end)
