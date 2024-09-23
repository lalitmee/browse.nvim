local M = {}

M.opts = {
    provider = "google",
    bookmarks = {
        -- -- urls
        -- "https://github.com/lalitmee/browse.nvim",

        -- -- aliases
        -- ["github_code_search"] = "https://github.com/search?q=%s&type=code",
        -- ["github_repo_search"] = "https://github.com/search?q=%s&type=respositories",
    },
    icons = {
        bookmark_alias = "->",
        bookmarks_prompt = "",
        grouped_bookmarks = "->",
    },
    persist_grouped_bookmarks_query = false,
}

function M.setup(opts)
    opts = opts or {}
    M.opts = vim.tbl_deep_extend("force", M.opts, opts)
end

return M
