-- check_magic_strings.lua
-- CI tool to detect magic strings that should be using Constants

-- List of patterns to search for in the codebase
local magicStringPatterns = {
    -- Token Types
    '"fire"', "'fire'", '"force"', "'force'",
    '"moon"', "'moon'", '"nature"', "'nature'",
    '"star"', "'star'", '"random"', "'random'",
    '"any"', "'any'",
    
    -- Token States
    '"FREE"', "'FREE'", '"CHANNELED"', "'CHANNELED'",
    '"SHIELDING"', "'SHIELDING'", '"LOCKED"', "'LOCKED'",
    '"DESTROYED"', "'DESTROYED'",
    
    -- Range States
    '"NEAR"', "'NEAR'", '"FAR"', "'FAR'",
    
    -- Elevation States
    '"GROUNDED"', "'GROUNDED'", '"AERIAL"', "'AERIAL'",
    
    -- Shield Types
    '"barrier"', "'barrier'", '"ward"', "'ward'",
    '"field"', "'field'",
    
    -- Attack Types
    '"projectile"', "'projectile'", '"remote"', "'remote'",
    '"zone"', "'zone'", '"utility"', "'utility'",
    
    -- Target Types
    '"SELF"', "'SELF'", '"ENEMY"', "'ENEMY'",
    
    -- Damage Types
    '"generic"', "'generic'", '"mixed"', "'mixed'"
}

-- Files to exclude from checking (e.g., test files, documentation)
local excludedPaths = {
    "spec/",
    "test_",
    "docs/",
    "tools/",
    "check_magic_strings.lua",
    "Constants.lua"
}

-- Check if a file should be excluded
local function isExcluded(filepath)
    for _, pattern in ipairs(excludedPaths) do
        if filepath:find(pattern) then
            return true
        end
    end
    return false
end

-- Scan a file for magic strings
local function scanFile(filepath)
    if isExcluded(filepath) then
        return {}
    end
    
    local file = io.open(filepath, "r")
    if not file then
        print("Warning: Could not open file: " .. filepath)
        return {}
    end
    
    local content = file:read("*all")
    file:close()
    
    local issues = {}
    local lineNumber = 1
    
    -- Process file line by line
    for line in content:gmatch("[^\r\n]+") do
        for _, pattern in ipairs(magicStringPatterns) do
            -- Simple pattern matching for demonstration
            if line:find(pattern) then
                -- Check if it's not in a comment or string explanation
                if not line:match("^%s*%-%-") then
                    -- Ignore if it's part of a Constants reference
                    if not line:find("Constants%.") then
                        table.insert(issues, {
                            line = lineNumber,
                            pattern = pattern,
                            content = line:gsub("^%s+", ""):sub(1, 80) -- Trim and truncate for display
                        })
                    end
                end
            end
        end
        lineNumber = lineNumber + 1
    end
    
    return issues
end

-- Recursively scan directory for .lua files
local function scanDirectory(dirPath)
    local issues = {}
    local files = {}
    
    -- In a real implementation, use io.popen to list files
    -- For now, let's just hardcode a list of main files to check
    files = {
        "main.lua",
        "keywords.lua",
        "spells.lua",
        "wizard.lua",
        "manapool.lua",
        "spellCompiler.lua",
        "ui.lua",
        "vfx.lua"
    }
    
    for _, filename in ipairs(files) do
        local filepath = dirPath .. "/" .. filename
        local fileIssues = scanFile(filepath)
        
        if #fileIssues > 0 then
            issues[filepath] = fileIssues
        end
    end
    
    return issues
end

-- Main function
local function main()
    local startDir = arg[1] or "."
    local allIssues = scanDirectory(startDir)
    
    -- Count total issues
    local totalIssues = 0
    for _, fileIssues in pairs(allIssues) do
        totalIssues = totalIssues + #fileIssues
    end
    
    -- Print results
    print("Magic String Check Results")
    print("=========================")
    print("Found " .. totalIssues .. " potential magic string issues")
    
    for filepath, fileIssues in pairs(allIssues) do
        print("\n" .. filepath .. " (" .. #fileIssues .. " issues):")
        for _, issue in ipairs(fileIssues) do
            print(string.format("  Line %d: %s => %s", 
                issue.line, issue.pattern, issue.content))
        end
    end
    
    -- Set exit code for CI
    os.exit(totalIssues > 0 and 1 or 0)
end

main()