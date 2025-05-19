local Log = {}

-- Flag to enable verbose debug logging
Log.verbose = false

--- Set verbose logging flag
-- @param enabled boolean
function Log.setVerbose(enabled)
    Log.verbose = not not enabled
end

--- Print a debug message if verbose logging is enabled
function Log.debug(...)
    if Log.verbose then
        print(...)
    end
end

return Log
