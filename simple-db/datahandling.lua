local simple_db_constants = require('simple-db.constants')

local COLUMN_TYPE = simple_db_constants.COLUMN_TYPE
--[[
local DataHandler = {}

---@param handle file*
---@return any|nil, nil|string
function DataHandler.read(handle)
    error("unimplemented")
end

---@param handle file*
---@return boolean|nil, boolean|string
function DataHandler.write(handle)
    error("unimplemented")
end
]]--

local BooleanDataHandler = {}

---@param handle file*
---@return boolean|nil, nil|string
function BooleanDataHandler.read(handle)
    local old_seek = handle.seek()
    local read_success, result = pcall(handle.read, 1)
    if not read_success then
        handle.seek("set", old_seek)
        return nil, result
    end
    return string.unpack("B", result) & 0x1 > 0 -- Check the first bit
end

---@param handle file*
---@return boolean|nil, boolean|string
function BooleanDataHandler.write(handle)
    local old_seek = handle.seek()
    
    local read_success, result = pcall(handle.read, 1)
    if not read_success then
        handle.seek("set", old_seek)
        return nil, result
    end
end

local column_type_mapping = {
    [COLUMN_TYPE.BOOLEAN] = BooleanDataHandler
}

return {
    BooleanDataHandler = BooleanDataHandler,
    column_type_mapping = column_type_mapping
}