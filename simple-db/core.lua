-- Check if some core 5.3 Lua stuff is missing
assert(string.unpack or string.pack, "Lua 5.3 or higher is required, or a string.pack and string.unpack support library needs to be installed.")

-- Various constants

local simple_db_constants = require('simple-db.constants')

local TableConstructor = require('simple-db.tableconstructor')

local simpledbcore = {
}

--- Initialize a new table to a file handle
--- Returns `true` if the table creation succeeded and the handle advanced to the end of the initilization, `false` if it had failed with a string describing the error with the handle returned back to it's previous position
---@param handle file* handle to write to
---@param table_constructor TableConstructor table constructor
---@return boolean|nil, boolean|string
function simpledbcore.init_table(handle, table_constructor)
    if not table_constructor.passed_validation then
        local success, e = table_constructor:validate()
        if not success then return success, e end
    end
    local old_position = handle.seek()
end

return simpledbcore