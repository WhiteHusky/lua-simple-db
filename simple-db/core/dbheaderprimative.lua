local Utils = require("simple-db.core.utils")

local pack = string.pack
local unpack = string.unpack

---@class DBHeaderPrimitive
---@field columns table
local DBHeaderPrimitive = {}

--[[
    {
        {"my_string_column", "s4"},
        {"my_byte_column", "B"},
    }
]]

--- Creates a new DBHeaderPrimitive from a definition
---@param columns table list of lists that have a column name and associated 6.4.2 format strings
---@return DBHeaderPrimitive
function DBHeaderPrimitive:new(columns)
    local o = {
        columns = columns,
    }

    setmetatable(o, self)
    self.__index = self
    return o
end

--- Reads and creates a new DBHeaderPrimitive from a handle, advancing it to the end of the header
---@param handle file*
---@return DBHeaderPrimitive
function DBHeaderPrimitive.fromhandle(handle)
    local columns = {}
    while true do
        local columnfmtlen = unpack("B", handle:read(1))
        --- If we hit a null, then we're at the end of the definition.
        if columnfmtlen == 0 then break end
        local columnfmt = Utils.readfixedstring(handle, columnfmtlen)
        local columnname = Utils.readstring(handle, 1)
        local column = {}
        table.insert(column, columnname)
        table.insert(column, columnfmt)
        table.insert(columns, column)
    end
    return DBHeaderPrimitive:new(columns)
end

--- Writes table header to handle
---@param handle file* handle to write to
function DBHeaderPrimitive:writeheader(handle)
    for _, column in ipairs(self.columns) do
        local name, fmt = table.unpack(column)
        handle:write(pack("s1s1", fmt, name))
    end
    handle:write("\x00")
end

return DBHeaderPrimitive