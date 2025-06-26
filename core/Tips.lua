local Tips = {}

local loadedTips = nil

local function parseTips(json)
    local tips = {}
    if not json then return tips end
    for tipBlock in json:gmatch("%{[^{}]*%}") do
        local title = tipBlock:match('"title"%s*:%s*"(.-)"')
        local content = tipBlock:match('"content"%s*:%s*"(.-)"')
        local source = tipBlock:match('"source"%s*:%s*"(.-)"')
        if title and content and source then
            table.insert(tips, {
                title = title,
                content = content,
                source = source
            })
        end
    end
    return tips
end

function Tips.load(path)
    if loadedTips then
        return loadedTips
    end
    local data = love.filesystem.read(path)
    if not data then
        print("ERROR: Could not load tips file: " .. tostring(path))
        loadedTips = {}
        return loadedTips
    end
    loadedTips = parseTips(data)
    return loadedTips
end

function Tips.getRandomTip()
    if not loadedTips then
        return nil
    end
    if #loadedTips == 0 then
        return nil
    end
    return loadedTips[love.math.random(#loadedTips)]
end

return Tips
