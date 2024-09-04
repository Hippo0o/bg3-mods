---@type Utils
local Utils = Require("Hlib/Utils")

---@type Libs
local Libs = Require("Hlib/Libs")

---@class Chainable
local M = {}

---@class Chainable : LibsStruct
---@field After fun(self: Chainable, func: fun(source: any|nil, ...: any), passSelf: boolean|nil, chainOnNil: boolean|nil): Chainable
---@field Catch fun(self: Chainable, func: fun(source: any|nil, err: string), passSelf: boolean|nil): Chainable
---@field Final fun(self: Chainable, func: fun(...: any, passSelf: boolean|nil): boolean, any): Chainable
---@field Source any
local Chainable = Libs.Struct({
    _IsChainable = nil,
    Source = nil,
    _InitalInput = {},
    _Chain = {},
    _Began = false,
})

function Chainable.New(source)
    local obj = Chainable.Init()
    obj._IsChainable = Utils.RandomId("Chainable_")
    obj.Source = source

    return obj
end

---@param value any
---@return boolean
function M.IsChainable(value)
    return type(value) == "table" and value._IsChainable
end

---@param source any
---@return Chainable
function M.Create(source)
    return Chainable.New(source)
end

-- callback to execute in order
-- will be skipped if the previous callback returned nil and chainOnNil is false
function Chainable:After(func, passSelf, chainOnNil)
    if type(func) ~= "function" then
        error("Chainable:After(func) - function expected, got " .. type(func))
    end

    table.insert(self._Chain, { exec = { func, passSelf, chainOnNil } })

    return self
end

-- callback to catch errors happening in the chain before
-- will continue the chain with the result of the catch
function Chainable:Catch(func, passSelf)
    if type(func) ~= "function" then
        error("Chainable:Catch(func) - function expected, got " .. type(func))
    end

    table.insert(self._Chain, { catch = { func, passSelf } })

    return self
end

-- callback to catch errors and finalize the chain before
-- takes priority over catch if before catch
function Chainable:Final(func, passSelf)
    if type(func) ~= "function" then
        error("Chainable:Final(func) - function expected, got " .. type(func))
    end

    table.insert(self._Chain, { final = { func, passSelf } })

    return self
end

function Chainable:Throw(err)
    local catch = {}

    for i, link in ipairs(self._Chain) do
        if link.final then
            break
        end

        if link.catch then
            catch = link.catch
            for j = 1, i do
                table.remove(self._Chain, 1)
            end

            break
        end
    end

    local func, passSelf = table.unpack(catch)

    if type(func) ~= "function" then
        return self:End(false, { err })
    end

    local result = {
        pcall(function()
            if passSelf then
                return func(self, err)
            end

            return func(err)
        end),
    }

    local success = table.remove(result, 1)
    if not success then
        return self:End(false, { table.unpack(result) })
    end

    if not self._Began then
        return self:Begin(table.unpack(result))
    end

    return table.unpack(result)
end

function Chainable:Begin(...)
    local state = Utils.Table.Extend({ ... }, self._InitalInput)
    self._InitalInput = {}
    self._Began = true

    local function createNested(state)
        ---@type Chainable
        local nested = state[1]

        Utils.Table.Extend(nested._Chain, self._Chain)

        self._Chain = {}

        nested._InitalInput = Utils.Table.Clone(state)
        table.remove(nested._InitalInput, 1)

        return nested
    end

    -- defer chain to nested chainable, same as inheritance tbh
    if M.IsChainable(state[1]) then
        return createNested(state)
    end

    local firstExec = true
    while #self._Chain > 0 do
        local link = table.remove(self._Chain, 1)

        local ok, err = pcall(function()
            if link.final then
                table.insert(self._Chain, 1, link)
                state = { self:End(true, state) }
            end

            if not link.exec then
                return
            end

            local func, passSelf, chainOnNil = table.unpack(link.exec)
            if firstExec or state[1] ~= nil or chainOnNil then
                firstExec = false

                if passSelf then
                    state = { func(self, table.unpack(state)) }
                else
                    state = { func(table.unpack(state)) }
                end
            end
        end)

        if not ok then
            state = { self:Throw(err) }
        end

        -- interrupt chain if a nested chainable is returned
        if M.IsChainable(state[1]) then
            return createNested(state)
        end
    end

    return self:End(true, state)
end

---@param success boolean
---@param state table
---@return any
function Chainable:End(success, state)
    while #self._Chain > 0 do
        local link = table.remove(self._Chain, 1)
        if link.final then
            local func, passSelf = table.unpack(link.final)
            if type(func) == "function" then
                local params = { success, table.unpack(state) }
                if passSelf then
                    table.insert(params, 1, self)
                end

                local result = { func(table.unpack(params)) }
                if #result > 0 then
                    success = table.remove(result, 1)
                    state = result
                end
            end

            break
        end
    end

    if not success then
        self._Chain = {}
        error(table.unpack(state))
    end

    if not M.IsChainable(state[1]) then
        self._Chain = {}
    end

    if not self._Began then
        return self:Begin(table.unpack(state))
    end

    return table.unpack(state)
end

return M
