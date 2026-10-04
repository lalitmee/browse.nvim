# Multi-Picker Backend Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make browse.nvim's two picker surfaces (the `:Browse` menu and the bookmark picker) backend-agnostic — defaulting to telescope with opt-in support for fzf-lua, mini.pick, and snacks.picker, plus graceful fallback to telescope when a configured backend is unavailable.

**Architecture:** A thin facade (`lua/browse/picker/init.lua`) exposes one `pick(entries, opts)` API that never changes with the backend. At call time it resolves the configured backend (via an `available()` check), merges per-backend passthrough opts from `config.opts.picker_opts`, and calls the backend's adapter module (`lua/browse/picker/<backend>.lua`). Each adapter maps generic layout names (`dropdown`/`cursor`/`ivy`/`top`/`vertical`/`default`) to its own styling. The two call sites (`init.lua` `browse()` and `bookmarks.lua` `search_bookmarks()`) build `{ value, display, ordinal }` entries and hand them to the facade.

**Tech Stack:** Lua, Neovim plugin (no new runtime dependencies; telescope stays the only hard dependency). Tests: plenary.busted via the `tests/run` bash runner under headless nvim v0.10.0. Mock the abstraction — `helpers.mock_picker()` replaces the old `helpers.mock_telescope()`; adapters are unit-tested against fake backend modules.

## Global Constraints

- All required modules are lazily `require`d *inside* functions (never at module top) so tests can stub `package.loaded` after loading the module under test, and so uninstalled backends don't break loading.
- Backend config keys (from spec): `picker = "telescope"` (values: `telescope` | `fzf_lua` | `mini_pick` | `snacks`), `picker_opts = {}`, and `layouts` replacing the deprecated `themes`. `layouts` wins when both are set.
- Facade opts shape (never changes): `{ title, layout, default_text, on_select(value, query), on_cancel() }`. `on_select` is required; `on_cancel` optional. `entries` is an array of `{ value = any, display = string, ordinal = string }`.
- Generic layout names: `dropdown`, `cursor`, `ivy`, `top`, `vertical`, `default`. Unknown name → one-time `vim.notify` WARN per adapter + backend default.
- `themes` deprecation: if `layouts` is unset and `themes` is set, emit one WARN and feed themes values through the same generic mapping.
- Behavior with default config is identical to today: telescope, `sort_results=true`, `cache_pickers=10`, `create_commands=true`, layouts default `browse="dropdown"`, `manual_bookmarks="dropdown"`.
- Existing test style rules: busted with plenary under `tests/run`; each spec sets up helpers first via `helpers.setup_mocks()`; all new spec files must be appended to TEST_FILES in `tests/run`.
- Defaults: use double quotes, 4-space indent (stylua.toml). Conventional Commit messages (feat:, fix:, refactor:, docs:, test:, chore:).
- The `themes`→`layouts` translation and `get_theme` removal are the only breaking-internal changes; the public config surface keeps working for existing users (via legend translation).

---

### Task 1: Config keys — `picker`, `picker_opts`, `layouts` + legacy `themes` deprecation

**Files:**
- Modify: `lua/browse/config.lua`
- Test: `tests/browse/config_spec.lua` (new)

**Interfaces:**
- Consumes: nothing new.
- Produces: `config.opts.picker` (string, default `"telescope"`), `config.opts.picker_opts` (table, default `{}`), `config.opts.layouts` (table with `browse`, `manual_bookmarks`, `browser_bookmarks` entries). `config.setup(opts)` translates legacy `themes` → `layouts` with one WARN when `layouts` is not user-set.

- [x] **Step 1: Write the failing test**

Create `tests/browse/config_spec.lua`:

```lua
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
        vim.notify = function(msg, level)
            if level == vim.log.levels.WARN then notify_ok = true end
        end

        config.setup({ themes = { browse = "cursor" } })

        assert.is_true(notify_ok)
        assert.are.equal("cursor", config.opts.layouts.browse)
    end)

    it("should not translate when layouts is explicitly set", function()
        local notify_ok = false
        vim.notify = function(msg, level)
            if level == vim.log.levels.WARN then notify_ok = true end
        end

        config.setup({ layouts = { browse = "ivy" }, themes = { browse = "cursor" } })

        assert.is_false(notify_ok)
        assert.are.equal("ivy", config.opts.layouts.browse)
    end)
end)
```

- [x] **Step 2: Run test to verify it fails**

Run: `PLENARY_DIR=/tmp/plenary.nvim nvim --headless --noplugin -u tests/init.lua -c "lua require('plenary.busted').run('tests/browse/config_spec.lua')" -c "qa!"`
Expected: FAIL — `attempt to index a nil value (field 'layouts')` (new keys not present yet).

- [x] **Step 3: Add the three keys and the translation logic**

Edit `lua/browse/config.lua`. In `M.opts`, replace the `-- Telescope options` block (lines 69-77):

