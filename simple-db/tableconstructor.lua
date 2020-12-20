local simple_db_constants = require('simple-db.constants')

local NULL = simple_db_constants.NULL

local COLUMN_TYPE = simple_db_constants.COLUMN_TYPE

local RECORD_ID_TYPE = simple_db_constants.RECORD_ID_TYPE

--- Returns `true` or `false` if a value is in a table
---@param table table
---@param value any
---@return boolean
local function in_table(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

local TableConstructor = {}

--- Helper to create tables
---@return TableConstructor
function TableConstructor:new()
    local o = {
        record_id_type = NULL,
        -- column_name = column_type
        columns = {},
        passed_validation = false
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

--- Adds a column to the table construction
---@param column_name string Name of the column
---@param column_type number Type of the column
---@return TableConstructor
function TableConstructor:add_column(column_name, column_type)
    self.columns[column_name] = column_type
    self.passed_validation = false
    return self
end

--- Sets the record id type
---@param record_id_type number Record ID type
---@return TableConstructor
function TableConstructor:set_record_id_type(record_id_type)
    self.record_id_type = record_id_type
    self.passed_validation = false
    return self
end

--- Validates a table construction
--- Returns `true` if validation succeeded or `false` with a string describing the error.
---@return boolean|nil, boolean|string
function TableConstructor:validate()
    if not in_table(RECORD_ID_TYPE, self.record_id_type) then
        return false, "invalid record id type"
    end
    for column_name, column_type in pairs(self.columns) do
        if not in_table(COLUMN_TYPE, column_type) then
            return false, "`" .. column_name .."` has an invalid column type"
        end
    end
    self.passed_validation = true
    return true
end

return TableConstructor