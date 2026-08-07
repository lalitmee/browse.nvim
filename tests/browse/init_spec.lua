local helpers = require("helpers")
helpers.setup_mocks()

describe("browse.init", function()
    local rg_callbacks

    local function stub_routes()
        rg_callbacks = {}
        package.loaded["browse.input"] = {
            search_input = function(vt)
                rg_callbacks["input"] = vt
            end,
        }
        package.loaded["browse.devdocs"] = {
            search = function(vt)
                rg_callbacks["devdocs"] = vt
            end,
            search_with_filetype = function(vt)
                rg_callbacks["devdocs_file"] = vt
            end,
        }
        package.loaded["browse.mdn"] = {
            search = function(vt)
                rg_callbacks["mdn"] = vt
            end,
            search_with_filetype = function(vt)
                rg_callbacks["mdn_file"] = vt
            end,
        }
        package.loaded["browse.bookmarks"] = {
            search_bookmarks = function(cfg)
                rg_callbacks["bookmarks"] = cfg
            end,
        }
    end

    before_each(function()
        helpers.mock_picker()
        stub_routes()
        package.loaded["browse.init"] = nil
        package.loaded["browse.config"] = nil
    end)

    it("should create the unified Browse command when configured", function()
        local command_created = nil
        vim.api.nvim_create_user_command = function(name, _, opts)
            if name == "Browse" then
                command_created = { name = name, opts = opts }
            end
        end
        local browse = require("browse.init")
        browse.setup({ create_commands = true })
        assert.is_not_nil(command_created)
    end)

    it("should NOT create commands when disabled", function()
        local commands_created = {}
        vim.api.nvim_create_user_command = function(name, _, opts)
            commands_created[name] = true
        end
        local browse = require("browse.init")
        browse.setup({ create_commands = false })
        assert.is_true(vim.tbl_isempty(commands_created))
    end)

    it("should open the browse menu with six entries", function()
        local browse = require("browse.init")
        browse.browse()
        local calls = helpers.get_picker_calls()
        assert.equal(1, #calls)
        local entries = calls[1].entries
        assert.equal(6, #entries)
        assert.equal("Browse", calls[1].opts.title)
        assert.equal("Manual Bookmarks", entries[1].display)
        assert.equal("manual_bookmarks", entries[1].value)
    end)

    it("should dispatch menu actions through on_select", function()
        local browse = require("browse.init")
        browse.browse()
        -- select Input Search
        helpers.simulate_select("input", "")
        assert.is_not_nil(rg_callbacks["input"])
        -- select Devdocs Search with filetype
        helpers.simulate_select("devdocs_file", "")
        assert.is_not_nil(rg_callbacks["devdocs_file"])
        -- select MDN
        helpers.simulate_select("mdn", "")
        assert.is_not_nil(rg_callbacks["mdn"])
        -- select Manual Bookmarks
        helpers.simulate_select("manual_bookmarks", "")
        assert.is_not_nil(rg_callbacks["bookmarks"])
        assert.equal("manual", rg_callbacks["bookmarks"].source)
    end)
end)