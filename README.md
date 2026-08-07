<div align="center">

# browse.nvim

##### browse for anything using your choice of method

[![GitHub Repo stars](https://img.shields.io/github/stars/lalitmee/browse.nvim?style=for-the-badge)](https://github.com/lalitmee/browse.nvim/stargazers)
[![Tests](https://img.shields.io/github/actions/workflow/status/lalitmee/browse.nvim/ci.yml?label=Tests&style=for-the-badge)](https://github.com/lalitmee/browse.nvim/actions/workflows/ci.yml)
[![License](https://img.shields.io/github/license/lalitmee/browse.nvim?color=%23FFC600&style=for-the-badge)](https://github.com/lalitmee/browse.nvim/blob/main/LICENSE)

<video src="https://github.com/user-attachments/assets/2e0395f6-90e5-4698-aa76-0420033f4b5d" controls></video>

</div>

`browse.nvim` is a plugin that provides a unified interface for browsing and
searching web resources directly from within Neovim. It uses a pluggable picker
backend (telescope.nvim by default, with opt-in support for fzf-lua, mini.pick,
and snacks.picker) to offer a powerful picker for accessing your bookmarks,
searching with different providers (like Google, DuckDuckGo), and querying
documentation sites like DevDocs and MDN.

## Showcase

<details>
<summary>🎥 Click here to see features in action!</summary>

### Unified Command System
<video src="https://github.com/user-attachments/assets/44112cd1-6209-4282-9d50-7aa1dba81d0f" controls></video>

### Unified Bookmark Search
<video src="https://github.com/user-attachments/assets/cb071e3a-7133-4328-beca-47c649352772" controls></video>

### Filetype Docs Search
<video src="https://github.com/user-attachments/assets/1720126e-c460-4917-82f8-89988e0fccf6" controls></video>

### Visual Mode Search
<video src="https://github.com/user-attachments/assets/6693ff2c-374c-47df-81db-03f452d37b9f" controls></video>

</details>

## Features

- Cross-platform support.
- Reduces keystrokes for search queries.
- Multi-picker backend support: telescope.nvim (default), fzf-lua, mini.pick, or snacks.picker.
- [DevDocs](https://devdocs.io) integration.
- [MDN](https://developer.mozilla.org/en-US/) Web Docs integration.
- Powerful and flexible bookmarking system, with support for multiple files (JSON, YAML, TOML, TXT) and browser bookmark importing.

## Requirements

- [neovim](https://github.com/neovim/neovim) (0.7.0+)
- A picker backend — [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) by default, or one of the alternatives listed in [Picker backends](#picker-backends).
- A command-line opener:
  - **Linux**: [xdg-open](https://linux.die.net/man/1/xdg-open)
  - **WSL**: [wsl-open](https://github.com/4U6U57/wsl-open)
  - **macOS**: `open`
  - **Windows**: `start`
- [dressing.nvim](https://github.com/stevearc/dressing.nvim) (optional, for a better UI).

## Installation

- Using [lazy.nvim](https://github.com/folke/lazy.nvim)

  ```lua
  {
      "lalitmee/browse.nvim",
      -- telescope.nvim is the default picker backend, but you can swap it for
      -- any backend listed under `Picker Backends`.
      dependencies = { "nvim-telescope/telescope.nvim" },
      opts = {
          -- add your options here, or leave empty to use defaults
      },
  }
  ```

To use a different picker backend, add it as a dependency and set `picker` in your opts:

  ```lua
  {
      "lalitmee/browse.nvim",
      dependencies = { "ibhagwan/fzf-lua" }, -- fzf-lua, mini.pick, or snacks.nvim
      opts = {
          picker = "fzf_lua", -- telescope (default), fzf_lua, mini_pick, snacks
      },
}
  ```

## Configuration

Here is the default configuration:
```lua
require('browse').setup({
    -- The default search provider for `input_search()`.
    -- Values: "google", "duckduckgo", "bing", "brave".
    provider = "google",

    -- A Lua table containing your bookmarks.
    bookmarks = {},

    -- A list of absolute paths to external bookmark files.
    bookmark_files = {},

    -- Configuration for importing bookmarks from web browsers.
    browser_bookmarks = {
        enabled = false,
        browsers = {
            chrome = false,
            firefox = false,
            safari = false,
            edge = false,
        },
        group_by_folder = true,
        auto_detect = true,
    },

    -- If `true`, duplicate bookmark URLs from all sources will be removed.
    deduplicate_bookmarks = true,

    -- If `true`, bookmarks loaded from files and browsers will be cached to improve performance.
    cache_bookmarks = true,

    -- The duration in seconds for which the bookmark cache is valid.
    cache_duration = 60,

    -- If `true`, the plugin will create default user commands for you.
    create_commands = true,

    -- The picker backend used for the browse menu and bookmark picker.
    -- Values: "telescope" (default), "fzf_lua", "mini_pick", "snacks".
    picker = "telescope",

    -- Per-backend passthrough opts, e.g. { fzf_lua = { winopts = {...} } }.
    picker_opts = {},

    -- A table to configure the layout for each picker.
    -- Valid layouts depend on the backend (see "Picker Backends").
    layouts = {
        browse = "dropdown",
        manual_bookmarks = "dropdown",
        browser_bookmarks = nil, -- nil uses the backend default layout
    },
    -- DEPRECATED: use `layouts` instead. If `layouts` is also set, `layouts` wins.
    -- Setting only `themes` triggers a one-time deprecation warning at setup.
    themes = nil,

    -- Configuration for parsing plain text (`.txt`) bookmark files.
    plain_text = {
        delimiters = { ":", "=" },
        comment_chars = { "#", ";" },
    },

    -- Customize the icons used in the pickers.
    icons = {
        bookmark_alias = "->",
        bookmarks_prompt = "",
        grouped_bookmarks = "->",
        file_bookmark = "📄",
        browser_bookmark = "🌐",
    },

    -- If `true`, the search query is preserved when you navigate into a nested bookmark group.
    persist_grouped_bookmarks_query = false,

    -- Configuration for the bookmark picker.
    bookmark_picker = {
        -- If `true`, nested bookmarks are displayed in a nested structure.
        -- If `false`, all bookmarks are shown in a flat list.
        show_nested = true,
    },

    -- The number of pickers to cache, enabling back-navigation in nested bookmark groups.
    cache_pickers = 10,

    -- If `true`, bookmark results are sorted alphabetically.
    -- If `false`, they are displayed in the order they were defined.
    sort_results = true,
})
```

## Picker Backends

The `:Browse` menu, the bookmark picker, and nested-group navigation all run through a
single facade that abstracts over the picker widget. You get the same behavior and
configuration on every backend.

| Backend | `picker` value | Extra requirement | Supported layouts |
| --- | --- | --- | --- |
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | `telescope` | nothing | `default`, `dropdown`, `cursor`, `ivy` |
| [fzf-lua](https://github.com/ibhagwan/fzf-lua) | `fzf_lua` | the `fzf` or `sk` binary on `PATH` | `default`, `dropdown`, `cursor`, `ivy` |
| [mini.pick](https://github.com/echasnovski/mini.pick) | `mini_pick` | nothing | `default`, `dropdown`, `cursor`, `ivy` |
| [snacks.nvim](https://github.com/folke/snacks.nvim) | `snacks` | nothing | `default`, `dropdown`, `cursor`, `ivy`, `top`, `vertical` |

### Fallback behavior

- If the configured backend is not installed, or fails the extra requirement (e.g. the
  `fzf` binary is missing), the plugin warns once and falls back to telescope.nvim.
- If the selected backend errors at runtime, the plugin reports the error and opens
  telescope.nvim instead.

So a broken or missing backend never leaves you staring at an empty buffer.

### Per-backend options: `picker_opts`

`picker_opts` is a passthrough table of options forwarded to each backend. Options given
at the call site (e.g. the `opts` passed to `browse()`) take precedence over these.

Backend specifics:

- **telescope**: options are merged into the telescope picker configuration.
- **fzf-lua**: accepts `winopts` (and any option `fzf_exec` understands), e.g.
  `{ winopts = { preview = true } }`.
- **mini.pick**: accepts `window`, e.g. `{ window = { border = "single" } }`.
- **snacks**: options are merged into the `snacks.picker.pick` spec.

```lua
require('browse').setup({
    picker = "fzf_lua",
    picker_opts = {
        fzf_lua = {
            winopts = { preview = true },
        },
    },
})
```

### Layouts and the deprecated `themes`

Layouts control where and how each picker appears, and are backend-independent. Setting
`layouts = { browse = "ivy", manual_bookmarks = "ivy" }` gives you an ivy-ish layout on
every backend that supports it (see the table above for which layouts each backend
accepts; the backend falls back to its default for all unsupported names).

```lua
require('browse').setup({
    layouts = {
        browse = "dropdown",
        manual_bookmarks = "dropdown",
        browser_bookmarks = nil, -- nil = backend default layout
    },
})
```

**`themes` is deprecated.** Migrate by renaming `themes` to `layouts` — the keys and
values are identical. While `themes` still works as a fallback (and is translated for
you), setting only `themes` triggers a one-time deprecation warning at setup, and if
both are present, `layouts` wins.

```diff
 require('browse').setup({
-    themes = { browse = "dropdown", manual_bookmarks = "dropdown" },
+    layouts = { browse = "dropdown", manual_bookmarks = "dropdown" },
 })
```

## Usage

The main entry point is the `require('browse').browse()` Lua function. This opens the configured picker with the following options:

- **Manual Bookmarks**: Search through your bookmarks from your config and files.
- **Browser Bookmarks**: Search through bookmarks imported from your web browsers.
- **Devdocs Search**: Search for queries on devdocs.io.
- **Devdocs Search with filetype**: Search DevDocs, automatically using the current buffer's filetype as a filter.
- **Input Search**: Enter a query to search with your default search provider.
- **MDN Web Docs**: Search for queries on the MDN Web Docs.

Text selected in visual mode will be used as the initial query for searches.

### Commands

If `create_commands = true` (the default), the plugin will create the `:Browse` command.

```vim
:Browse <subcommand>
```

If no subcommand is provided, the main selection menu will open. All subcommands support visual mode selection to pre-fill the search query.

| Subcommand | Action |
| --- | --- |
| `input` | Opens the input search to query with your default provider. |
| `mdn` | Searches the MDN Web Docs. |
| `mdn_ft` | Searches MDN, including the current buffer's filetype. |
| `devdocs` | Searches devdocs.io. |
| `devdocs_ft` | Searches DevDocs, including the current buffer's filetype. |
| `bookmarks` | Opens a picker to select a bookmark source. |
| `bookmarks_manual` | Opens your manual bookmarks directly. |
| `bookmarks_browser` | Opens your browser bookmarks directly. |

### API

All public functions are available under the `require('browse')` module.

- `browse.setup({opts})`: Configures the plugin. See [Configuration](#configuration).

- `browse.browse({opts})`: Opens the main picker to select a search type.

- `browse.open_manual_bookmarks({opts})`: Opens the picker directly to your manual bookmarks (from config and files).

- `browse.open_browser_bookmarks({opts})`: Opens the picker directly to your browser bookmarks.

- `browse.input_search()`: Prompts for input and searches using the configured `provider`.

- `browse.devdocs.search()`: Prompts for input and searches on devdocs.io.

- `browse.devdocs.search_with_filetype()`: Prompts for input and searches on devdocs.io, using the current buffer's filetype to narrow the search.

- `browse.mdn.search()`: Prompts for input and searches on MDN Web Docs.

## Bookmarks

`browse.nvim` can aggregate bookmarks from three sources: a Lua table, external files, and your web browser's bookmarks.

### Lua Table

You can define bookmarks directly in your `setup()` call or pass them to the `browse()` or `open_bookmarks()` functions. The table can have several formats:

1.  **Simple list of URLs**:
    ```lua
    bookmarks = {
        "https://neovim.io",
        "https://github.com/nvim-telescope/telescope.nvim",
    }
    ```

2.  **Aliases for URLs** (name = URL):
    ```lua
    bookmarks = {
        neovim = "https://neovim.io",
        telescope = "https://github.com/nvim-telescope/telescope.nvim",
    }
    ```
    If the URL contains `%s`, it will be treated as a search query, and you will be prompted for input.
    ```lua
    bookmarks = {
        gh_search = "https://github.com/search?q=%s",
    }
    ```

3.  **Grouped bookmarks**:
    You can create nested tables to group related bookmarks.
    ```lua
    bookmarks = {
        neovim = {
            name = "Neovim Resources", -- Optional display name for the group
            website = "https://neovim.io",
            discourse = "https://neovim.discourse.group/",
        },
    }
    ```

### External Files

Use the `bookmark_files` option to specify a list of files to load bookmarks from. The following formats are supported:

- `json`: Standard JSON format.
- `yaml`: YAML format.
- `toml`: TOML format.
- `txt`: A plain text file where each line is a bookmark. The format can be `name: url` or just `url`. Use the `plain_text` config table to customize delimiters and comments.

### Browser Bookmarks

Set `browser_bookmarks.enabled = true` to import bookmarks from your installed web browsers.

- `enabled` (boolean): Master switch to enable/disable this feature.
- `browsers` (table): A table of booleans to control which browsers to import from (e.g., `{ chrome = true, firefox = false }`).
- `auto_detect` (boolean): If `true`, the plugin will try to find installed browsers and enable them automatically if they are not explicitly set in the `browsers` table.
- `group_by_folder` (boolean): If `true`, bookmarks will be nested in the picker according to the folder structure in your browser.

## Acknowledgements and Credits

- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [open-browser.nvim](https://github.com/tyru/open-browser.vim)

## Support

<a href="https://www.buymeacoffee.com/iamlalitmee" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>
