local HandleWrapper = {}

local HandleWrapper = {}

--- Helper to handle reading 
---@return HandleWrapper
function HandleWrapper:new()
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

return HandleWrapper