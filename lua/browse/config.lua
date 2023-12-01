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
        bookmark_alias = "->", -- if you have nerd fonts, you can set this to ""
        bookmarks_prompt = "", -- if you have nerd fonts, you can set this to "󰂺 "
        grouped_bookmarks = "->", -- if you have nerd fonts, you can set this to 
    },
}

function M.setup(opts)
    opts = opts or {}
    M.opts = vim.tbl_deep_extend("force", M.opts, opts)
end

return M
