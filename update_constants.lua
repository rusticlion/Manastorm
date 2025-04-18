-- update_constants.lua
-- A one-time script to replace string literals with Constants module references

local replacements = {
    -- Token Types
    ['"fire"'] = "Constants.TokenType.FIRE",
    ['"force"'] = "Constants.TokenType.FORCE",
    ['"moon"'] = "Constants.TokenType.MOON",
    ['"nature"'] = "Constants.TokenType.NATURE",
    ['"star"'] = "Constants.TokenType.STAR",
    ['"random"'] = "Constants.TokenType.RANDOM",
    ['"any"'] = "Constants.TokenType.ANY",
    
    -- Token States
    ['"FREE"'] = "Constants.TokenState.FREE",
    ['"CHANNELED"'] = "Constants.TokenState.CHANNELED",
    ['"SHIELDING"'] = "Constants.TokenState.SHIELDING",
    ['"LOCKED"'] = "Constants.TokenState.LOCKED",
    ['"DESTROYED"'] = "Constants.TokenState.DESTROYED",
    
    -- Range States
    ['"NEAR"'] = "Constants.RangeState.NEAR",
    ['"FAR"'] = "Constants.RangeState.FAR",
    
    -- Elevation States
    ['"GROUNDED"'] = "Constants.ElevationState.GROUNDED",
    ['"AERIAL"'] = "Constants.ElevationState.AERIAL",
    
    -- Shield Types
    ['"barrier"'] = "Constants.ShieldType.BARRIER",
    ['"ward"'] = "Constants.ShieldType.WARD",
    ['"field"'] = "Constants.ShieldType.FIELD",
    
    -- Attack Types
    ['"projectile"'] = "Constants.AttackType.PROJECTILE",
    ['"remote"'] = "Constants.AttackType.REMOTE",
    ['"zone"'] = "Constants.AttackType.ZONE",
    ['"utility"'] = "Constants.AttackType.UTILITY",
    
    -- Target Types
    ['"SELF"'] = "Constants.TargetType.SELF",
    ['"ENEMY"'] = "Constants.TargetType.ENEMY",
    ['"SLOT_SELF"'] = "Constants.TargetType.SLOT_SELF",
    ['"SLOT_ENEMY"'] = "Constants.TargetType.SLOT_ENEMY",
    ['"POOL_SELF"'] = "Constants.TargetType.POOL_SELF",
    ['"POOL_ENEMY"'] = "Constants.TargetType.POOL_ENEMY",
    ['"caster"'] = "Constants.TargetType.CASTER",
    ['"target"'] = "Constants.TargetType.TARGET",
    
    -- Damage Types
    ['"generic"'] = "Constants.DamageType.GENERIC",
    ['"mixed"'] = "Constants.DamageType.MIXED",
    
    -- Special case for array literals
    ['{"projectile"}'] = "{Constants.AttackType.PROJECTILE}",
    ['{"fire", "force", "moon", "nature", "star", "random"}'] = 
      "{Constants.TokenType.FIRE, Constants.TokenType.FORCE, Constants.TokenType.MOON, Constants.TokenType.NATURE, Constants.TokenType.STAR, Constants.TokenType.RANDOM}",
    ['{"barrier", "ward", "field"}'] = 
      "{Constants.ShieldType.BARRIER, Constants.ShieldType.WARD, Constants.ShieldType.FIELD}"
}

-- Files to process
local files = {
    "keywords.lua",
    "spellCompiler.lua",
    "wizard.lua",
    "manapool.lua"
}

-- Process a file
local function processFile(filename)
    -- Read the file content
    local file = io.open(filename, "r")
    if not file then
        print("Error: Couldn't open file " .. filename)
        return false
    end
    
    local content = file:read("*all")
    file:close()
    
    -- Track replacements
    local numReplacements = 0
    
    -- Perform replacements
    for pattern, replacement in pairs(replacements) do
        -- Count occurrences
        local count = select(2, string.gsub(content, pattern, pattern))
        
        if count > 0 then
            -- Perform replacement
            content, replaced = string.gsub(content, pattern, replacement)
            numReplacements = numReplacements + replaced
            print(string.format("  Replaced %d occurrences of %s with %s", replaced, pattern, replacement))
        end
    end
    
    -- Write the file back
    file = io.open(filename, "w")
    if not file then
        print("Error: Couldn't write to file " .. filename)
        return false
    end
    
    file:write(content)
    file:close()
    
    print(string.format("Processed %s: %d replacements", filename, numReplacements))
    return true
end

-- Main processing
print("Starting constant replacements...")
for _, filename in ipairs(files) do
    print("Processing " .. filename)
    processFile(filename)
end
print("Replacements complete!")