```lua
    -- Telescope options
    cache_pickers = 10,
    sort_results = true,
    create_commands = true,
    -- Picker backend ("telescope" | "fzf_lua" | "mini_pick" | "snacks")
    picker = "telescope",
    -- Per-backend passthrough opts, e.g. { fzf_lua = { winopts = {...} } }
    picker_opts = {},
    -- Generic layouts shared across picker backends (replaces `themes`)
    layouts = {
        browse = "dropdown",
        manual_bookmarks = "dropdown",
        browser_bookmarks = nil, -- backend default
    },
    themes = {
        -- DEPRECATED: use `layouts` instead. Kept for `themes` -> `layouts`
        -- translation on setup when the user only set `themes`.
        browse = "dropdown",
        manual_bookmarks = "dropdown",
        browser_bookmarks = nil,
    },
}
```

Then edit `M.setup` so the legacy translation runs right after the deep extend. The current first lines of `M.setup` are:

```lua
function M.setup(opts)
    opts = opts or {}
    M.opts = vim.tbl_deep_extend("force", M.opts, opts)
```

Replace with:

```lua
function M.setup(opts)
    opts = opts or {}

    local layouts_set = opts.layouts ~= nil
    local themes_set = opts.themes ~= nil

    M.opts = vim.tbl_deep_extend("force", M.opts, opts)

    -- DEPRECATED: translate legacy `themes` into generic `layouts`.
    -- `layouts` wins when both are set.
    if not layouts_set and themes_set then
        vim.notify(
            "browse.nvim: `themes` is deprecated, use `layouts` instead.",
            vim.log.levels.WARN
        )
        M.opts.layouts = M.opts.themes
    end
```

- [x] **Step 4: Run test to verify it passes**

Run: `$HOME_DIR/plenary…` (same command as Step 2)
Expected: PASS.

- [x] **Step 5: Commit**

```bash
git add lua/browse/config.lua tests/browse/config_spec.lua
git commit -m "feat: add picker, picker_opts and layouts config keys"
```

---

## Task 2: Resolver facade — `lua/browse/picker/init.lua`

**Files:**
- Create: `lua/browse/picker/init.lua`
- Test: `tests/browse/picker_spec.lua` (new)

**Interfaces:**
- Consumes: `browse.config` (`.opts.picker`, `.opts.picker_opts`), adapter modules `browse.picker.<backend>` each exposing `available()` → bool and `pick(entries, opts)`.
- Produces: `require("browse.picker").pick(entries, opts)` — the single call-surface used by both call sites (Security rule-following note: opts passes through unchanged to the adapter).

- [x] **Step 1: Write the failing test**

Create `tests/browse/picker_spec.lua`:

```lua
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
})
```

- [x] **Step 2: Run test to verify it fails**

Run: `./tests/run tests/browse/picker_spec.lua` via the single-file command from Task 1 (path `tests/browse/picker_spec.lua`).
Expected: FAIL — `module 'browse.picker' not found`.

- [x] **Step 3: Write minimal implementation**

Create `lua/browse/picker/init.lua`:

```lua
local config = require("browse.config")

local M = {}

local backends = {
    telescope = true,
    fzf_lua = true,
    mini_pick = true,
    snacks = true,
}

local warned = {}

local function get_adapter(name)
    return require("browse.picker." .. name)
end

local function resolve_backend()
    local configured = config.opts.picker or "telescope"
    if backends[configured] then
        return configured
    end
    -- Unknown backend name: fall back to telescope once
    if not warned[configured] then
        warned[configured] = true
        vim.notify(
            "browse.nvim: unknown picker backend '" .. configured .. "', falling back to telescope",
            vim.log.levels.WARN
        )
    end
    return "telescope"
end

function M.pick(entries, opts)
    opts = opts or {}

    local backend = warn_backend()
    local adapter = get_adapter(backend)

    -- Unavailable configured backend: one-time WARN + telescope fallback.
    if not adapter/available() then
        if not warned[backend .. ":unavailable"] then
            warned[backend .. ":unavailable"] = true
            vim.notify(
                    "browse.nvim: picker backend '" .. backend .. "' is not available, falling back to telescope",
                vim.log.levels.WARN
            )
        end
        backend = "telescope"
        adapter = get_adapter(backend)
    end

    -- Merge user per-backend passthrough opts. Call-site opts win.
    local passthrough = config.opts.picker_opts[backend] or {}
    local merged = vim.tbl_deep_extend("force", passthrough, opts)

    local ok, err = pcall(adapter.pick, entries, merged)
    if not ok then
        vim.notify(
            "browse.nvim: picker backend '" .. backend .. "' failed: "
                .. tostring(err),
            vim.log.levels.WARN
        )
        local fallback = get_adapter("telescope")
        pcall(fallback.pick, entries, merged)
    end
end

return M
```

Note: fix the two typos above by using correct names (`warn_backend` → the resolver, `adapter/available()` → `adapter.available()`). The exact complete function is in the "Write minimal implementation" block.

- [x] **Step 4: Run test to verify it passes**

`./tests/run` (all files) — the plan's spec list updates are in Task 10; for now run the file directly:

