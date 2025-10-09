# Browse.nvim Enhanced Features

This document describes the enhanced features available in browse.nvim, including multi-source bookmark management, browser imports, and external file support.

## Multi-Source Bookmark Management

Browse.nvim now supports loading bookmarks from multiple sources simultaneously:

### 1. Traditional Lua Configuration
```lua
require('browse').setup({
    bookmarks = {
        -- Direct URLs
        "https://github.com/neovim/neovim",
        
        -- URLs with aliases
        ["github_search"] = "https://github.com/search?q=%s",
        
        -- Grouped bookmarks
        ["development"] = {
            name = "Development Resources",
            ["github"] = "https://github.com",
            ["stackoverflow"] = "https://stackoverflow.com/search?q=%s"
        }
    }
})
```

### 2. Browser Bookmark Import
Automatically import bookmarks from your browsers:

```lua
require('browse').setup({
    browser_bookmarks = {
        enabled = true,
        browsers = {
            chrome = true,
            firefox = true,
            safari = true,
            edge = false
        },
        group_by_folder = true,  -- Preserve browser folder structure
        auto_detect = true       -- Auto-detect available browsers
    }
})
```

**Supported Browsers:**
- **Chrome/Chromium** - Linux, macOS, Windows
- **Firefox** - Linux, macOS, Windows  
- **Safari** - macOS only
- **Microsoft Edge** - Linux, macOS, Windows

### 3. External Bookmark Files
Load bookmarks from external files in multiple formats:

```lua
require('browse').setup({
    bookmark_files = {
        "~/bookmarks.json",
        "~/.config/bookmarks.yaml",
        vim.fn.stdpath("config") .. "/bookmarks.toml"
    }
})
```

**Supported File Formats:**

#### JSON Format
```json
{
  "development": {
    "name": "Development Resources",
    "github": "https://github.com/search?q=%s&type=code",
    "stackoverflow": "https://stackoverflow.com/search?q=%s"
  },
  "direct": {
    "hackernews": "https://news.ycombinator.com"
  }
}
```

#### YAML Format
```yaml
development:
  name: Development Resources
  github: https://github.com/search?q=%s&type=code
  stackoverflow: https://stackoverflow.com/search?q=%s

direct:
  hackernews: https://news.ycombinator.com
```

#### TOML Format
```toml
[development]
name = "Development Resources"
github = "https://github.com/search?q=%s&type=code"
stackoverflow = "https://stackoverflow.com/search?q=%s"

[direct]
hackernews = "https://news.ycombinator.com"
```

#### Plain Text Format
```
[Development]
GitHub: https://github.com/search?q=%s&type=code
Stack Overflow: https://stackoverflow.com/search?q=%s

[Direct Links]
https://news.ycombinator.com
https://dev.to
```

## Advanced Configuration

### Complete Configuration Example
```lua
require('browse').setup({
    -- Search provider
    provider = "google", -- google, duckduckgo, bing, brave
    
    -- Traditional bookmarks (still supported)
    bookmarks = {
        ["quick_search"] = "https://google.com/search?q=%s"
    },
    
    -- External bookmark files
    bookmark_files = {
        "~/dev-bookmarks.json",
        "~/.config/personal-bookmarks.yaml"
    },
    
    -- Browser bookmark import
    browser_bookmarks = {
        enabled = true,
        browsers = {
            chrome = true,
            firefox = true,
            safari = false,
            edge = false
        },
        group_by_folder = true,
        auto_detect = true
    },
    
    -- Bookmark management
    deduplicate_bookmarks = true,  -- Remove duplicate URLs
    cache_bookmarks = true,        -- Cache for performance
    cache_duration = 60,           -- Cache duration in seconds
    
    -- UI customization
    icons = {
        bookmark_alias = "→",
        bookmarks_prompt = "🔖",
        grouped_bookmarks = "📁",
        file_bookmark = "📄",
        browser_bookmark = "🌐"
    },
    
    persist_grouped_bookmarks_query = false
})
```

