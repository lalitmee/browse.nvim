<div align="center">

# browse.nvim

##### browse for anything using your choice of method

![Neovim](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white)
[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)
[![License](https://img.shields.io/github/license/lalitmee/browse.nvim?color=%23FFC600&style=for-the-badge)](https://github.com/lalitmee/browse.nvim/blob/main/LICENSE)

![browse.nvim](https://user-images.githubusercontent.com/10762218/217238018-29564296-063a-43cb-a3c1-28703db9c31c.gif)

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

## Setup

```lua
-- default values for the setup
require('browse').setup({
  -- search provider you want to use
  provider = "google", -- duckduckgo, bing

  -- either pass it here or just pass the table to the functions
  -- see below for more
  bookmarks = {}
})
```

## Usage

There are so many ways in which you can use this to improve your search experience. After `bookmarks` table support for multiple formats and organized structure of the bookmarks, you can just use `open_bookmarks()` api.

### bookmarks

For bookmarks you can declare your bookmarks in lua table format. `bookmarks`
table can contain multiple structures.

1. grouped urls with a name key in the table (recommended)

   ```lua
   local bookmarks = {
     ["github"] = {
         ["name"] = "search github from neovim",
         ["code_search"] = "https://github.com/search?q=%s&type=code",
         ["repo_search"] = "https://github.com/search?q=%s&type=repositories",
         ["issues_search"] = "https://github.com/search?q=%s&type=issues",
         ["pulls_search"] = "https://github.com/search?q=%s&type=pullrequests",
     },
   }
   ```

2. urls with aliases

   ```lua
   local bookmarks = {
     ["github_code_search"] = "https://github.com/search?q=%s&type=code",
     ["github_repo_search"] = "https://github.com/search?q=%s&type=repositories",
   }
   ```

3. urls with a query parameter

   ```lua
   local bookmarks = {
     "https://github.com/search?q=%s&type=code",
     "https://github.com/search?q=%s&type=repositories",
   }
   ```

4. simple and direct urls

   ```lua
   local bookmarks = {
        "https://github.com/hoob3rt/lualine.nvim",
        "https://github.com/neovim/neovim",
        "https://neovim.discourse.group/",
        "https://github.com/nvim-telescope/telescope.nvim",
        "https://github.com/rockerBOO/awesome-neovim",
    }
   ```

5. you can also combine all of the above in a table if you want.

and then pass this table into the `browse()` function like this

```lua
vim.keymap.set("n", "<leader>b", function()
  require("browse").browse({ bookmarks = bookmarks })
end)
```

> If this `bookmarks` table will be empty or will not be passed and if you select `Bookmarks`
> from `telescope` result, you will not see anything in the telescope results.

### search

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

### mdn

- `mdn.search()`, search for anything on [MDN](https://developer.mozilla.org/en-US/)

```lua
require('browse.mdn').search()
```

## Customizations

You can customize the `input_search()` to use the `provider` you like. Possible values for the provider are following:

- `google`
- `duckduckgo`
- `brave`
- `bing`

## Advanced usage

Create commands for all the functions which `browse.nvim` exposes and then simply run whatever you want from the
command line

```lua
local browse = require('browse')

function command(name, rhs, opts)
  opts = opts or {}
  vim.api.nvim_create_user_command(name, rhs, opts)
end

command("InputSearch", function()
  browse.input_search()
end, {})

-- this will open telescope using dropdown theme with all the available options
-- in which `browse.nvim` can be used
command("Browse", function()
  browse.browse({ bookmarks = bookmarks })
end)

command("Bookmarks", function()
  browse.open_bookmarks({ bookmarks = bookmarks })
end)

command("DevdocsSearch", function()
  browse.devdocs.search()
end)

command("DevdocsFiletypeSearch", function()
  browse.devdocs.search_with_filetype()
end)

command("MdnSearch", function()
  browse.mdn.search()
end)
```

## Acknowledgements and Credits

- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [open-browser.nvim](https://github.com/tyru/open-browser.vim)

## Support

<a href="https://www.buymeacoffee.com/iamlalitmee" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>