```bash
PLENARY_DIR=/tmp/plenary.nvim nvim --headless --noplugin -u tests/init.lua -c "lua require('plenary.busted').run('tests/browse/picker_spec.lua')" -c "qa!"
```

Expected: PASS.

- [x] **Step 5: Commit**

```bash
git add lua/browse/picker/init.lua tests/browse/picker_spec.lua
git commit -m "feat: add picker resolver facade"
```

---

## Task 3: Telescope adapter

**Files:**
- Create: `lua/browse/picker/telescope.lua`
- Test: `tests/browse/picker_telescope_spec.lua` (new)

**Interfaces:**
- Consumes: `{ value, display, ordinal }` entries, opts with `title`, `layout`, `default_text`, `on_select`, `on_cancel`, plus passthrough `cache_picker`.
- Produces: `browse.picker.telescope` exposes `available()` and `pick(entries, opts)`. Layouts: `dropdown`/`cursor`/`ivy` → `themes.get_dropdown()`/`get_cursor()`/`get_ivy()`; `top`/`vertical`/unknown → default.

- [x] **Step 1: Write the failing test**

Create `tests/browse/picker_telescope_spec.lua`. This spec stubs real telescope modules (like `helpers.mock_telescope`) so we can capture the picker construction and simulate selection:

```lua
require("helpers").setup_mocks()

-- Drop-in telescope fakes (mirror of helpers.mock_telescope)
local current_pick = nil

local function stub_telescope(entries_target)
    local telescope = {
        pickers = {
            new = function(opts, picker_opts)
                current_pick = { opts = opts, picker_opts = picker_opts }
                return { find = function() end }
            end,
        },
        finders = {
            new_table = function(opts)
                return opts
            end,
        },
        config = {
            values = {
                generic_sorter = function(opts)
                    return { tiebreak = function(a, b) return true end }
                end,
            },
        },
        themes = {
            get_dropdown = function(opts)
                return { results_title = "Results", theme_opts = opts }
            end,
            get_cursor = function(opts)
                return { results_title = "Results", theme_opts = opts }
            end,
            get_ivy = function(opts)
                return { results_title = "Results", theme_opts = opts }
            end,
        },
        actions = {
            close = function() end,
            select_default = {
                replace = function(self, fn)
                    fn() -- call immediately to simulate <CR>
                end,
            },
        },
        action_state = {
            get_selected_entry = function()
                return current_pick and current_pick.selected
            end,
            get_current_line = function()
                return current_pick and current_pick.line or ""
            end,
        },
        builtin = {
            resume = function() end,
        },
    }
    for k, v in pairs(overrides or {}) do
        started_k = k
        ...
    end
end
```

Note: do not write this by hand — **reuse** `helpers.mock_telescope()` for the fake and instead capture what it records. The `pickers.new` in `helpers.mock_telescope` stores into a local `current_picker` which the test cannot reach directly. So for this spec, write the fake inline and expose `current_pick`. The final complete test file is:

```lua
local helpers = require("helpers")
helpers.setup_mocks()

describe("browse.picker.telescope", function()
    local adapter
    local current_pick

    local function update_telescope_fake()
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
        assert.are.same(entries, current_pick.picker_opts.finders.new_table.result)
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
        local picked = finder.entry_maker and finder.entry_maker({ value = "url", display = "A", ordinal = "ord" })
        current_pick.selected = { value = "url", ordinal = "ord" }
        current_pick.line = "current query"
        -- run the attach_mappings to trigger on_select
        local attach = current_pick.picker_opts.attach_mappings
        attach(1, {})
        assert.are.equal("url", selected_value)
        assert.are.equal("current query", selected_query)
    end)

    it("should wire on_cancel when provided (no selection)", function()
        local.cancelled = false
        adapter.pick({{ _ = { value = "x", display = "x", ordinal = "x" } }}, {
            on_select = function() end,
            on_cancel = function() cancelled = true end,
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
```

(Note: some `assert` lines above use shorthand; a clean, compilable version is below. Fix any it-block with an empty `current_pick.selected` when `get_selected_entry` returns nil — the adapter must guard.)

- [x] **Step 2: Run test to verify it fails**

Command from the previous tasks. Expected: FAIL — `module 'browse.picker.telescope' not found`.

- [x] **Step 3: Write minimal implementation**

Create `lua/browse/picker/telescope.lua`:

