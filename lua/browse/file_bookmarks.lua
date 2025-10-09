local M = {}

-- Supported file extensions and their parsers
local parsers = {
    json = "parse_json",
    yaml = "parse_yaml",
    yml = "parse_yaml",
    toml = "parse_toml",
    txt = "parse_plain_text",
}

-- Parse JSON bookmark file
local function parse_json(content)
    local json_str = table.concat(content, "\n")
    local ok, data = pcall(vim.fn.json_decode, json_str)
    
    if not ok then
        return nil, "Invalid JSON format"
    end
    
    return data, nil
end

-- Parse YAML bookmark file (improved implementation)
local function parse_yaml(content)
    local bookmarks = {}
    local path = {}
    local line_num = 0

    for _, line in ipairs(content) do
        line_num = line_num + 1
        local indent, key, value = line:match("^(%s*)(%S+):%s*(.*)")

        if key then
            -- Handle comments
            value = value:match("([^#]+)") or value
            value = value:gsub("^%s*", ""):gsub("%s*$", "")

            -- Handle quotes
            if value:match('^"(.*)"$') or value:match("^'(.*)'$") then
                value = value:sub(2, -2)
            end

            local level = #indent / 2 + 1

            if level > #path + 1 then
                return nil, string.format("Invalid indentation at line %d", line_num)
            end

            while #path >= level do
                table.remove(path)
            end

            local current_level = bookmarks
            for i = 1, #path do
                current_level = current_level[path[i]]
            end

            if value == "" then
                -- This is a new group
                current_level[key] = { name = key }
                table.insert(path, key)
            else
                -- This is a key-value pair
                current_level[key] = value
            end
        elseif line:match("^%s*-") then
            return nil, string.format("Lists are not supported at line %d", line_num)
        end
    end

    return bookmarks, nil
end

-- Parse TOML bookmark file (improved implementation)
local function parse_toml(content)
    local bookmarks = {}
    local current_table = bookmarks
    local line_num = 0

    for _, line in ipairs(content) do
        line_num = line_num + 1
        line = line:gsub("^%s*", ""):gsub("%s*$", "")

        if line:match("^%[.+%]") and not line:match("^%[%[.+%]%]") then
            -- Table
            local key = line:match("%[(.+)%]")
            local parts = {}
            for part in key:gmatch("[^%.]+") do
                table.insert(parts, part)
            end

            current_table = bookmarks
            for i = 1, #parts do
                local part = parts[i]
                if not current_table[part] then
                    current_table[part] = {}
                end
                current_table = current_table[part]
            end
        elseif line:match("^%[%[.+%]%]") then
            -- Array of Tables
            local key = line:match("%[%[(.+)%]%]")
            if not bookmarks[key] then
                bookmarks[key] = {}
            end
            current_table = {}
            table.insert(bookmarks[key], current_table)
        elseif line:match("=") then
            -- Key-value pair
            local key, value = line:match("([^=]+)=(.+)")
            key = key:gsub("^%s*", ""):gsub("%s*$", "")
            value = value:gsub("^%s*", ""):gsub("%s*$", "")

            -- Handle types
            if value:match('^"(.*)"$') then
                value = value:sub(2, -2)
            elseif value == "true" then
                value = true
            elseif value == "false" then
                value = false
            elseif tonumber(value) then
                value = tonumber(value)
            else
                return nil, string.format("Invalid value at line %d", line_num)
            end

            current_table[key] = value
        elseif line ~= "" and not line:match("^#") then
            return nil, string.format("Invalid syntax at line %d", line_num)
        end
    end

    return bookmarks, nil
end

-- Parse plain text bookmark file (improved implementation)
local function parse_plain_text(content, opts)
    opts = opts or {}
    local delimiters = opts.delimiters or { ":" }
    local comment_chars = opts.comment_chars or { "#" }
    local line_num = 0

    local bookmarks = {}
    local current_section = "bookmarks"
    bookmarks[current_section] = { name = "Text Bookmarks" }

    for _, line in ipairs(content) do
        line_num = line_num + 1
        line = line:gsub("^%s*", ""):gsub("%s*$", "")

        local is_comment = false
        for _, char in ipairs(comment_chars) do
            if line:match("^" .. char) then
                is_comment = true
                break
            end
        end

        if line ~= "" and not is_comment then
            if line:match("^%[.+%]") then
                -- Section like [Development]
                current_section = line:gsub("^%[", ""):gsub("%]$", "")
                bookmarks[current_section] = { name = current_section }
            elseif line:match("^https?://") then
                -- Direct URL
                table.insert(bookmarks[current_section], line)
            else
                -- Name: URL format
                local found = false
                for _, delim in ipairs(delimiters) do
                    local name, url = line:match("^(.-)" .. delim .. "%s*(.+)$")
                    if name and url then
                        name = name:gsub("%s*$", ""):gsub(" ", "_"):lower()
                        bookmarks[current_section][name] = url
                        found = true
                        break
                    end
                end
                if not found then
                    return nil, string.format("Invalid syntax at line %d", line_num)
                end
            end
        end
    end

    return bookmarks, nil
end

-- Get file extension
local function get_file_extension(file_path)
    return file_path:match("%.([^%.]+)$") or ""
end

