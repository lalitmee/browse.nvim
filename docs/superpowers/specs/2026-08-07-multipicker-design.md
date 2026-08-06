# Multi-Picker Backend Support for browse.nvim

**Date:** 2026-08-07
**Status:** Approved design

## Summary

Make browse.nvim's two picker surfaces (the main `:Browse` menu and the bookmark
picker) backend-agnostic. Users choose a picker backend via config — telescope
(default), fzf-lua, mini.pick, or snacks.picker — with graceful fallback to
telescope when the chosen backend is unavailable. Behavior with the default
configuration stays identical to the current version.

## Motivation

browse.nvim currently hardcodes `telescope.nvim`. The community has several
popular pickers (fzf-lua, mini.pick, snacks.picker, telescope.nvim); users
should be able to use whichever they already have installed.

## Scope

In scope:

- Two picker call sites: `lua/browse/init.lua` (the `browse()` main menu) and
  `lua/browse/bookmarks.lua` (`search_bookmarks`, the nested bookmark picker).
- New config keys and the deprecation of the `themes` key.
- The four backend adapters and their unit tests.

Out of scope:

- `vim.ui.input`-based text prompts (`input.lua`, `mdn.lua`, `devdocs.lua`).
- Bookmark parsing, browser import, bookmark_manager.
- Any new picker backends beyond the four listed.

## Current Architecture

- `lua/browse/init.lua` and `lua/browse/bookmarks.lua` call Telescope APIs
  directly (`telescope.pickers`, `telescope.finders`, `telescope.config.values`,
  `telescope.themes`, `telescope.actions`, `telescope.actions.state`,
  `telescope.builtin.resume`).
- `lua/browse/utils.lua` exposes `get_theme(name)` which calls
  `telescope.themes`.
- `lua/browse/config.lua` defines `themes = { browse = "dropdown",
  manual_bookmarks = "dropdown", browser_bookmarks = nil }`.
- Tests mock telescope via `tests/helpers.lua` `mock_telescope()`.

## Approach

Thin internal picker interface ("facade") plus one adapter module per backend,
chosen by a resolver at call time.

### Facade API

```lua
require("browse.picker").pick(entries, {
    title        = "Bookmarks",             -- window/prompt title (optional)
    layout       = "dropdown",              -- generic layout name (optional)
    default_text = "query",                 -- prefill (optional)
    on_select    = function(value, query) end,  -- required
    on_cancel    = function() end,          -- optional
})
-- entries: array of { value = any, display = string, ordinal = string }
```

The facade signature never changes with the backend. Backends that cannot
express prefill or query text degrade internally; call sites are unaffected.

### Backend selection

1. Read `config.opts.picker` (default `"telescope"`).
2. Check `available()` on the adapter. If unavailable, emit one `vim.notify`
   (WARN) and fall back to `telescope` for the session (tracked in a
   module-level set so the notice fires once per backend).
3. Merge `config.opts.picker_opts[backend]` into the opts table.
4. Call the adapter inside a `pcall`. On runtime failure, notify and fall back
   to telescope for that single invocation.

## Config

New keys in `lua/browse/config.lua`:

```lua
picker = "telescope",   -- "telescope" | "fzf_lua" | "mini_pick" | "snacks"
picker_opts = {},       -- per-backend passthrough, e.g. { fzf_lua = { winopts = {...} } }
layouts = {             -- replaces `themes`
    browse = "dropdown",
    manual_bookmarks = "dropdown",
    browser_bookmarks = nil,  -- backend default
},
```

### Layout names

Generic names shared across backends: `dropdown`, `cursor`, `ivy`, `top`,
`vertical`, `default`.

Each adapter maps the generic name to its own styling:

| Layout | telescope | fzf-lua | mini.pick | snacks |
| --- | --- | --- | --- | --- |
| dropdown | `themes.get_dropdown` | centered bordered float | centered bordered window | `layout = "select"` |
| cursor | `themes.get_cursor` | cursor-positioned float | cursor-positioned window | `layout = "select"` |
| ivy | `themes.get_ivy` | bottom full-width | bottom full-width | `layout = "ivy"` |
| top | — | — | — | `layout = "top"` |
| vertical | — | — | — | `layout = "vertical"` |
| default | telescope default | fzf-lua default | mini.pick default | snacks default |