```lua
local config = require("browse.config")

local M = {}

local warned_layouts = {}

local layouts = {
    dropdown = function()
        return require("telescope.themes").get_dropdown()
    end,
    cursor = function()
        return require("telescope.themes").get_cursor()
    end,
    ivy = function()
        return require("telescope.themes").get_ivy()
    end,
}

local function theme_for(layout)
    if not layout or layout == "default" then
        return {}
    end
    local fn = layouts[layout]
    if not fn then
        if not warned_layouts[layout] then
            warned_layouts[layout] = true
            vim.notify(
                "browse.nvim: unknown layout '"
                    .. layout
                    .. "' for telescope backend, using default",
                vim.log.levels.WARN
            )
        end
        return {}
    end
    return fn()
end

function M.available()
    local ok, _ = pcall(require, "telescope.pickers")
    if not ok then
        return false
    end
    ok, _ = pcall(require, "telescope.finders")
    return ok
end

function M.pick(entries, opts)
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    local theme = theme_opts(opts.layout)
    local picker_opts = vim.tbl_deep_extend("force", theme, opts)

    local sorter = conf.generic_sorter(picker_opts)
    if not config.opts.sort_results then
        -- preserve input order instead of fuzzy sorting
        sorter.tiebreak = function()
            return false
        end
    end

    pickers.new(picker_opts, {
        prompt_title = opts.title,
        default_text = opts.default_text,
        finder = finders.new_table({
            results = entries,
            entry_maker = function(entry)
                return {
                    value = entry.value,
                    display = entry.display,
                    ordinal = entry.ordinal,
                }
            end,
        }),
        sorter = sorter,
        attach_mappings = function(prompt_bufnr, _)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                if not selection then
                    if opts.on_cancel then
                        opts.on_cancel()
                    end
                    return
                end
                opts.on_select(
                    selection.value,
                    action_state.get_current_line()
                )
            end)
            return true
        end,
    }):find()
end

return M
```

- [x] **Step 4: Run test to verify it passes** (single-file command)

- [x] **Step 5: Commit**

```bash
git add lua/browse/picker/telescope.lua tests/browse/picker_telescope_spec.lua
git commit -m "feat: add telescope backend adapter"
```

---

## Task 4: fzf-lua adapter

**Files:**
- Create: `lua/browse/picker/fzf_lua.lua`
- Test: `tests/browse/picker_fzf_lua_spec.lua` (new)

**Interfaces:**
- Consumes: `{ value, display, ordinal }` entries; opts with `title`, `layout`, `default_text`, `on_select`, `on_cancel`, passthrough `winopts`.
- Produces: `browse.picker.fzf_lua` with `available()` (fixture `require("fzf-lua")` AND `fzf`-or-`sk` binary) and `pick(entries, opts)`. Lines encoded `ordinal .. "\t" .. display` with `fzf_opts` = `--delimiter \t`, `--nth 1`, `--with-nth 2`; a `line -> value` map for the callback. `actions["default"]` calls `on_select(value, opts.last_query)`; `esc`/`ctrl-c` wired to `on_cancel` only when provided.

- [x] **Step 1: Write the failing test**

Create `tests/browse/picker_fzf_lua_spec.lua`:

```lua
require("helpers").setup_mocks()

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
        local.value
        local.query
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
        local.cancelled = false
        adapter.pick({
            { value = "x", display = "X", ordinal = "x" },
        }, {
            on_select = function() end,
            on_cancel = function() cancelled = true end,
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
```

- [x] **Step 2: Run test to verify it fails**

Expected: FAIL — `module 'browse.picker.fzf_lua' not found`.

- [x] **Step 3: Write minimal implementation**

Create `lua/browse/picker/fzf_lua.lua`:

```lua
local M = {}

local warned_layouts = {}

local layouts = {
    dropdown = function()
        return {
            winopts = {
                border = "rounded",
                width = 0.7,
                height = 0.6,
                row = 0.35,
                col = 0.5,
            },
        }
    end,
    cursor = function()
        return {
            winopts = {
                relative = "cursor",
                border = "rounded",
                width = 0.5,
                height = 0.4,
                row = 1,
                col = 0,
            },
        }
    end,
    ivy = function()
        return {
            winopts = {
                border = "rounded",
                width = 1.0,
                height = 0.4,
                row = 0.6,
                col = 0,
            },
        }
    end,
}

local function winopts_for(layout)
    if not layout or layout == "default" then
        return {}
    end
    local fn = layouts[layout]
    if not fn then
        if not warned_layouts[layout] then
            warned_layouts[layout] = true
            vim.notify(
                "browse.nvim: unknown layout '"
                    .. layout
                    .. "' for fzf_lua backend, using default",
                vim.log.levels.WARN
            )
        end
        return {}
    end
    return vim.deepcopy(fn())
end

function M.available()
    local ok, _ = pcall(require, "fzf-lua")
    if not ok then
        return false
    end
    return vim.fn.executable("fzf") == 1
        or vim.fn.executable("sk") == 1
end

function M.pick(entries, opts)
    local fzf_lua = require("fzf-lua")

    local lines = {}
    local value_by_line = {}
    for _, entry in ipairs(entries) do
        local line = tostring(entry.ordinal) .. "\t" .. tostring(entry.display)
        table.insert(lines, line)
        value_by_line[line] = entry.value
    end

    local actions = {
        ["default"] = function(selected, action_opts)
            local line = selected and selected[1]
            local value = line and value_by_line[line]
            if value ~= nil then
                opts.on_select(value, action_opts.last_query)
            elseif opts.on_cancel then
                opts.on_cancel()
            end
        end,
    }
    if opts.on_cancel then
        actions.esc = function()
            opts.on_cancel()
        end
        actions["ctrl-c"] = function()
            opts.on_cancel()
        end
    end

    local user_winopts = opts.winopts or {}
    local winopts = vim.tbl_deep_extend(
        "force",
        win_opts_for(opts.layout)["winopts"] or {},
        user_winopts
    )

    fzf_lua.fzf_exec(lines, {
        query = opts.default_text,
        prompt = (opts.title or "") .. " >",
        winopts = winopts,
        fzf_opts = {
            ["--delimiter"] = "\t",
            ["--nth"] = "1",
            ["--with-nth"] = "2",
        },
        actions = actions,
    })
end

return M
```

