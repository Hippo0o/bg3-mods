---@type Utils
local Utils = Require("Hlib/Utils")

---@type Libs
local Libs = Require("Hlib/Libs")

---@class Chainable
local M = {}

---@class Chainable : LibsStruct
---@field After fun(self: Chainable, func: fun(source: any|nil, ...: any), passSource: boolean|nil): Chainable
---@field Catch fun(self: Chainable, func: fun(source: any|nil, err: string), passSource: boolean|nil): Chainable
---@field Source any
local Chainable = Libs.Struct({
    _IsChainable = nil,
    Source = nil,
    _InitalInput = {},
    _Chain = {},
    _Catch = {},
})

function Chainable.New(source)
    local obj = Chainable.Init()
    obj._IsChainable = Utils.RandomId("Chainable_")
    obj.Source = source
    obj._InitalInput = {}
    obj._Chain = {}

    return obj
end

function Chainable:After(func, passSource)
    if type(func) ~= "function" then
        error("Chainable:After(func) - function expected, got " .. type(func))
    end

    table.insert(self._Chain, { func, passSource })

    return self
end

function Chainable:Catch(func, passSource)
    if type(func) ~= "function" then
        error("Chainable:Catch(func) - function expected, got " .. type(func))
    end

    self._Catch = { func, passSource }

    return self
end

function Chainable:Throw(err)
    local func, passSource = table.unpack(self._Catch)

    if type(func) ~= "function" then
        return self:End(false, err)
    end

    if passSource then
        return self:End(true, { func(self.Source, err) })
    end

    return self:End(true, { func(err) })
end

function Chainable:Begin(...)
    local state = Utils.Table.Combine({ ... }, self._InitalInput)

    if #self._Chain == 0 then
        return self:End(true, state)
    end

    for i, link in ipairs(self._Chain) do
        local func, passSource = table.unpack(link)

        local ok, err = pcall(function()
            if passSource then
                state = { func(self.Source, table.unpack(state)) }
            else
                state = { func(table.unpack(state)) }
            end
        end)

        if not ok then
            state = self:Throw(err)
            break
        end

        if state[1] == nil then
            state = self:End(true, state)
            break
        end

        -- interrupt chain if a nested chainable is returned
        if type(state[1]) == "table" and state[1]._IsChainable then
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

            nested._IsChainable = self._IsChainable

            break
        end

        if i == #self._Chain then
            state = self:End(true, state)
        end
    end

    return state
end

local listeners = {}

---@param success boolean
---@param state table|string
---@return table|string state
function Chainable:End(success, state)
    self._Chain = {}

    if listeners[self._IsChainable] then
        local tbl = listeners[self._IsChainable]
        listeners[self._IsChainable] = nil

        for _, listener in ipairs(tbl) do
            listener(success, state)
        end

        return state
    end

    if not success then
        error(state)
    end

    return state
end

---@param chainable Chainable
---@param func fun(success: boolean, state: table|string)
function M.OnEnd(chainable, func)
    assert(
        type(chainable) == "table" and chainable._IsChainable,
        "Chainable.OnEnd(chainable, ...) - Chainable expected"
    )
    assert(type(func) == "function", "Chainable.OnEnd(..., func) - function expected, got " .. type(func))

    if not listeners[chainable._IsChainable] then
        listeners[chainable._IsChainable] = {}
    end

    table.insert(listeners[chainable._IsChainable], func)
end

---@param source any
---@return Chainable
function M.Create(source)
    return Chainable.New(source)
end

return M
