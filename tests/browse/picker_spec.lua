local helpers = require("helpers")
helpers.setup_mocks()

describe("browse.picker (resolver facade)", function()
    local calls
    local config

    local function fake_adapter(name, available_ok)
        return {
            available = function() return available_ok end,
            pick = function(entries, opts)
                table.insert(calls, { name = name, entries = entries, opts = opts })
                return true
            end,
        }
    end

    before_each(function()
        calls = {}
        package.loaded["browse.picker"] = nil
        package.loaded["browse.picker.telescope"] = nil
        package.loaded["browse.picker.fzf_lua"] = nil
        package.loaded["browse.picker.mini_pick"] = nil
        package.loaded["browse.picker.snacks"] = nil
        package.loaded["browse.config"] = nil
        config = require("browse.config")

        -- Seed the four adapter modules with fakes so `require` resolves
        package.loaded["browse.picker.telescope"] = fake_adapter("telescope", true)
        package.loaded["browse.picker.fzf_lua"] = fake_adapter("fzf_lua", true)
        package.loaded["browse.picker.mini_pick"] = fake_adapter("mini_pick", true)
        package.loaded["browse.picker.snacks"] = fake_adapter("snacks", true)
    end)

    it("should pick the configured backend", function()
        config.opts.picker = "fzf_lua"
        require("browse.picker").pick({ { value = "a" } }, { title = "T" })
        assert.are.equal("fzf_lua", calls[#calls].name)
    end)

    it("should pass entries and opts straight through", function()
        config.opts.picker = "snacks"
        local entries = { { value = "v", display = "d", ordinal = "o" } }
        local pick = require("browse.picker")
        pick.pick(entries, { title = "Menu" })
        assert.are.same(entries, calls[1].entries)
        assert.are.equal("Menu", calls[1].opts.title)
    end)

    it("should merge user picker_opts into the call opts", function()
        local config_mod = require("browse.config")
        config_mod.opts.picker = "fzf_lua"
        config_mod.opts.picker_opts = { fzf_lua = { winopts = { height = 10 } } }
        require("browse.picker").pick({ { value = "a" } }, { title = "x" })
        -- call-site opts (title) win; user passthrough (winopts) survives
        assert.are.equal("x", calls[1].opts.title)
        assert.are.equal(10, calls[1].opts.winopts.height)
    end)

    it("should fall back to telescope when configured backend is unavailable", function()
        package.loaded["browse.picker.fzf_lua"] = fake_adapter("fzf_lua", false)
        local notices = 0
        vim.notify = function()
            notices = notices + 1
        end
        local config_mod = require("browse.config")
        config_mod.opts.picker = "fzf_lua"
        require("browse.picker").pick({ _ = { value = "a" } }, {})
        assert.are.equal("telescope", calls[#calls].name)
        assert.is_true(notices >= 1)
    end)

    it("should fall back to telescope when adapter throws at runtime", function()
        package.loaded["browse.picker.fzf_lua"] = {
            available = function() return true end,
            pick = function()
                error("boom")
            end,
        }
        local config_mod = require("browse.config")
        config_mod.opts.picker = "fzf_lua"
        require("browse.picker").pick({ _ = { value = "a" } }, {})
        -- telescope adapter invoked as the rescue
        assert.are.equal("telescope", calls[#calls].name)
    end)

    it("should default to telescope for unknown picker name", function()
        local config_mod = require("browse.config")
        config_mod.opts.picker = "unknown_backend"
        require("browse.picker").pick({ { value = "a" } }, {})
        assert.are.equal("telescope", calls[#calls].name)
    end)
end)
