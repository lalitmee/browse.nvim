local helpers = require("helpers")
helpers.setup_mocks()

describe("browse.config", function()
    local config

    before_each(function()
        package.loaded["browse.config"] = nil
        config = require("browse.config")
    end)

    it("should default to telescope picker with empty passthrough opts", function()
        assert.are.equal("telescope", config.opts.picker)
        assert.is_table(config.opts.picker_opts)
        assert.is_true(vim.tbl_isempty(config.opts.picker_opts))
    end)

    it("should expose default generic layouts", function()
        assert.are.equal("dropdown", config.opts.layouts.browse)
        assert.are.equal("dropdown", config.opts.layouts.manual_bookmarks)
    end)

    it("should translate legacy themes into layouts with one deprecation notice", function()
        local notify_ok = false
        vim.notify = function(_, level)
            if level == vim.log.levels.WARN then notify_ok = true end
        end

        config.setup({ themes = { browse = "cursor" } })

        assert.is_true(notify_ok)
        assert.are.equal("cursor", config.opts.layouts.browse)
    end)

    it("should not translate when layouts is explicitly set", function()
        local notify_ok = false
        vim.notify = function(_, level)
            if level == vim.log.levels.WARN then notify_ok = true end
        end

        config.setup({ layouts = { browse = "ivy" }, themes = { browse = "cursor" } })

        assert.is_false(notify_ok)
        assert.are.equal("ivy", config.opts.layouts.browse)
    end)
end)
