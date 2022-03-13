# browse.nvim

browse for anything using your choice of method

## Requirements

- neovim-0.7 (nightly)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

## Installation

- [packer.nvim](https://github.com/wbthomason/packer.nvim)

  ```lua
  use { 'lalitmee/browse.nvim', requires = {'nvim-telescope/telescope.nvim'} }
  ```

- [vim-plug](https://github.com/junegunn/vim-plug)

  ```vim
  Plug 'nvim-telescope/telescope.nvim'
  Plug 'lalitmee/browse.nvim'
  ```

## Usage

browse.nvim provides a function `browse()`

```lua
vim.keymap.set("n", "<leader>b", '<cmd>lua require("browse").browse()<cr>')
```
