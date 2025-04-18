-- Pool.lua
-- Object pooling system to reduce garbage generation and frame spikes
-- by reusing tables for frequently created and destroyed objects

local Pool = {}
Pool.__index = Pool

-- Store different pools for different object types
Pool.pools = {}

-- Debug statistics
Pool.stats = {
    acquires = {},
    releases = {},
    creates = {},
    poolSizes = {}
}

-- Create a new pool of objects with a given id
function Pool.create(id, initialSize, factoryFn, resetFn)
    if Pool.pools[id] then
        print("[POOL] WARNING: Pool with id '" .. id .. "' already exists! Using existing pool.")
        return Pool.pools[id]
    end
    
    local pool = {
        id = id,
        objects = {}, -- Available objects
        active = {}, -- Currently in use
        factory = factoryFn or function() return {} end, -- Creates new objects
        reset = resetFn or function(obj) 
            -- Basic reset function (clear all fields)
            for k, _ in pairs(obj) do
                obj[k] = nil
            end
            return obj
        end
    }
    
    -- Initialize stats for this pool
    Pool.stats.acquires[id] = 0
    Pool.stats.releases[id] = 0
    Pool.stats.creates[id] = 0
    Pool.stats.poolSizes[id] = 0
    
    -- Pre-populate the pool with specified number of objects
    for i = 1, initialSize or 0 do
        local obj = pool.factory()
        table.insert(pool.objects, obj)
        Pool.stats.creates[id] = Pool.stats.creates[id] + 1
        Pool.stats.poolSizes[id] = Pool.stats.poolSizes[id] + 1
    end
    
    Pool.pools[id] = pool
    print("[POOL] Created new pool '" .. id .. "' with " .. (initialSize or 0) .. " objects")
    
    return pool
end

-- Get an object from the pool, creating a new one if none are available
function Pool.acquire(id, ...)
    local pool = Pool.pools[id]
    if not pool then
        print("[POOL] WARNING: Acquiring from non-existent pool '" .. id .. "'. Creating new pool.")
        local varArgs = {...}
        -- Using the varargs to determine initialization functions
        local factoryFn = varArgs[1]
        local resetFn = varArgs[2]
        pool = Pool.create(id, 0, factoryFn, resetFn)
    end
    
    local obj
    if #pool.objects > 0 then
        -- Use an existing object from the pool
        obj = table.remove(pool.objects)
    else
        -- Create a new object
        obj = pool.factory()
        Pool.stats.creates[id] = Pool.stats.creates[id] + 1
        Pool.stats.poolSizes[id] = Pool.stats.poolSizes[id] + 1
        -- Debug message when creating a new object (uncomment for debugging)
        -- print("[POOL] Created new object for pool '" .. id .. "'")
    end
    
    -- Mark as active and track statistics
    pool.active[obj] = true
    Pool.stats.acquires[id] = Pool.stats.acquires[id] + 1
    
    return obj
end

-- Return an object to the pool
function Pool.release(id, obj)
    local pool = Pool.pools[id]
    if not pool then
        print("[POOL] ERROR: Trying to release to non-existent pool '" .. id .. "'. Object discarded.")
        return false
    end
    
    -- Check if object is actually from this pool
    if not pool.active[obj] then
        print("[POOL] WARNING: Object being released was not acquired from pool '" .. id .. "'. Object discarded.")
        return false
    end
    
    -- Remove from active set
    pool.active[obj] = nil
    
    -- Reset the object to clean state using pool's reset function
    obj = pool.reset(obj)
    
    -- Add back to available pool
    table.insert(pool.objects, obj)
    Pool.stats.releases[id] = Pool.stats.releases[id] + 1
    
    return true
end

-- Get the current size of a pool (available + active)
function Pool.size(id)
    local pool = Pool.pools[id]
    if not pool then return 0 end
    
    local activeCount = 0
    for _ in pairs(pool.active) do
        activeCount = activeCount + 1
    end
    
    return #pool.objects + activeCount
end

-- Get the number of available objects in the pool
function Pool.available(id)
    local pool = Pool.pools[id]
    if not pool then return 0 end
    
    return #pool.objects
end

