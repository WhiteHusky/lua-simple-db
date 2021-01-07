local DBHeaderPrimative = require("simple-db.core.dbheaderprimative")
local DBRecordPrimative = require("simple-db.core.dbrecordprimative")
local RecordFlags = require("simple-db.core.recordflags")

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
---@return DBTable
function DBTable.fromhandle(handle)
    local dbtable = DBTable:new(handle)
    dbtable.start = handle:seek("cur")
    dbtable:readmeta()
    dbtable.header = DBHeaderPrimative.fromhandle(handle)
    dbtable.record = DBRecordPrimative.fromdbheader(dbtable.header)
    dbtable.headerlength = handle:seek("cur") - dbtable.start
    return dbtable
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
    self.moverowsondelete = moverowsondelete == 1
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
    self:writemeta()
    self.header:writeheader(self.handle)
end

function DBTable:insert(...)
    if #{...} ~= #self.record.columns then
        error("not enough columns")
    end
    self.handle:seek("set", self.lastfreerecord)
    self.record:writerecord(self.handle, RecordFlags.VALID, ...)
    self.lastfreerecord = self.handle:seek("cur")
    self.count = self.count + 1
    self.handle:seek("set", self.start)
    self:writemeta()
end

--- Uses a query to find records. Returns a iterator.
---@param query table list of columns with regex searches
---@return function
function DBTable:find(query)
    if not query then query = {} end
    local posquery = {}
    for column, searchfunction in pairs(query) do
        for columnmetaindex, columnmeta in ipairs(self.record.columns) do
            if columnmeta[1] == column then
                posquery[columnmetaindex] = searchfunction
                break
            end
        end
    end
    query = nil
    local nextread = self.handle:seek("set", self.headerlength + 1)
    local outofrecords = false
    return function ()
        if outofrecords then return nil end
        self.handle:seek("set", nextread)
        local record = {}
        local discard = false
        while true do
            record = self.record:readrecord(self.handle)
            if record == nil then
                outofrecords = true
                return nil
            end
            for pos, searchfunction in pairs(posquery) do
                if not searchfunction(record[pos]) then
                    discard = true
                    break
                end
            end
            if not discard then
                nextread = self.handle:seek("cur")
                return table.unpack(record)
            else
                discard = false
            end
        end
    end
end

return DBTable