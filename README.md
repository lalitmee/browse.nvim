<div align="center">

# browse.nvim

##### browse for anything using your choice of method

![Neovim](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white)
[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)
[![License](https://img.shields.io/github/license/lalitmee/browse.nvim?color=%23FFC600&style=for-the-badge)](https://github.com/lalitmee/browse.nvim/blob/main/LICENSE)

![browse.nvim](https://user-images.githubusercontent.com/10762218/197941488-eed7780c-c7c0-47d8-9dcb-f1347944b61e.gif)

</div>

## Features

- cross platform
- reduces your search key strokes for any stackoverflow query
- [devdocs](https://devdocs.io) search
- [MDN](https://developer.mozilla.org/en-US/) search

## Requirements

- [neovim](https://github.com/neovim/neovim) (0.7.0+)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (if you
  want to browse bookmarks otherwise no need)
- [xdg-open](https://linux.die.net/man/1/xdg-open) (linux)
- [open](https://ss64.com/osx/open.html) (mac)
- [start](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/start) (windows)
- [dressing.nvim](https://github.com/stevearc/dressing.nvim) it will make the inputs and selects pretty (optional)

## Installation

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

## Usage

`browse.nvim` exposes the following for:

### Search

- `input_search()`, it will prompt you to search for something

```lua
require('browse').input_search()
```

- `open_bookmarks()`, search with the table `bookmarks`

```lua
require("browse").open_bookmarks({ bookmarks = bookmarks })
```

- `browse()`, it opens `telescope.nvim` dropdown theme to select the method

```lua
require("browse").browse({ bookmarks = bookmarks })
```

### devdocs

- `devdocs.search()`, search for anything in the [devdocs](https://devdocs.io/)

```lua
require('browse.devdocs').search()
```

- `devdocs.search_with_filetype()`, search for anything for the current file type

```lua
require('browse.devdocs').search_with_filetype()
```

### MDN

- `mdn.search()`, search for anything on [MDN](https://developer.mozilla.org/en-US/)

```lua
require('browse.mdn').search()
```

## bookmarks

For bookmarks you can declare your bookmarks in lua table format. for example:

```lua
local bookmarks = {
  "https://github.com/hoob3rt/lualine.nvim",
  "https://github.com/neovim/neovim",
  "https://neovim.discourse.group/",
  "https://github.com/nvim-telescope/telescope.nvim",
  "https://github.com/rockerBOO/awesome-neovim",
}
```

Bookmarks can be given aliases like so:

```lua
local aliases = {
  ["neovim/neovim"] = "https://github.com/neovim/neovim",
}
```
The bookmark can then be inputted as `neovim/neovim`.

and then pass this table into the `browse()` function like this

```lua
vim.keymap.set("n", "<leader>b", function()
  require("browse").browse({ bookmarks = bookmarks, aliases = aliases})
end)
```

> If this `bookmarks` table will be empty or will not be passed and if you select `Bookmarks`
> from `telescope` result, you will not see anything in the telescope results.

## Customizations

You can customize the `input_search()` to use the `provider` you like. Possible values for the provider are following:

- `google`
- `duckduckgo`
- `brave`
- `bing`

```lua
require('browse').setup({
  -- search provider you want to use
  provider = "google", -- default
})
```

## Advanced usage

Create commands for all the functions which `browse.nvim` exposes and then simply run whatever you want from the
command line

```lua
local browse = require('browse')

function command(name, rhs, opts)
  opts = opts or {}
  vim.api.nvim_create_user_command(name, rhs, opts)
end

command("BrowseInputSearch", function()
  browse.input_search()
end, {})

command("Browse", function()
  browse.browse({ bookmarks = bookmarks })
end, {})

command("BrowseBookmarks", function()
  browse.open_bookmarks({ bookmarks = bookmarks })
end, {})

command("BrowseDevdocsSearch", function()
  browse.devdocs.search()
end, {})

command("BrowseDevdocsFiletypeSearch", function()
  browse.devdocs.search_with_filetype()
end, {})

command("BrowseMdnSearch", function()
  browse.mdn.search()
end, {})
```

## Acknowledgements and Credits

- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [open-browser.nvim](https://github.com/tyru/open-browser.vim)

## Donate

[![](https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/ilalitmee)

Buy me a coffee through [paypal](https://paypal.me/ilalitmee).
