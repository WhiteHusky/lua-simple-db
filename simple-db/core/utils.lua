local Utils = {}

local pack = string.pack
local unpack = string.unpack

--- Short form of `unpack("c"..len, handle:read(len))`
---@param handle file*
---@param len number
---@return string
function Utils.readfixedstring(handle, len)
    local str = unpack("c"..len, handle:read(len))
    return str
end

--- Reads a string from a handle
---@param handle file*
---@param lenbytes number number of bytes used for length
---@return string
function Utils.readstring(handle, lenbytes)
    local len = unpack("I"..lenbytes, handle:read(lenbytes))
    return Utils.readfixedstring(handle, len)
end

return Utils