Unknown layout name → one-time notice + backend default.

### Legacy `themes` key

If `layouts` is unset and `themes` is set, read `themes`, emit a one-time
deprecation notice (WARN), and feed the values through the same generic-name
mapping. `layouts` always wins when both are set.

## Component Details

### `lua/browse/picker/telescope.lua`

- `available()`: `pcall(require)` the telescope modules.
- `pick()`: current behavior — `pickers.new` + `finders.new_table` +
  `entry_maker` producing `{ value, display, ordinal }`, `conf.generic_sorter`
  honoring `sort_results`, `attach_mappings` replacing `select_default`, and
  `actions.close`. Layout name -> `themes.get_<name>`. `default_text` prefill.
- Absorbs the current `utils.get_theme` logic.

### `lua/browse/picker/fzf_lua.lua`

- `available()`: fixture `require("fzf-lua")` succeeds **and**
  `vim.fn.executable("fzf") == 1 or vim.fn.executable("sk") == 1`.
- Entries encoded as `ordinal .. "\t" .. display`; `fzf_opts` set
  `--delimiter "\t"`, `--nth 1`, `--with-nth 2`.
- `actions = { ["default"] = on_select(selected[1] -> value, opts.last_query) }`.
  `esc`/`ctrl-c` handlers wired only when `on_cancel` is provided.
- Query text from `opts.last_query`. Prefill via `opts.query`.
- Value lookup: keep a line -> value map from the entries.

### `lua/browse/picker/mini_pick.lua`

- `available()`: `_G.MiniPick ~= nil` (mini.pick requires `setup()`).
- `source.items = entries` as `{ text = display, value = value }`.
- `source.choose(item)`: call `on_select(item.value, query)`; return `nil` to
  close the picker.
- Query text from `MiniPick.get_picker_query()`; prefill via
  `vim.schedule(function() MiniPick.set_picker_query(split(default_text)) end)`
  before `MiniPick.start`.
- Layout name -> `window.config` presets. Ignore `jump` on selection.

### `lua/browse/picker/snacks.lua`

- `available()`: `pcall(require("snacks"))`.
- `Snacks.picker.pick({ items, format = "text", title, layout/prefs })` with
  `confirm = function(picker, item) picker:close(); on_select(item.value,
  picker.input:get()) end`.
- Prefill via `pattern`. Layout name -> `layout` preset.
- `on_cancel` wired via `on_close` when provided.

## Error Handling

- Per-backend `available()` as above.
- Unavailable configured backend: one-time WARN + telescope fallback.
- Runtime adapter failure: notify + telescope for that invocation.
- Esc/`<C-c>`: backend default close; `on_cancel` wired only if provided.

## Testing

- `tests/helpers.lua`: replace `mock_telescope` with `mock_picker` that stubs
  `require("browse.picker")`, recording `entries`/`opts` and invoking
  `on_select`/`on_cancel`. Migrate existing specs (`init_spec.lua`,
  `picker_flow_spec.lua`, `bookmarks_spec.lua`, `display_spec.lua`,
  `picker_query_flow.lua`, `utils_spec.lua`).
- Adapter unit tests with fake backend modules (fake telescope pick-select
  modules, fake fzf-lua, fake `_G.MiniPick`, fake `snacks.picker`) asserting
  entry/opts/callback translation.
- Resolver tests: picker string, `picker_opts` merge, fallback on unavailable
  backend, layout mapping, legacy `themes` deprecation behavior.

## Documentation

- Update `README.md` configuration section: `picker`, `picker_opts`,
  `layouts`; note `themes` deprecation.
- Update `doc/browse-nvim.txt` and `FEATURES.md`'s dependency/UI notes.
- Note the new optional dependency for each backend (fzf-lua needs the `fzf`
  binary; mini.pick and snacks are pure Lua; telescope remains default).

## Non-Goals / Deferred

- `vim.ui.input`-based prompts remain unchanged.
- No per-picker backend mixing (single global `picker`; per-picker layouts only).
- No new backends beyond the four.