<div align="center">

# browse.nvim

##### browse for anything using your choice of method

![Neovim](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white)
[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)
[![License](https://img.shields.io/github/license/lalitmee/browse.nvim?color=%23FFC600&style=for-the-badge)](https://github.com/lalitmee/browse.nvim/blob/main/LICENSE)

![browse.nvim](./media/browse.gif)

</div>

## Requirements

- [neovim](https://github.com/neovim/neovim) (nightly)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

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

browse.nvim provides a function `browse()`

### bookmarks

For bookmars you can declare you bookmarks in table format. for example:

```lua
local bookmarks = {
  "https://github.com/hoob3rt/lualine.nvim",
  "https://github.com/neovim/neovim",
  "https://neovim.discourse.group/",
  "https://github.com/nvim-telescope/telescope.nvim",
  "https://github.com/rockerBOO/awesome-neovim",
}
```

and then pass this table into the `browse()` function like this

```lua
vim.keymap.set("n", "<leader>b", function()
  require("browse").browse({ bookmarks = bookmarks })
end)
```

> If this `bookmarks` table will be empty or will not be passed and if you select `Bookmarks`
> from `telescope` result, you will not see anything in the telescope results.

## Roadmap

I know there are many things which can be done with this but for now I wanted
this simple functionality. If you are interested in enhancing this, Pull Requests
are welcomed.

## Acknowledgements

- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