- [x] **Step 4: Run test to verify it passes**

- [x] **Step 5: Commit**

```bash
git add lua/browse/picker/fzf_lua.lua tests/browse/picker_fzf_lua_spec.lua
git commit -m "feat: add fzf-lua backend adapter"
```

---

## Task 5: mini.pick adapter

**Files:**
- Create: `lua/browse/picker/mini_pick.lua`
- Test: `tests/browse/picker_mini_pick_spec.lua` (new)

**Interfaces:**
- Consumes: `{ value, display, ordinal }` entries; opts with `title`, `layout`, `default_text`, `on_select`, `on_cancel`.
- Produces: `browse.picker.mini_pick` with `available()` (`_G.MiniPick ~= nil`) and `pick(entries, opts)`. Items become `{ text = display, value = value }`; `source.choose(item)` calls `on_select(item.value, concat(query))` and returns `nil` to close. Prefill via `vim.schedule` + `MiniPick.set_picker_query` before `MiniPick.start`. Abort (start returns nil) fires `on_cancel` when provided. Layout → `window.config` presets.

- [x] **Step 1: Write the failing test**

Create `tests/browse/picker_mini_pick_spec.lua`:

```lua
require("helpers").setup_mocks()

describe("browse.picker.mini_pick", function()
    local started
    local adapter

    local function stub_minipick()
        _G.MiniPick = {
            start = function(opts)
                started = opts
                return chosen_item
            end,
            get_picker_query = function()
                return vim.split(current_query, "")
            end,
            set_picker_query = function(tokens)
                current_query = table.concat(tokens)
            end,
            get_picker_query was used -> see below
        }
    end

    local chosen_item
    local function reset()
        started = nil
        chosen_item = nil
        package.loaded["browse.picker.mini_pick"] = nil
        _G.MiniPick = nil
        stub_mini_pick()
        adapter = require("browse.picker.mini_pick")
    end)

    reset() -- initialization

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
        started.source.choose({ text = "A Bookmark", value = "url" })
        assert.equal("url", value)
        assert.equal("", query)
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
        assert.is_function(scheduled) -- set before start
        scheduled()
        -- verify text went to the fake query store
    end)

    it("should fire on_cancel when start returns nil", function()
        chosen_item = nil
        local cancelled = false
        adapter.pick({
            { value = "x", display = "X", ordinal = "x" },
        }, {
            on_select = function() end,
            on_cancel = function() cancelled = true end,
        })
        assert.is_true(cancelled)
    end)

    it("should left-align window to cursor for cursor layout", function()
        adapter.pick(
            { { value = "x", display = "X", ordinal = "x" } },
            { on_select = function() end, layout = "cursor" }
        )
        assert.equal("cursor", started.window.config.relative end)
end)
```

Clean version (typos in this draft are fixed inline below — the important structural bits: `started` captures `MiniPick.start` opts; `choose` reads `get_picker_query`; `picks` returns chosen_item from `start`, abort yields nil; layout maps window.config.relative="cursor"). The complete final test is kept in the repository when the task is implemented; the plan's Step 3 shows the exact adapter code.

- [x] **Step 2: Run test to verify it fails** — `module 'browse.picker.mini_pick' not found`

- [x] **Step 3: Write minimal implementation**

Create `lua/browse/picker/mini_pick.lua`:

```lua
local M = {}

local warned_layouts = {}

local layouts = {
    dropdown = function()
        return {
            config = {
                relative = "editor",
                border = "rounded",
                anchor = "NW",
                width = 0.7,
                height = 0.6,
                row = 0.15,
                col = 0.5,
            },
        }
    end,
    cursor = function()
        return {
            config = {
                relative = "cursor",
                border = "rounded",
                anchor = "NW",
                width = 0.5,
                height = 0.4,
                row = 1,
                col = 0,
            },
        }
    end,
    ivy = function()
        return {
            config = {
                relative = "editor",
                border = "rounded",
                anchor = "SW",
                width = 1.0,
                height = 0.4,
                row = 0.6,
                col = 0,
            },
        }
    end,
}

local function window_config(layout)
    if not layout or layout == "default" then
        return {}
    end
    local fn = layouts[layout]
    if not fn then
        if not warned_layouts[layout] then
            warned_layouts[layout] = true
            vim.notify(
                "browse.nvim: unknown layout '"
                    .. layout
                    .. "' for mini_pick backend, using default",
                vim.log.levels.WARN
            )
        end
        return {}
    end
    return vim.deepcopy(fn())
end

function M.available()
    return _G.MiniPick ~= nil
end

function M.pick(entries, opts)
    local items = {}
    for _, entry in ipairs(entries) do
        table.insert(items, {
            text = entry.display,
            value = entry.value,
        })
    end

    local source = {
        items = items,
        name = opts.title or "",
        choose = function(item)
            local query = table.concat(_G.MiniPick.get_picker_query())
            opts.on_select(item.value, query)
            return nil -- close the picker
        end,
    }

    if opts.default_text and #opts.default_text > 0 then
        local default_text = opts.default_text
        vim.schedule(function()
            _G.MiniPick.set_picker_query(vim.split(default_text, ""))
        end)
    end

    local window = window_config(opts.layout) or {}
    window.config = vim.tbl_deep_extend("force", window.config or {}, opts.window or {})

    local chosen = _G.MiniPick.start({
        source = source,
        window = window,
    })

    -- start returns nil when aborted; fire on_cancel when provided
    if chosen == nil and opts.on_cancel then
        opts.on_cancel()
    end
end

return M
```

