# GEMINI.MD: AI Collaboration Guide

This document provides essential context for AI models interacting with this project. Adhering to these guidelines will ensure consistency and maintain code quality.

## 1. Project Overview & Purpose

* **Primary Goal:** `browse.nvim` is a Neovim plugin designed to provide a unified interface for browsing and searching web resources directly from the editor. It leverages `telescope.nvim` to offer a dropdown picker for accessing bookmarks, search providers, and documentation sites like DevDocs and MDN.
* **Business Domain:** Developer Tooling / Neovim Ecosystem.

## 2. Core Technologies & Stack

* **Languages:** Lua
* **Frameworks & Runtimes:** Neovim (0.7.0+)
* **Databases:** None.
* **Key Libraries/Dependencies:** 
    - `nvim-telescope/telescope.nvim`: Core dependency for the UI.
    - `plenary.nvim`: Used for testing.
* **Package Manager(s):** Not explicitly defined, but supports standard Neovim plugin managers like `lazy.nvim`, `packer.nvim`, and `vim-plug`.

## 3. Architectural Patterns

* **Overall Architecture:** The plugin is a modular Neovim plugin built around `telescope.nvim`. It follows a single-responsibility principle for its modules.
* **Directory Structure Philosophy:** 
    * `/lua/browse/`: Contains all the core source code.
        * `init.lua`: The main entry point that sets up the Telescope picker.
        * `config.lua`: Manages user configuration and defaults.
        * `bookmark_manager.lua`: Handles multi-source bookmark aggregation (Lua, files, browsers).
        * `browser_bookmarks.lua`: Logic for importing bookmarks from browsers.
        * `file_bookmarks.lua`: Parses bookmarks from external files (JSON, YAML, TOML, TXT).
        * `input.lua`: Manages search provider logic (Google, DuckDuckGo, etc.).
        * `devdocs.lua`, `mdn.lua`: Integrations for specific documentation sites.
        * `utils.lua`: Cross-platform utilities.
    * `/tests/`: Contains all unit and integration tests, primarily using `plenary.busted`.

## 4. Coding Conventions & Style Guide

* **Formatting:** The project uses `stylua` for code formatting. The configuration is defined in `stylua.toml`. Key styles include 4-space indentation and double quotes for strings.
* **Naming Conventions:** 
    * `variables`, `functions`: `snake_case` (e.g., `my_variable`).
    * `modules`: `snake_case` (e.g., `bookmark_manager.lua`).
* **API Design:** The plugin exposes a public API through its main `browse` module, with functions like `browse()`, `input_search()`, and `open_bookmarks()`. Sub-modules like `devdocs` and `mdn` also have their own public functions.
* **Error Handling:** The codebase uses Lua's standard `pcall` and `error` for handling errors, with user-facing errors reported through Neovim's notification system.

## 5. Key Files & Entrypoints

* **Main Entrypoint(s):** `lua/browse/init.lua` is the main entry point that users interact with.
* **Configuration:** `lua/browse/config.lua` is the primary file for application configuration.
* **CI/CD Pipeline:** There is no CI/CD pipeline configured in the repository.

## 6. Development & Testing Workflow

* **Local Development Environment:** Install the plugin locally in Neovim using a plugin manager and test interactively.
* **Testing:** Tests are run using the `run_tests.sh` script. This script uses `plenary.nvim`'s busted implementation.
    * Run all tests: `./run_tests.sh`
    * Run a specific test file: `nvim --headless -c "PlenaryBustedFile tests/browse/utils_spec.lua" -c "qa!"`
* **CI/CD Process:** Not applicable.

## 7. Specific Instructions for AI Collaboration

* **Contribution Guidelines:** No formal `CONTRIBUTING.md` exists. However, based on the project structure and existing code, contributions should:
    - Follow the existing code style and formatting.
    - Add tests for new features in the `/tests` directory.
    - Maintain backward compatibility.
* **Infrastructure (IaC):** Not applicable.
* **Security:** Be mindful of security when dealing with shell commands for opening browsers. Ensure proper escaping of URLs and search queries to prevent command injection vulnerabilities. The `utils.lua` module is critical for this.
* **Dependencies:** The project has minimal external dependencies. Any new dependencies should be justified and discussed.
* **Commit Messages:** Follow the Conventional Commits specification (e.g., `feat:`, `fix:`, `docs:`, `refactor:`).