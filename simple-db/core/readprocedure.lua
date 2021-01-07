local Utils = require("simple-db.core.utils")

local pack = string.pack
local unpack = string.unpack

local function size(fmt)
    return string.len(pack(fmt, 0))
end

local function set(list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
  end
  

local fixedfmt = set({"b", "B", "h", "H", "l", "L", "j", "J", "T", "f", "d", "n", "x"})
local fixedvariablefmt = set({"i", "I", "c"})
local variablefmt = set({"s"})
local fixedfmtreadlen = {}
for f, _ in pairs(fixedfmt) do
    fixedfmtreadlen[f] = size(f)
end

local ReadProcedure = {}

local function fixedread(fmt, readlength)
    ---@param handle file*
    ---@return any
    return function (handle) 
        local r = {unpack(fmt, handle:read(readlength))}
        table.remove(r)
        return table.unpack(r)
    end
end

local function variablestringread(lenbytes)
    return function (handle)
        return Utils.readstring(handle, lenbytes)
    end
end

local function mixedprocedure(procedure)
    ---@param handle file*
    return function (handle)
        local results = {}
        local result = {}
        for _, func in ipairs(procedure) do
            result = {func(handle)}
            for _, r in ipairs(result) do
                table.insert(results, r)
            end
        end
        return table.unpack(results)
    end
end

local function fmtwitharg(fmt, start)
    local lenstart, lenend = fmt:find("%d+", start+1)
    if lenstart ~= start+1 then error("bad fmt, expected a digit following fmt but found it elsewhere or not at all") end
    return tonumber(fmt:sub(lenstart, lenend)), lenend - lenstart + 1
end


--- Takes a format and returns a function that takes a handle to gather results
---@param fmt string
---@return function|boolean
function ReadProcedure.fromfmt(fmt)
    local i = 1
    local fmtchain = ""
    local fmtchainreadlen = 0
    local procedure = {}
    local fixedlength = true
    while i < fmt:len() + 1 do
        local part = fmt:sub(i,i)
        -- Handle the easier formats.
        if part == " " then
            -- Blank spaces are valid.
        elseif fixedfmt[part] then
            fmtchain = fmtchain..part
            fmtchainreadlen = fmtchainreadlen + fixedfmtreadlen[part]
        -- Deal with special formats that are fixed length but need additional information.
        elseif fixedvariablefmt[part] then
            local readlen, charlen = fmtwitharg(fmt, i)
            fmtchain = fmtchain..part..readlen
            fmtchainreadlen = fmtchainreadlen + readlen
            i = i + (charlen)
        elseif variablefmt[part] then
            fixedlength = false
            -- The only variable fmt are strings so,
            local readlen, charlen = fmtwitharg(fmt, i)
            -- append the procedure with the current chain and clear the chain
            if fmtchain:len() > 0 then
                table.insert(procedure, fixedread(fmtchain, fmtchainreadlen))
                fmtchain = ""
                fmtchainreadlen = 0
            end
            -- Finally add the string reading procedure
            table.insert(procedure, variablestringread(readlen))
            i = i + (charlen)
        else
            error("invalid fmt: "..part)
        end
        i = i + 1
    end
    -- Add the rest of the chain if present to the procedure if present
    if fmtchain:len() > 0 then
        table.insert(procedure, fixedread(fmtchain, fmtchainreadlen))
    end

    -- If there is one function in the procedure, just return the function, else create a function
    if #procedure < 2 then
        return procedure[1], fixedlength
    else
        ---@param handle file*
        return mixedprocedure(procedure), fixedlength
    end
end

return ReadProcedure