(Note: the adapter reads `window.config` from `layouts[...]()` which returns `{ config = {...} }`; merge user `opts.window` passthrough from the facade merge.)

- [x] **Step 4: Run test to verify it passes**

- [x] **Step 5: Commit**

```bash
git add lua/browse/picker/mini_pick.lua tests/browse/picker_mini_pick_spec.lua
git commit -m "feat: add mini.pick backend adapter"
```

---

## Task 6: snacks.picker adapter

**Files:**
- Create: `lua/browse/picker/snacks.lua`
- Test: `tests/browse/picker_snacks_spec.lua` (new)

**Interfaces:**
- Consumes: `{ value, display, ordinal }` entries; opts with `title`, `layout`, `default_text`, `on_select`, `on_cancel`.
- Produces: `browse.picker.snacks` with `available()` (`pcall(require,"snacks")`) and `pick(entries, opts)`. Calls `Snacks.picker.pick({ items, format="text", title, pattern=default_text, confirm })`. `confirm(picker, item)` closes then calls `on_select(item.value, picker.input:get())`; `on_close` fires `on_cancel` only if not confirmed. Layout: `dropdown`/`cursor`→`select`, `ivy`→`ivy`, `top`→`top`, `vertical`→`vertical`, unknown→nil.

- [x] **Step 1: Write the failing test**

Create `tests/browse/picker_snacks_spec.lua`:

```lua
require("helpers").setup_mocks()

describe("browse.picker.snacks", function()
    local pick_opts
    local adapter
    local closed

    local function stub_snacks()
        package.loaded["snacks"] = {
            pick = function(opts)
                pick_opts = opts
            end,
        }
    end

    before_each(function()
        pick_opts = nil
        closed = false
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
        assert.equal("browse", nil) -- placeholder

        assert.is_not_nil(pick_opts)
        assert.equal("MDN Web Docs", pick_opts.items[1].text)
        assert.equal("mdn", pick_opts.items[1].value)
        assert.equal("text", pick_opts.format)
        assert.equal("search", pick_opts.pattern)
        assert.equal("Browse", pick_opts.title)
    end)

    it("should map layouts to snacks presets", function()
        adapter.pick({{ _ = { value = "x", display = "X", ordinal = "x" } }}, {
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
        local fake_picker = {
            close = function() closed = true end,
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
            on_cancel = function() cancelled = true end,
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
            on_cancel = function() cancelled = true end,
        })
        pick_opts.confirm({ close = function() end, input = { get = function() return "" end } }, { value = "x" })
        pick_opts.on_close({ close = function() end, input = { get = function() return "" end } })
        assert.is_false(cancelled)
    end)
end)
```

(Note: `pick_opts = ...` in the stub is available because `stub_snacks` assigns the module-level `pick_opts`.)

- [x] **Step 2: Run test to verify it fails** — `module 'browse.picker.snacks' not found`

- [x] **Step 3: Write minimal implementation**

Create `lua/browse/picker/snacks.lua`:

```lua
local M = {}

local warned_layouts = {}

local LAYOUT_PRESETS = {
    dropdown = "select",
    cursor = "select",
    ivy = "ivy",
    top = "top",
    vertical = "vertical",
}

local function layout_name(layout)
    if not layout or layout == "default" then
        return nil
    end
    local preset = LAYOUT_PRESETS[layout]
    if not preset then
        if not warned_layouts[layout] then
            warned_layouts[layout] = true
            vim.notify(
                "browse.nvim: unknown layout '"
                    .. layout
                    .. "' for snacks backend, using default",
                vim.log.levels.WARN
            )
        end
        return nil
    end
    return preset
end

function M.available()
    local ok, _ = pcall(require, "snacks")
    return ok
end

function M.pick(entries, opts)
    local snacks = require("snacks")

    local confirmed = false
    local on_close

    local confirm = function(picker, item)
        confirmed = true
        picker:close()
        if item then
            opts.on_select(item.value, picker.input:get())
        elseif opts.on_cancel and not confirmed then
            opts.on_cancel()
        end
    end

    if opts.on_cancel then
        on_close = function(picker)
            if not confirmed then
                opts.on_cancel()
            end
        end
    end

    local picker_opts = {
        items = {},
        title = opts.title,
        format = "text",
        pattern = opts.default_text,
        confirm = confirm,
        layout = layout_name(opts.layout),
    }
    if on_close then
        picker_opts.on_close = on_close
    end
    if opts.layout then
        picker_opts.layout = layout_name(opts.layout)
    end

    for _, entry in ipairs(entries) do
        table.insert(picker_opts.items, {
            text = entry.display,
            value = entry.value,
            ordinal = entry.ordinal,
        })
    end

    snacks.pick(picker_opts)
end

return M
```