-- Get number of active objects from the pool
function Pool.activeCount(id)
    local pool = Pool.pools[id]
    if not pool then return 0 end
    
    local count = 0
    for _ in pairs(pool.active) do
        count = count + 1
    end
    
    return count
end

-- Clear a pool (useful during level transitions or game resets)
function Pool.clear(id)
    local pool = Pool.pools[id]
    if not pool then return end
    
    -- Clear both active and inactive objects
    pool.objects = {}
    pool.active = {}
    
    -- Reset stats
    Pool.stats.poolSizes[id] = 0
    
    print("[POOL] Cleared pool '" .. id .. "'")
end

-- Get debug stats about pool usage
function Pool.getStats()
    local stats = {
        pools = {},
        totalObjects = 0,
        totalActive = 0,
        totalAvailable = 0
    }
    
    for id, pool in pairs(Pool.pools) do
        local activeCount = 0
        for _ in pairs(pool.active) do
            activeCount = activeCount + 1
        end
        
        local poolStats = {
            id = id,
            size = Pool.size(id),
            active = activeCount,
            available = #pool.objects,
            acquires = Pool.stats.acquires[id] or 0,
            releases = Pool.stats.releases[id] or 0,
            creates = Pool.stats.creates[id] or 0
        }
        
        table.insert(stats.pools, poolStats)
        stats.totalObjects = stats.totalObjects + poolStats.size
        stats.totalActive = stats.totalActive + poolStats.active
        stats.totalAvailable = stats.totalAvailable + poolStats.available
    end
    
    return stats
end

-- Print debug stats for all pools
function Pool.printStats()
    local stats = Pool.getStats()
    
    print("\n=== OBJECT POOL STATISTICS ===")
    print(string.format("Total Objects: %d (Active: %d, Available: %d)", 
        stats.totalObjects, stats.totalActive, stats.totalAvailable))
    
    for _, poolStats in ipairs(stats.pools) do
        print(string.format("Pool '%s': %d objects (%d active, %d available)", 
            poolStats.id, poolStats.size, poolStats.active, poolStats.available))
        print(string.format("  - Created: %d, Acquired: %d, Released: %d, Reuse: %.1f%%", 
            poolStats.creates, poolStats.acquires, poolStats.releases,
            poolStats.acquires > 0 and ((poolStats.acquires - poolStats.creates) / poolStats.acquires * 100) or 0))
    end
    print("==============================\n")
end

-- Debug overlay showing pool stats
function Pool.drawDebugOverlay()
    local stats = Pool.getStats()
    
    -- Check if love.graphics is available
    if not love or not love.graphics then return end
    
    -- Save current graphics state
    love.graphics.push("all")
    
    -- Set up colors and font
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 10, 10, 300, 20 + #stats.pools * 40)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("OBJECT POOLS: " .. stats.totalObjects .. " objects (" .. 
        stats.totalActive .. " active, " .. stats.totalAvailable .. " available)", 15, 15)
    
    for i, poolStats in ipairs(stats.pools) do
        love.graphics.print(string.format("'%s': %d obj (%d active, %d avail)", 
            poolStats.id, poolStats.size, poolStats.active, poolStats.available), 20, 15 + i * 20)
        
        -- Calculate reuse percentage
        local reusePercent = poolStats.acquires > 0 and 
            ((poolStats.acquires - poolStats.creates) / poolStats.acquires * 100) or 0
        
        love.graphics.print(string.format("Created: %d, Acq: %d, Reuse: %.1f%%", 
            poolStats.creates, poolStats.acquires, reusePercent), 30, 15 + i * 20 + 12)
        
        -- Draw a small bar showing active vs available
        if poolStats.size > 0 then
            -- Background bar
            love.graphics.setColor(0.3, 0.3, 0.3, 1)
            love.graphics.rectangle("fill", 180, 19 + i * 20, 100, 8)
            
            -- Active portion
            love.graphics.setColor(0.8, 0.3, 0.3, 1)
            love.graphics.rectangle("fill", 180, 19 + i * 20, 
                100 * (poolStats.active / poolStats.size), 8)
        end
    end
    
    -- Restore graphics state
    love.graphics.pop()
end

return Pool