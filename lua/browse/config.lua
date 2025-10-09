local M = {}

M.opts = {
    provider = "google",
    
    -- Traditional bookmark config (still supported)
    bookmarks = {
        -- -- urls
        -- "https://github.com/lalitmee/browse.nvim",

        -- -- aliases
        -- ["github_code_search"] = "https://github.com/search?q=%s&type=code",
        -- ["github_repo_search"] = "https://github.com/search?q=%s&type=repositories",
    },
    
    -- External bookmark files (JSON, YAML, TOML, TXT)
    bookmark_files = {
        -- "~/bookmarks.json",
        -- "~/.config/bookmarks.yaml",
        -- vim.fn.stdpath("config") .. "/bookmarks.toml",
    },
    
    -- Browser bookmark import
    browser_bookmarks = {
        enabled = false,  -- Set to true to enable browser imports
        browsers = {
            chrome = false,
            firefox = false,
            safari = false,
            edge = false,
        },
        group_by_folder = true,  -- Group by browser folder structure
        auto_detect = true,      -- Auto-detect available browsers
    },
    
    -- Bookmark management options
    deduplicate_bookmarks = true,  -- Remove duplicate URLs
    cache_bookmarks = true,        -- Cache loaded bookmarks
    cache_duration = 60,           -- Cache duration in seconds

    -- Plain text parser options
    plain_text = {
        delimiters = { ":", "=" },
        comment_chars = { "#", ";" },
    },
    
    -- UI options
    icons = {
        bookmark_alias = "->",
        bookmarks_prompt = "",
        grouped_bookmarks = "->",
        file_bookmark = "📄",
        browser_bookmark = "🌐",
    },
    
    persist_grouped_bookmarks_query = false,

    -- Telescope options
    cache_pickers = 10,
    sort_results = true,
}

function M.setup(opts)
    opts = opts or {}
    M.opts = vim.tbl_deep_extend("force", M.opts, opts)
    
    -- Auto-detect browsers if enabled
    if M.opts.browser_bookmarks and M.opts.browser_bookmarks.enabled and M.opts.browser_bookmarks.auto_detect then
        local browser_bookmarks = require("browse.browser_bookmarks")
        local available_browsers = browser_bookmarks.detect_browsers()
        
        -- Enable detected browsers if not explicitly configured
        for browser, _ in pairs(available_browsers) do
            if M.opts.browser_bookmarks.browsers[browser] == nil then
                M.opts.browser_bookmarks.browsers[browser] = true
                vim.notify("Auto-detected and enabled " .. browser .. " bookmark import", vim.log.levels.INFO)
            end
        end
    end
    
    -- Validate bookmark files exist
    if M.opts.bookmark_files then
        local valid_files = {}
        for _, file_path in ipairs(M.opts.bookmark_files) do
            local expanded_path = vim.fn.expand(file_path)
            if vim.fn.filereadable(expanded_path) == 1 then
                table.insert(valid_files, expanded_path)
            else
                vim.notify("Bookmark file not found: " .. file_path, vim.log.levels.WARN)
            end
        end
        M.opts.bookmark_files = valid_files
    end
end

return M