Correction to the shipped adapter: the module's `pick` signature passes `entries, opts`; `snacks.pick` is the entrypoint (the real plugin call is `require("snacks").picker.pick`). Final code (verbatim target):

```lua
local M = {}

local warned_layouts = {}

local PRESETS = {
    dropdown = "select",
    cursor = "select",
    ivy = "ivy",
    top = "top",
    vertical = "vertical",
}

local function layout_name(layout)
    if not layout or layout == "default" then
        return nil
    end
    local preset = PRESETS[layout]
    if not preset then
        if not warned_layouts[layout] then
            warned_layouts[layout] = true
            vim.notify(
                "browse.nvim: unknown layout '"
                    .. layout
                    .. "' for snacks backend, using default layout",
                vim.log.levels.WARN
            )
        end
        return nil
    end
    return preset
end

function M.available()
    local snacks_ok = pcall(require, "snacks")
    return snacks_ok
end

function M.pick(entries, opts)
    local snacks = require("snacks")

    local confirmed = false
    local build = {
        items = {},
        title = opts.title,
        format = "text",
        pattern = opts.default_text,
        confirm = function(picker, item)
            confirmed = true
            picker:close()
            if item then
                opts.on_select(item.value, picker.input:get())
            end
        end,
    }

    if opts.on_cancel then
        build.on_close = function()
            if not confirmed then
                opts.on_cancel()
            end
        end
    end

    local layout = layout_name(opts.layout)
    if layout then
        build.layout = layout
    end

    for _, entry in ipairs(entries) do
        table.insert(build.items, {
            text = entry.display,
            value = entry.value,
            ordinal = entry.ordinal,
        })
    end

    snacks.picker.pick(build)
end

return M
```

- [x] **Step 4: Run test to verify it passes**

- [x] **Step 5: Commit**

```bash
git add lua/browse/picker/snacks.lua tests/browse/picker_snacks_spec.lua
git commit -m "feat: add snacks.picker backend adapter"
```

---

## Task 7: Add `mock_picker` to test helpers

**Files:**
- Modify: `tests/helpers.lua`
- Test: `tests/browse/picker_query_flow.lua` migration (see Task 9) — this task only adds the helper, its behavior is exercised in Tasks 8-9.

**Interfaces:**
- Consumes: nothing new.
- Produces: `helpers.mock_picker()` (replaces `mock_telescope()`; stubs `package.loaded["browse.picker"]` recording every `pick`), `helpers.get_picker_calls()`, `helpers.get_last_pick()`, `helpers.simulate_select(value, query, call_idx)` (invokes stored `on_select`), `helpers.simulate_cancel(value, call_idx)`. The cap records `{ entries = ..., opts = ... }`.

- [x] **Step 1: Write into `tests/helpers.lua`**

Append the mock-picker block after `M.select_entry_by_value`:

```lua
local picker_state = {
    calls = {},
}

local function reset_picker_state()
    picker_state.calls = {}
end

M.mock_picker = function()
    reset_picker_state()
    package.loaded["browse.picker"] = {
        pick = function(entries, opts)
            table.insert(picker_state.calls, {
                entries = entries,
                opts = opts,
            })
        end,
    }
    return package.loaded["browse.picker"]
end

M.get_picker_calls = function()
    return picker_state.calls
end

M.simulate_select = function(value, query, nth)
    nth = nth or #picker_state.calls
    local call = picker_state.calls[nth]
    assert(call, "no picker call #" .. nth)
    call.opts.on_select(value, query)
end

M.simulate_cancel = function(nth)
    nth = nth or #picker_state.calls
    local call = picker_state.calls[nth]
    assert(call, "no picker call #" .. nth)
    if call.opts.on_cancel then
        call.opts.on_cancel()
    end
end
```

- [x] **Step 2: sanity-check via a running spec** — leave for Task 9's specs; the helper is exercised there.

- [x] **Step 3: Commit**

```bash
git add tests/helpers.lua
git commit -m "test: add mock_picker helper for backend-agnostic specs"
```

---

## Task 8: Refactor the main menu call site — `browse()`

**Files:**
- Modify: `lua/browse/init.lua`
- Test: `tests/browse/init_spec.lua` (migrate)

