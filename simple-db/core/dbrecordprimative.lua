local ReadProcedure = require("simple-db.core.readprocedure")
local RecordFlags = require("simple-db.core.recordflags")

local pack = string.pack
local unpack = string.unpack

---@class DBRecordPrimitive
---@field readprocedure function
---@field recordfmt string
---@field columns table
local DBRecordPrimitive = {}

---@param columns table list of lists that have a column name and associated 6.4.2 format strings
---@return DBRecordPrimitive
function DBRecordPrimitive:new(columns)
    local o = {
        columns = columns,
        recordfmt = "",
        readprocedure = function() end,
        fixedlength = false
    }
    for _, column in ipairs(o.columns) do
        local _, fmt = table.unpack(column)
        o.recordfmt = o.recordfmt..fmt
    end
    local readprocedure, fixedlength = ReadProcedure.fromfmt(o.recordfmt)
    o.readprocedure = readprocedure
    o.fixedlength = fixedlength
    setmetatable(o, self)
    self.__index = self
    return o
end

---@param dbheaderprimitive DBHeaderPrimitive
function DBRecordPrimitive.fromdbheader(dbheaderprimitive)
    return DBRecordPrimitive:new(dbheaderprimitive.columns)
end

--- Reads a record and advances to the end of it. Else returns `nil` and advances one.
---@param handle file*
function DBRecordPrimitive:readrecord(handle)
    local meta = string.unpack("B", handle:read(1))
    if meta & RecordFlags.VALID > 0 then
        return {self.readprocedure(handle)}
    else
        return nil
    end
end

--- Writes record to handle
---@param handle file*
---@vararg any columns
function DBRecordPrimitive:writerecord(handle, metaflags, ...)
    handle:write(pack("B"..self.recordfmt, metaflags | RecordFlags.VALID, ...))
end

return DBRecordPrimitive