-- Validate bookmark structure
local function validate_bookmarks(bookmarks)
    if type(bookmarks) ~= "table" then
        return false, "Bookmarks must be a table"
    end
    
    for key, value in pairs(bookmarks) do
        if type(key) == "string" then
            if type(value) == "string" then
                -- Simple key-value pair
                if not value:match("^https?://") then
                    return false, "Invalid URL: " .. value
                end
            elseif type(value) == "table" then
                -- Grouped bookmarks
                for sub_key, sub_value in pairs(value) do
                    if type(sub_value) == "string" and sub_key ~= "name" then
                        if not sub_value:match("^https?://") then
                            return false, "Invalid URL in group " .. key .. ": " .. sub_value
                        end
                    end
                end
            end
        elseif type(key) == "number" and type(value) == "string" then
            -- Array entry
            if not value:match("^https?://") then
                return false, "Invalid URL: " .. value
            end
        end
    end
    
    return true, nil
end

-- Load bookmarks from file
function M.load_from_file(file_path)
    -- Check if file exists
    if vim.fn.filereadable(file_path) ~= 1 then
        return nil, "File not found: " .. file_path
    end
    
    -- Get file extension and parser
    local ext = get_file_extension(file_path):lower()
    local parser_name = parsers[ext]
    
    if not parser_name then
        return nil, "Unsupported file format: " .. ext
    end
    
    -- Read file content
    local ok, content = pcall(vim.fn.readfile, file_path)
    if not ok then
        return nil, "Failed to read file: " .. file_path
    end
    
    -- Parse content
    local bookmarks, parse_error
    
    if parser_name == "parse_json" then
        bookmarks, parse_error = parse_json(content)
    elseif parser_name == "parse_yaml" then
        bookmarks, parse_error = parse_yaml(content)
    elseif parser_name == "parse_toml" then
        bookmarks, parse_error = parse_toml(content)
    elseif parser_name == "parse_plain_text" then
        local config = require("browse.config")
        bookmarks, parse_error = parse_plain_text(content, config.opts.plain_text)
    end
    
    if parse_error then
        return nil, parse_error
    end
    
    -- Validate bookmarks
    local valid, validation_error = validate_bookmarks(bookmarks)
    if not valid then
        return nil, validation_error
    end
    
    return bookmarks, nil
end

-- Save bookmarks to file
function M.save_to_file(bookmarks, file_path, format)
    format = format or get_file_extension(file_path):lower()
    
    local content_lines = {}
    
    if format == "json" then
        local json_str = vim.fn.json_encode(bookmarks)
        table.insert(content_lines, json_str)
    elseif format == "yaml" or format == "yml" then
        local function write_yaml_level(tbl, indent)
            indent = indent or ""
            for key, value in pairs(tbl) do
                if type(value) == "table" and key ~= "name" then
                    table.insert(content_lines, indent .. key .. ":")
                    write_yaml_level(value, indent .. "  ")
                elseif type(value) == "string" and key ~= "name" then
                    table.insert(content_lines, indent .. key .. ": " .. value)
                end
            end
        end
        write_yaml_level(bookmarks)
    elseif format == "toml" then
        local function write_toml_level(tbl, path)
            local keys = {}
            for k, v in pairs(tbl) do
                if type(v) ~= "table" then
                    table.insert(keys, k)
                end
            end
            table.sort(keys)

            if #keys > 0 then
                if path ~= "" then
                    table.insert(content_lines, "[" .. path .. "]")
                end
                for _, key in ipairs(keys) do
                    local value = tbl[key]
                    if type(value) == "string" then
                        table.insert(content_lines, key .. ' = "' .. value .. '"')
                    else
                        table.insert(content_lines, key .. " = " .. tostring(value))
                    end
                end
                table.insert(content_lines, "")
            end

            for key, value in pairs(tbl) do
                if type(value) == "table" then
                    local new_path = path == "" and key or (path .. "." .. key)
                    write_toml_level(value, new_path)
                end
            end
        end
        write_toml_level(bookmarks, "")
    elseif format == "txt" then
        for group_name, group_data in pairs(bookmarks) do
            table.insert(content_lines, "[" .. group_name .. "]")
            for key, value in pairs(group_data) do
                if key ~= "name" then
                    if type(key) == "number" then
                        table.insert(content_lines, value)
                    else
                        table.insert(content_lines, key .. ": " .. value)
                    end
                end
            end
            table.insert(content_lines, "")
        end
    else
        return false, "Unsupported format: " .. format
    end
    
    local ok, result = pcall(vim.fn.writefile, content_lines, file_path)
    -- writefile returns 0 on success, any other value or error means failure
    local success = ok and (result == 0 or result == nil)
    if success then
        return true, nil
    else
        return false, "Failed to write file"
    end
end

-- Get supported file formats
function M.get_supported_formats()
    return vim.tbl_keys(parsers)
end

-- Detect bookmark files in directory
function M.find_bookmark_files(directory)
    local found_files = {}
    local search_patterns = {}
    
    for ext in pairs(parsers) do
        table.insert(search_patterns, "*." .. ext)
    end
    
    for _, pattern in ipairs(search_patterns) do
        local full_pattern = directory .. "/" .. pattern
        local files = vim.fn.glob(full_pattern, false, true)
        vim.list_extend(found_files, files)
    end
    
    return found_files
end

return M
