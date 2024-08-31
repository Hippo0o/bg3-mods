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
    _Catch = nil,
    _Final = nil,
})

function Chainable.New(source)
    local obj = Chainable.Init()
    obj._IsChainable = Utils.RandomId("Chainable_")
    obj.Source = source
    obj._InitalInput = {}

    return obj
end

---@param obj any
---@return boolean
function M.IsChainable(value)
    return type(value) == "table" and value._IsChainable
end

---@param source any
---@return Chainable
function M.Create(source)
    return Chainable.New(source)
end

function Chainable:After(func, passSelf, chainOnNil)
    if type(func) ~= "function" then
        error("Chainable:After(func) - function expected, got " .. type(func))
    end

    table.insert(self._Chain, { func, passSelf, chainOnNil })

    return self
end

function Chainable:Catch(func, passSelf)
    if type(func) ~= "function" then
        error("Chainable:Catch(func) - function expected, got " .. type(func))
    end

    self._Catch = { func, passSelf }

    return self
end

function Chainable:Final(func, passSelf)
    if type(func) ~= "function" then
        error("Chainable:Final(func) - function expected, got " .. type(func))
    end

    self._Final = { func, passSelf }

    return self
end

function Chainable:Throw(err)
    local func, passSelf = table.unpack(self._Catch or {})

    if type(func) ~= "function" then
        return self:End(false, { err })
    end

    if passSelf then
        return self:End(true, { func(self, err) })
    end

    return self:End(true, { func(err) })
end

function Chainable:Begin(...)
    local state = Utils.Table.Combine({ ... }, self._InitalInput)

    if #self._Chain == 0 then
        return self:End(true, state)
    end

    for i, link in ipairs(self._Chain) do
        local func, passSelf, chainOnNil = table.unpack(link)

        local ok, err = pcall(function()
            if i == 1 or state[1] or chainOnNil then
                if passSelf then
                    state = { func(self, table.unpack(state)) }
                else
                    state = { func(table.unpack(state)) }
                end
            end
        end)

        if not ok then
            state = { self:Throw(err) }
            break
        end

        -- interrupt chain if a nested chainable is returned
        if M.IsChainable(state[1]) then
            ---@type Chainable
            local nested = state[1]

            local addonChain = Utils.Table.Clone(self._Chain)
            for j = 1, i do
                table.remove(addonChain, 1)
            end

            Utils.Table.Combine(nested._Chain, addonChain)

            nested._InitalInput = Utils.Table.Clone(state)
            table.remove(nested._InitalInput, 1)

            if self._Catch then
                nested._Catch = self._Catch
            end

            if self._Final then
                nested._Final = self._Final
            end

            break
        end

        if i == #self._Chain then
            return self:End(true, state)
        end
    end

    return table.unpack(state)
end

---@param success boolean
---@param state table
---@return any
function Chainable:End(success, state)
    local func, passSelf = table.unpack(self._Final or {})

    if type(func) == "function" then
        local function final()
            if passSelf then
                return { func(self, success, table.unpack(state)) }
            end

            return { func(success, table.unpack(state)) }
        end

        local result = final()

        success = table.remove(result, 1)
        state = result
    end

    if not success then
        error(table.unpack(state))
    end

    return table.unpack(state)
end

return M
