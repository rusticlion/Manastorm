local Settings = {}

-- Default configuration
local defaults = {
    dummyFlag = false,
    gameSpeed = "FAST",
    controls = {
        p1 = { slot1 = "q", slot2 = "w", slot3 = "e", cast = "f", free = "g", book = "b" },
        p2 = { slot1 = "i", slot2 = "o", slot3 = "p", cast = "j", free = "h", book = "m" }
    }
}

local function deepcopy(tbl)
    if type(tbl) ~= "table" then return tbl end
    local result = {}
    for k, v in pairs(tbl) do
        result[k] = deepcopy(v)
    end
    return result
end

local function serialize(tbl, indent)
    indent = indent or 0
    local parts = {"{\n"}
    local pad = string.rep(" ", indent + 2)
    for k, v in pairs(tbl) do
        local key
        if type(k) == "string" then
            key = k .. " = "
        else
            key = "[" .. k .. "] = "
        end
        if type(v) == "table" then
            table.insert(parts, pad .. key .. serialize(v, indent + 2) .. ",\n")
        elseif type(v) == "string" then
            table.insert(parts, pad .. key .. string.format("%q", v) .. ",\n")
        else
            table.insert(parts, pad .. key .. tostring(v) .. ",\n")
        end
    end
    table.insert(parts, string.rep(" ", indent) .. "}")
    return table.concat(parts)
end

Settings.data = nil

function Settings.load()
    if love.filesystem.getInfo("settings.lua") then
        local chunk = love.filesystem.load("settings.lua")
        local ok, result = pcall(chunk)
        if ok and type(result) == "table" then
            Settings.data = result
            -- Backwards compatibility: convert numeric gameSpeed
            if type(Settings.data.gameSpeed) ~= "string" then
                Settings.data.gameSpeed = "FAST"
            end
            return
        end
    end
    Settings.data = deepcopy(defaults)
    Settings.save()
end

function Settings.save()
    if not Settings.data then return end
    local serialized = "return " .. serialize(Settings.data) .. "\n"
    love.filesystem.write("settings.lua", serialized)
end

function Settings.get(key)
    if not Settings.data then Settings.load() end
    return Settings.data[key]
end

function Settings.set(key, value)
    if not Settings.data then Settings.load() end
    Settings.data[key] = value
    Settings.save()
end

function Settings.getDefaults()
    return deepcopy(defaults)
end

return Settings
