local Settings = {}
local Constants = require("core.Constants")

-- Default configuration
local defaults = {
    dummyFlag = false,
    gameSpeed = "FAST",
    controls = {
        keyboardP1 = {
            [Constants.ControlAction.P1_SLOT1] = "q",
            [Constants.ControlAction.P1_SLOT2] = "w",
            [Constants.ControlAction.P1_SLOT3] = "e",
            [Constants.ControlAction.P1_CAST]  = "f",
            [Constants.ControlAction.P1_FREE]  = "g",
            [Constants.ControlAction.P1_BOOK]  = "b",
            [Constants.ControlAction.MENU_UP]    = "up",
            [Constants.ControlAction.MENU_DOWN]  = "down",
            [Constants.ControlAction.MENU_LEFT]  = "left",
            [Constants.ControlAction.MENU_RIGHT] = "right",
            [Constants.ControlAction.MENU_CONFIRM]     = "return",
            [Constants.ControlAction.MENU_CANCEL_BACK] = "escape"
        },
        keyboardP2 = {
            [Constants.ControlAction.P2_SLOT1] = "i",
            [Constants.ControlAction.P2_SLOT2] = "o",
            [Constants.ControlAction.P2_SLOT3] = "p",
            [Constants.ControlAction.P2_CAST]  = "j",
            [Constants.ControlAction.P2_FREE]  = "h",
            [Constants.ControlAction.P2_BOOK]  = "m"
        },
        gamepadP1 = {
            [Constants.ControlAction.P1_SLOT1] = "dpdown",
            [Constants.ControlAction.P1_SLOT2] = "dpleft",
            [Constants.ControlAction.P1_SLOT3] = "dpright",
            [Constants.ControlAction.P1_CAST]  = "a",
            [Constants.ControlAction.P1_FREE]  = "y",
            [Constants.ControlAction.P1_BOOK]  = "b",
            [Constants.ControlAction.MENU_UP]    = "dpup",
            [Constants.ControlAction.MENU_DOWN]  = "dpdown",
            [Constants.ControlAction.MENU_LEFT]  = "dpleft",
            [Constants.ControlAction.MENU_RIGHT] = "dpright",
            [Constants.ControlAction.MENU_CONFIRM]     = "a",
            [Constants.ControlAction.MENU_CANCEL_BACK] = "b"
        },
        gamepadP2 = {
            [Constants.ControlAction.P2_SLOT1] = "dpdown",
            -- Placeholder for P2 controller mappings
        }
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

local function mergeDefaults(target, default)
    for k, v in pairs(default) do
        if type(v) == "table" then
            if type(target[k]) ~= "table" then
                target[k] = deepcopy(v)
            else
                mergeDefaults(target[k], v)
            end
        elseif target[k] == nil then
            target[k] = v
        end
    end
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
            -- Merge new defaults for missing values
            mergeDefaults(Settings.data, defaults)
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
