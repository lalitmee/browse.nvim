local M = {}
local utils = require("browse.utils")

-- Browser bookmark file paths for different OS
local bookmark_paths = {
    chrome = {
        Linux = "~/.config/google-chrome/Default/Bookmarks",
        Darwin = "~/Library/Application Support/Google/Chrome/Default/Bookmarks",
        Windows_NT = "%LOCALAPPDATA%/Google/Chrome/User Data/Default/Bookmarks",
    },
    firefox = {
        Linux = "~/.mozilla/firefox/*/bookmarks.json",
        Darwin = "~/Library/Application Support/Firefox/Profiles/*/bookmarks.json",
        Windows_NT = "%APPDATA%/Mozilla/Firefox/Profiles/*/bookmarks.json",
    },
    safari = {
        Darwin = "~/Library/Safari/Bookmarks.plist",
    },
    edge = {
        Linux = "~/.config/microsoft-edge/Default/Bookmarks",
        Darwin = "~/Library/Application Support/Microsoft Edge/Default/Bookmarks",
        Windows_NT = "%LOCALAPPDATA%/Microsoft/Edge/User Data/Default/Bookmarks",
    },
}

-- Get OS name for path resolution
local function get_os_name()
    local os_info = vim.loop.os_uname()
    return os_info.sysname
end

-- Expand path with OS-specific variables
local function expand_path(path)
    path = vim.fn.expand(path)
    if vim.fn.has("win32") == 1 then
        path = path:gsub("%%(%w+)%%", function(var)
            return os.getenv(var) or ""
        end)
    end
    return path
end

-- Find bookmark files using glob patterns
local function find_bookmark_files(pattern)
    local expanded = expand_path(pattern)
    if expanded:match("%*") then
        return vim.fn.glob(expanded, false, true)
    else
        return vim.fn.filereadable(expanded) == 1 and { expanded } or {}
    end
end

-- Parse Chrome/Edge bookmark format (JSON)
local function parse_chromium_bookmarks(data)
    local bookmarks = {}
    
    local function parse_folder(folder, prefix)
        prefix = prefix or ""
        if not folder.children then return end
        
        for _, item in ipairs(folder.children) do
            if item.type == "url" then
                local name = prefix .. item.name
                table.insert(bookmarks, {
                    name = name,
                    url = item.url,
                    folder = prefix:gsub(" / $", "")
                })
            elseif item.type == "folder" then
                parse_folder(item, prefix .. item.name .. " / ")
            end
        end
    end
    
    if data.roots then
        for root_name, root in pairs(data.roots) do
            if root.children then
                parse_folder(root, root_name == "bookmark_bar" and "" or (root_name .. " / "))
            end
        end
    end
    
    return bookmarks
end

-- Parse Firefox bookmark format (JSON)
local function parse_firefox_bookmarks(data)
    local bookmarks = {}
    
    local function parse_item(item, path)
        path = path or ""
        
        if item.type == "text/x-moz-place" and item.uri then
            table.insert(bookmarks, {
                name = item.title or item.uri,
                url = item.uri,
                folder = path
            })
        elseif item.type == "text/x-moz-place-container" and item.children then
            local folder_path = path == "" and item.title or (path .. " / " .. item.title)
            for _, child in ipairs(item.children) do
                parse_item(child, folder_path)
            end
        end
    end
    
    if data.children then
        for _, child in ipairs(data.children) do
            parse_item(child)
        end
    elseif data.type then
        parse_item(data)
    end
    
    return bookmarks
end

-- Parse Safari bookmark format (requires plist conversion)
local function parse_safari_plist_json(data)
    local bookmarks = {}

    local function parse_item(item, path)
        path = path or ""
        if item.WebBookmarkType == "WebBookmarkTypeLeaf" and item.URLString then
            table.insert(bookmarks, {
                name = item.URIDictionary.title,
                url = item.URLString,
                folder = path,
            })
        elseif item.WebBookmarkType == "WebBookmarkTypeList" and item.Children then
            local folder_path = path == "" and item.Title or (path .. " / " .. item.Title)
            for _, child in ipairs(item.Children) do
                parse_item(child, folder_path)
            end
        end
    end

    for _, item in ipairs(data)
    do
        parse_item(item)
    end

    return bookmarks
end

