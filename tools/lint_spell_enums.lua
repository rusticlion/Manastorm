-- tools/lint_spell_enums.lua
-- Lints spell element files for raw enum-like string literals.

local function listSpellFiles()
    local files = {}
    local handle = io.popen("find spells/elements -type f -name '*.lua' | sort")
    if not handle then
        return files
    end

    for path in handle:lines() do
        table.insert(files, path)
    end
    handle:close()
    return files
end

local checks = {
    {
        id = "raw_attack_type",
        message = "use Constants.AttackType.*",
        match = function(line)
            return line:match("^%s*attackType%s*=%s*\"")
        end
    },
    {
        id = "raw_visual_shape",
        message = "use Constants.VisualShape.*",
        match = function(line)
            return line:match("^%s*visualShape%s*=%s*\"")
        end
    },
    {
        id = "raw_affinity",
        message = "use Constants.TokenType.* or a constants-backed enum",
        match = function(line)
            return line:match("^%s*affinity%s*=%s*\"")
        end
    },
    {
        id = "raw_target",
        message = "use Constants.TargetType.*",
        match = function(line)
            return line:match("^%s*target%s*=%s*\"")
        end
    },
    {
        id = "raw_cost_tokens",
        message = "use Constants.TokenType.* in cost arrays",
        match = function(line)
            return line:match("^%s*cost%s*=%s*{%s*\"")
        end
    },
    {
        id = "raw_damage_or_type",
        message = "use Constants.DamageType.* / Constants.ShieldType.*",
        match = function(line)
            return line:match("^%s*type%s*=%s*\"[a-z_]+\"")
                or line:match("^%s*damageType%s*=%s*\"[a-z_]+\"")
        end
    },
    {
        id = "raw_state_or_elevation",
        message = "use Constants.TokenState/TokenStatus/ElevationState",
        match = function(line)
            return line:match("token%.state%s*==%s*\"FREE\"")
                or line:match("elevation%s*==%s*\"[A-Z_]+\"")
                or line:match("elevation%s*=%s*\"[A-Z_]+\"")
        end
    },
    {
        id = "legacy_constants_elevation_namespace",
        message = "use Constants.ElevationState.*",
        match = function(line)
            return line:match("Constants%.Elevation%.[A-Z_]+")
        end
    }
}

local findings = {}
for _, filePath in ipairs(listSpellFiles()) do
    local fh = io.open(filePath, "r")
    if fh then
        local lineNo = 0
        for line in fh:lines() do
            lineNo = lineNo + 1
            for _, check in ipairs(checks) do
                if check.match(line) then
                    table.insert(findings, {
                        file = filePath,
                        line = lineNo,
                        id = check.id,
                        message = check.message,
                        text = line
                    })
                end
            end
        end
        fh:close()
    end
end

if #findings == 0 then
    print("[PASS] Spell enum lint passed")
    os.exit(0)
end

print(string.format("[FAIL] Spell enum lint found %d issue(s):", #findings))
for _, finding in ipairs(findings) do
    print(string.format(
        "%s:%d [%s] %s | %s",
        finding.file,
        finding.line,
        finding.id,
        finding.message,
        finding.text:gsub("^%s+", "")
    ))
end
os.exit(1)

