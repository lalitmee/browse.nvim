<div align="center">

# browse.nvim

##### browse for anything using your choice of method

![Neovim](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white)
[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)
[![GitHub Repo stars](https://img.shields.io/github/stars/lalitmee/browse.nvim?style=for-the-badge)](https://github.com/lalitmee/browse.nvim/stargazers)
[![CI](https://img.shields.io/github/actions/workflow_status/lalitmee/browse.nvim/ci.yml?style=for-the-badge)](https://github.com/lalitmee/browse.nvim/actions/workflows/ci.yml)
[![License](https://img.shields.io/github/license/lalitmee/browse.nvim?color=%23FFC600&style=for-the-badge)](https://github.com/lalitmee/browse.nvim/blob/main/LICENSE)

![browse.nvim](https://user-images.githubusercontent.com/10762218/217238018-29564296-063a-43cb-a3c1-28703db9c31c.gif)

</div>

`browse.nvim` is a plugin that provides a unified interface for browsing and
searching web resources directly from within Neovim. It uses `telescope.nvim`
to offer a powerful picker for accessing your bookmarks, searching with
different providers (like Google, DuckDuckGo), and querying documentation
sites like DevDocs and MDN.

## Features

- Cross-platform support.
- Reduces keystrokes for search queries.
- [DevDocs](https://devdocs.io) integration.
- [MDN](https://developer.mozilla.org/en-US/) Web Docs integration.
- Powerful and flexible bookmarking system, with support for multiple files (JSON, YAML, TOML, TXT) and browser bookmark importing.

## Requirements

- [neovim](https://github.com/neovim/neovim) (0.7.0+)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- A command-line opener:
  - **Linux**: [xdg-open](https://linux.die.net/man/1/xdg-open)
  - **WSL**: [wsl-open](https://github.com/4U6U57/wsl-open)
  - **macOS**: `open`
  - **Windows**: `start`
- [dressing.nvim](https://github.com/stevearc/dressing.nvim) (optional, for a better UI).

## Installation

- [lazy.nvim](https://github.com/folke/lazy.nvim)

  ```lua
  {
      "lalitmee/browse.nvim",
      dependencies = { "nvim-telescope/telescope.nvim" },
  }
  ```

- [packer.nvim](https://github.com/wbthomason/packer.nvim)

  ```lua
  use({
      "lalitmee/browse.nvim",
      requires = { "nvim-telescope/telescope.nvim" },
  })
  ```

- [vim-plug](https://github.com/junegunn/vim-plug)

  ```vim
  Plug 'nvim-telescope/telescope.nvim'
  Plug 'lalitmee/browse.nvim'
  ```

## Configuration

Call the `setup` function to configure the plugin.

Here is the default configuration:
```lua
require('browse').setup({
    provider = "google",
    bookmarks = {},
    bookmark_files = {},
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
    deduplicate_bookmarks = true,
    cache_bookmarks = true,
    cache_duration = 60,
    plain_text = {
        delimiters = { ":", "=" },
        comment_chars = { "#", ";" },
    },
    icons = {
        bookmark_alias = "->",
        bookmarks_prompt = "",
        grouped_bookmarks = "->",
        file_bookmark = "📄",
        browser_bookmark = "🌐",
    },
    persist_grouped_bookmarks_query = false,
    cache_pickers = 10,
    sort_results = true,
})
```

### Options

- `provider` (string): The default search provider for `input_search()`.
  - **Default**: `"google"`
  - **Values**: `"google"`, `"duckduckgo"`, `"bing"`, `"brave"`.

- `bookmarks` (table): A Lua table containing your bookmarks. See [Bookmarks](#bookmarks) for the detailed structure.
  - **Default**: `{}`

- `bookmark_files` (table): A list of absolute paths to external bookmark files.
  - **Default**: `{}`

- `browser_bookmarks` (table): Configuration for importing bookmarks from web browsers.
  - **Default**: `{ enabled = false, ... }`

- `deduplicate_bookmarks` (boolean): If `true`, duplicate bookmark URLs from all sources will be removed.
  - **Default**: `true`

- `cache_bookmarks` (boolean): If `true`, bookmarks loaded from files and browsers will be cached to improve performance.
  - **Default**: `true`

- `cache_duration` (number): The duration in seconds for which the bookmark cache is valid.
  - **Default**: `60`

- `plain_text` (table): Configuration for parsing plain text (`.txt`) bookmark files.
  - `delimiters` (table): Characters used to separate a bookmark's name from its URL.
  - `comment_chars` (table): Characters that signify the start of a comment line.
  - **Default**: `{ delimiters = {":", "="}, comment_chars = {"#", ";"} }`

- `icons` (table): Customize the icons used in the Telescope pickers.
  - **Default**: `{ bookmark_alias = "->", ... }`

- `persist_grouped_bookmarks_query` (boolean): If `true`, the search query is preserved when you navigate into a nested bookmark group.
  - **Default**: `false`

- `cache_pickers` (number): The number of Telescope pickers to cache, enabling back-navigation.
  - **Default**: `10`

- `sort_results` (boolean): If `true`, bookmark results are sorted alphabetically. If `false`, they are displayed in the order they were defined.
  - **Default**: `true`

## Usage

The main entry point is the `require('browse').browse()` Lua function. This opens a Telescope window with the following options:

- **Bookmarks Search**: Search through your configured bookmarks.
- **Devdocs Search**: Search for queries on devdocs.io.
- **Devdocs Search with filetype**: Search DevDocs, automatically using the current buffer's filetype as a filter.
- **Input Search**: Enter a query to search with your default search provider.
- **MDN Web Docs**: Search for queries on the MDN Web Docs.

Text selected in visual mode will be used as the initial query for searches.

### API

All public functions are available under the `require('browse')` module.

- `browse.setup({opts})`: Configures the plugin. See [Configuration](#configuration).

- `browse.browse({opts})`: Opens the main Telescope picker to select a search type. You can optionally pass a `bookmarks` table to this function to provide temporary bookmarks for this session only.

- `browse.open_bookmarks({opts})`: Opens the Telescope picker directly to your bookmarks. You can optionally pass a `bookmarks` table here as well.

- `browse.input_search()`: Prompts for input and searches using the configured `provider`.

- `browse.devdocs.search()`: Prompts for input and searches on devdocs.io.

- `browse.devdocs.search_with_filetype()`: Prompts for input and searches on devdocs.io, using the current buffer's filetype to narrow the search.

- `browse.mdn.search()`: Prompts for input and searches on MDN Web Docs.

### Commands

The plugin does not create any commands by default. You can create them yourself for easier access.

**Example:**
```lua
vim.api.nvim_create_user_command("Browse", function()
    require("browse").browse()
end, {})

vim.api.nvim_create_user_command("BrowseBookmarks", function()
    require("browse").open_bookmarks()
end, {})

vim.api.nvim_create_user_command("BrowseSearch", function()
    require("browse").input_search()
end, {})

vim.api.nvim_create_user_command("DevdocsSearch", function()
    require("browse.devdocs").search()
end, {})

vim.api.nvim_create_user_command("MdnSearch", function()
    require("browse.mdn").search()
end, {})
```

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