local DBHeaderPrimative = require("simple-db.core.dbheaderprimative")
local DBRecordPrimative = require("simple-db.core.dbrecordprimative")

local pack = string.pack
local unpack = string.unpack


---@class DBTable
---@field handle file*
---@field header DBHeaderPrimitive
---@field record DBRecordPrimitive
---@field count number
---@field moverowsondelete boolean
---@field headerlength number
---@field lastfreerecord number
---@field start number
local DBTable = {}

---@param handle file*
function DBTable:new(handle)
    local o = {
        handle = handle,
        header = nil, -- DBHeaderPrimative:new(columns),
        record = nil, -- DBRecordPrimative:new(columns),
        moverowsondelete = false,
        count = 0,
        headerlength = 0,
        lastfreerecord = 0,
        start = 0
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---@param handle file*
function DBTable.fromhandle(handle)
    local dbtable = DBTable:new(handle)
    dbtable.start = handle:seek("cur")
    dbtable:readmeta()
    dbtable.header = DBHeaderPrimative.fromhandle(handle)
    dbtable.record = DBRecordPrimative.fromdbheader(dbtable.header)
    dbtable.headerlength = handle:seek("cur") - dbtable.start
end

---@param handle file*
---@param columns table list of lists that have a column name and associated 6.4.2 format strings
---@param moverowsondelete boolean if deleting will move rows down to prevent fragmentation
function DBTable.newtable(handle, columns, moverowsondelete)
    local dbtable = DBTable:new(handle)
    dbtable.header = DBHeaderPrimative:new(columns)
    dbtable.record = DBRecordPrimative.fromdbheader(dbtable.header)
    dbtable.moverowsondelete = moverowsondelete
    dbtable.start = handle:seek("cur")
    dbtable:write()
    dbtable.headerlength = handle:seek("cur") - dbtable.start
    dbtable.lastfreerecord = dbtable.headerlength + 1
    handle:seek("set", dbtable.start)
    dbtable:writemeta()
    handle:seek("set", dbtable.lastfreerecord)
    return dbtable
end

function DBTable:readmeta()
    local count, lastfreerecord, moverowsondelete = unpack("I4I4B", self.handle:read(9))
    self.count = count
    self.lastfreerecord = lastfreerecord
    self.moverowsondelete = moverowsondelete
end

function DBTable:writemeta()
    self.handle:write(pack(
        "I4I4B",
        self.count,
        self.lastfreerecord,
        self.moverowsondelete and 1 or 0
    ))
end

function DBTable:write()
    DBTable:writemeta()
    self.header:writeheader(self.handle)
end

return DBTable