local function parse_safari_bookmarks(file_path)
    if vim.fn.has("mac") == 0 then
        return {}
    end

    if vim.fn.executable("plutil") == 0 then
        vim.notify("plutil not found, skipping Safari bookmark parsing", vim.log.levels.WARN)
        return {}
    end

    local cmd = string.format("plutil -convert json -o - %s", vim.fn.shellescape(file_path))
    local json_str = vim.fn.system(cmd)

    if vim.v.shell_error ~= 0 then
        vim.notify("Failed to convert Safari bookmarks to JSON", vim.log.levels.WARN)
        return {}
    end

    local ok, data = pcall(vim.fn.json_decode, json_str)
    if not ok then
        vim.notify("Failed to parse Safari bookmarks JSON", vim.log.levels.WARN)
        return {}
    end

    return parse_safari_plist_json(data)
end

-- Get bookmarks from a specific browser
function M.get_browser_bookmarks(browser_name)
    local os_name = get_os_name()
    local paths = bookmark_paths[browser_name]

    if not paths or not paths[os_name] then
        vim.notify(string.format("Bookmark path not defined for %s on %s", browser_name, os_name), vim.log.levels.WARN)
        return {}
    end

    local files = find_bookmark_files(paths[os_name])
    if vim.tbl_isempty(files) then
        vim.notify(string.format("No bookmark files found for %s", browser_name), vim.log.levels.INFO)
        return {}
    end

    local all_bookmarks = {}

    for _, file_path in ipairs(files) do
        local parsed_bookmarks = {}
        if browser_name == "safari" then
            parsed_bookmarks = parse_safari_bookmarks(file_path)
        else
            local success, content = pcall(vim.fn.readfile, file_path)
            if not success then
                vim.notify(string.format("Failed to read bookmark file: %s", file_path), vim.log.levels.WARN)
                goto continue
            end

            local json_str = table.concat(content, "\n")
            if json_str == "" then
                goto continue
            end

            local ok, data = pcall(vim.fn.json_decode, json_str)
            if not ok then
                vim.notify(string.format("Failed to parse bookmark file: %s", file_path), vim.log.levels.WARN)
                goto continue
            end

            if browser_name == "chrome" or browser_name == "edge" then
                parsed_bookmarks = parse_chromium_bookmarks(data)
            elseif browser_name == "firefox" then
                parsed_bookmarks = parse_firefox_bookmarks(data)
            end
        end

        vim.list_extend(all_bookmarks, parsed_bookmarks)

        ::continue::
    end

    return all_bookmarks
end

-- Get bookmarks from all available browsers
function M.get_all_browser_bookmarks(browser_config)
    local all_bookmarks = {}
    local browsers = { "chrome", "firefox", "safari", "edge" }
    
    for _, browser in ipairs(browsers) do
        if browser_config[browser] then
            local browser_bookmarks = M.get_browser_bookmarks(browser)
            for _, bookmark in ipairs(browser_bookmarks) do
                bookmark.source = browser
                table.insert(all_bookmarks, bookmark)
            end
        end
    end
    
    return all_bookmarks
end

-- Detect available browsers
function M.detect_browsers()
    local os_name = get_os_name()
    local available = {}
    
    for browser, paths in pairs(bookmark_paths) do
        if paths[os_name] then
            local files = find_bookmark_files(paths[os_name])
            if not vim.tbl_isempty(files) then
                available[browser] = true
            end
        end
    end
    
    return available
end

-- Convert browser bookmarks to browse.nvim format
function M.convert_to_browse_format(bookmarks, group_by_folder)
    if group_by_folder then
        local grouped = {}
        
        for _, bookmark in ipairs(bookmarks) do
            local folder = bookmark.folder or "Imported"
            if not grouped[folder] then
                grouped[folder] = {
                    name = folder .. " (from " .. (bookmark.source or "browser") .. ")"
                }
            end
            
            -- Create a safe key name
            local key = bookmark.name:gsub("[^%w_]", "_"):lower()
            grouped[folder][key] = bookmark.url
        end
        
        return grouped
    else
        local flat = {}
        for _, bookmark in ipairs(bookmarks) do
            local display_name = bookmark.name
            if bookmark.folder and bookmark.folder ~= "" then
                display_name = bookmark.folder .. " / " .. bookmark.name
            end
            flat[display_name] = bookmark.url
        end
        return flat
    end
end

-- Remove duplicate bookmarks based on URL
function M.deduplicate_bookmarks(bookmarks)
    local seen_urls = {}
    local unique_bookmarks = {}
    
    for _, bookmark in ipairs(bookmarks) do
        if not seen_urls[bookmark.url] then
            seen_urls[bookmark.url] = true
            table.insert(unique_bookmarks, bookmark)
        end
    end
    
    return unique_bookmarks
end

return M