### Browser Auto-Detection
When `auto_detect` is enabled, browse.nvim will:
1. Scan common browser bookmark locations
2. Automatically enable browsers with found bookmarks
3. Notify you which browsers were detected
4. Respect manual browser configurations (won't override explicit settings)

### Bookmark Validation
All bookmarks undergo validation:
- URL format checking
- Structure validation
- Error reporting with specific paths
- Graceful error handling (invalid bookmarks are skipped)

### Performance Features
- **Caching**: Bookmarks are cached to avoid repeated file reads
- **Smart Merging**: Duplicate URLs are automatically removed
- **Lazy Loading**: Browser bookmarks are only parsed when needed
- **Background Processing**: File operations don't block the UI

## New API Functions

### Bookmark Management
```lua
local bookmark_manager = require('browse.bookmark_manager')

-- Get all bookmarks from all sources
local bookmarks = bookmark_manager.get_bookmarks()

-- Force refresh cache
local bookmarks = bookmark_manager.get_bookmarks(true)

-- Search bookmarks
local results = bookmark_manager.search_bookmarks("neovim")

-- Get statistics
local stats = bookmark_manager.get_stats()
print("Total bookmarks:", stats.total_bookmarks)
print("Unique domains:", stats.unique_domain_count)

-- Add new bookmark
bookmark_manager.add_bookmark("new_site", "https://example.com", "~/bookmarks.json")

-- Clear cache
bookmark_manager.clear_cache()
```

### Browser Bookmarks
```lua
local browser_bookmarks = require('browse.browser_bookmarks')

-- Get bookmarks from specific browser
local chrome_bookmarks = browser_bookmarks.get_browser_bookmarks("chrome")

-- Detect available browsers
local available = browser_bookmarks.detect_browsers()

-- Get all browser bookmarks
local all_browser_bookmarks = browser_bookmarks.get_all_browser_bookmarks({
    chrome = true,
    firefox = true
})
```

### File Bookmarks
```lua
local file_bookmarks = require('browse.file_bookmarks')

-- Load from file
local bookmarks, error = file_bookmarks.load_from_file("~/bookmarks.json")

-- Save to file
file_bookmarks.save_to_file(bookmarks, "~/bookmarks.yaml", "yaml")

-- Get supported formats
local formats = file_bookmarks.get_supported_formats() -- {"json", "yaml", "toml", "txt"}

-- Find bookmark files in directory
local files = file_bookmarks.find_bookmark_files("~/.config")
```

## Migration Guide

### From Old Configuration
Old configurations remain fully compatible:

```lua
-- Old style (still works)
require('browse').setup({
    bookmarks = {
        ["github"] = "https://github.com"
    }
})

-- New style (enhanced features)
require('browse').setup({
    bookmarks = {
        ["github"] = "https://github.com"
    },
    browser_bookmarks = { enabled = true },
    bookmark_files = { "~/bookmarks.json" }
})
```

### Extracting Browser Bookmarks
1. Enable browser import: `browser_bookmarks.enabled = true`
2. Run `:Browse` to see imported bookmarks
3. Use bookmark manager to save to external file:
   ```lua
   :lua require('browse.bookmark_manager').save_to_external_file()
   ```

## Troubleshooting

### Common Issues

**Browser bookmarks not found:**
- Check browser is installed and has bookmarks
- Verify browser bookmark file permissions
- Try manual browser specification instead of auto-detect

**External file not loading:**
- Check file exists and is readable
- Validate file format (use online JSON/YAML validators)
- Check file permissions

**Performance issues:**
- Disable browser imports if not needed
- Reduce cache duration for development
- Use fewer external bookmark files

### Debug Mode
Enable debug logging:
```lua
vim.g.browse_debug = true
```

### Getting Help
1. Check `:checkhealth browse` (if implemented)
2. Review error messages in `:messages`
3. Test with minimal configuration
4. Check file permissions and paths