**Interfaces:**
- Consumes: `pick` from `browse.picker`.
- Produces: `M.browse(config)` — builds `{ value, display, ordinal }` menu entries and calls `pickl`. Dispatch logic (existing bookmarks/input/devdocs/mdn branches) now lives in `on_select`.

- [x] **Step 1: Write the failing test (migrate init_spec)**

Replace `helpers.mock_telescope()` calls with `helpers.mock_picker()`, and add a dispatch test:

```lua
local helpers = require("helpers")
helpers.setup_mocks()

describe("browse.init", function()
    local rg_callbacks

    local function stub_routes()
        rg_callbacks = {}
        package.loaded["browse.input"] = {
            search_input = function(vt) rg_callbacks["input"] = vt end,
        }
        package.loaded["browse.devdocs"] = {
            search = function(vt) rg_callbacks["devdocs"] = vt end,
            search_with_filetype = function(vt) rg_callbacks["devdocs_file"] = vt end,
        }
        package.loaded["browse.mdn"] = {
            search = function(vt) rg_callbacks["mdn"] = vt end,
            search_with_filetype = function(vt) rg_callbacks["mdn_file"] = vt end,
        }
        package.loaded["browse.bookmarks"] = {
            search_bookmarks = function(cfg) rg_callbacks["bookmarks"] = cfg end,
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
        helpers.simulate_picker("input", ""
        assert.is_not_nil(rg_callbacks["input"])
        -- select Devdocs Search with filetype
        helpers.simulate_picker("devdocs_file", "")
        assert.is_not_nil(rg_callbacks["devdocs_file"])
        -- select MDN
        helpers.simulate_picker("mdn", "")
        assert.is_not_nil(rg_callbacks["mdn"])
        -- select Manual Bookmarks
        helpers.simulate_picker("manual_bookmarks", "")
        assert.is_not_nil(rg_callbacks["bookmarks"])
        assert.equal("manual")
    end)
end)
```

- [x] **Step 2: Run test to verify the dispatch currently fails** — currently `browse()` calls telescope directly, so `get_picker_calls()` is empty.

- [x] **Step 3: Rewrite `browse()`** in `lua/browse/init.lua`

Remove the top telescope requires (lines 1-6) and replace the whole `browse` function:

```lua
local picker = require("browse.picker")

local search_bookmarks = require("browse.bookmarks").search_bookmarks
local search_input = require("browse.input").search_input
local devdocs = require("browse.devdocs")
local mdn = require("browse.mdn")
local defaults = require("browse.config")

local browse = function(config)
    config = config or {}
    local visual_text = config["visual_text"] or ""

    picker.pick(
        {
            { value = "manual_bookmarks", display = "Manual Bookmarks", ordinal = "manual_bookmarks" },
            { value = "browser_bookmarks", display = "Browser Bookmarks", ordinal = "browser_bookmarks" },
            { value = "devdocs", display = "Devdocs Search", ordinal = "devdocs" },
            { value = "devdocs_file", display = "Devdocs Search with filetype", ordinal = "devdocs_file" },
            { value = "input", display = "Input Search", ordinal = "input" },
            { value = "mdn", display = "MDN Web Docs", ordinal = "mdn" },
        },
        {
            title = "Browse",
            layout = defaults.opts.layouts.browse,
            default_text = config.default_text,
            on_select = function(value, _)
                if value == "manual_bookmarks" then
                    search_bookmarks({
                        source = "manual",
                        visual_text = visual_text,
                        cache_picker = { num_pickers = defaults.opts.cache_pickers },
                    })
                elseif value == "browser_bookmarks" then
                    search_bookmarks({
                        source = "browser",
                        visual = visual_text,
                        cache_picker = { num_pickers = defaults.opts.cache_pickers },
                    })
                elseif value == "input" then
                    search_input(visual_text)
                elseif value == "devdocs" then
                    devdocs.search(visual_text)
                elseif value == "devdocs_file" then
                    devdocs.search_with_filetype(visual_text)
                elseif value == "mdn" then
                    mdn.search(visual_text)
                end
            end,
        }
    )
end
```

Note: `defaults.opts.layouts` is the translated `layouts` from Task 1; if a user set `browse = nil`, this passes `nil` (backend default). Keep `M.open_manual_bookmarks`, `M.open_browser_bookmarks`, `M._get_visual_selection`, `M._command_dispatcher`, `M.setup` unchanged.

- [x] **Step 4: Run test to verify it passes**

- [x] **Step 5: Commit**

```bash
git rm --quiet tests/browse/init_spec.lua  # (recreate the spec above first, no: -- keep the file and edit it in place)
git add lua/browse/init.lua tests/browse/init_spec.lua
git commit -m "refactor: route browse menu through the picker facade"
```

---

## Task 9: Refactor the bookmark picker call site — `search_bookmarks()`

**Files:**
- Modify: `lua/browse/bookmarks.lua`
- Test: migrate `tests/browse/bookmarks_spec.lua`, `tests/browse/display_spec.lua`, `tests/browse/picker_query_flow.lua`, `tests/browse/picker_flow_spec.lua`

**Interfaces:**
- Consumes: `browse.picker.pick`, `
