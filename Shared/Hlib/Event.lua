---@type Utils
local Utils = Require("Hlib/Utils")

---@type Chainable
local Chainable = Require("Hlib/Chainable")

---@type Log
local Log = Require("Hlib/Log")

---@type Libs
local Libs = Require("Hlib/Libs")

---@class Event
local M = {}

local listeners = {}

-- exposed
---@class EventListener : LibsStruct
---@field private _Id string
---@field private _Event string
---@field private _Func fun(...: any)
---@field Once boolean
---@field Exec fun(self: EventListener, ...: any)
---@field Unregister fun(self: EventListener)
local EventListener = Libs.Struct({
    _Id = nil,
    _Event = nil,
    _Func = function() end,
    Once = false,
    Exec = function(self, ...)
        local args = { ... }

        xpcall(function()
            self._Func(table.unpack(args))
        end, function(err)
            Log.Error(err)
        end)

        if self.Once then
            self:Unregister()
        end
    end,
    Register = function(self)
        if not listeners[self._Event] then
            listeners[self._Event] = {}
        end

        table.insert(listeners[self._Event], self)
    end,
    Unregister = function(self)
        local eventListeners = listeners[self._Event]
        if not eventListeners then
            return
        end

        for i = #eventListeners, 1, -1 do
            if eventListeners[i]._Id == self._Id then
                Log.Debug("Event/Unregister", self._Event, self._Id)
                table.remove(eventListeners, i)
            end
        end

        if #eventListeners == 0 then
            listeners[self._Event] = nil
        end
    end,
})

---@param event string
---@param callback fun(...: any)
---@param once boolean|nil
---@return EventListener
function EventListener.New(event, callback, once)
    local obj = EventListener.Init({
        _Func = callback,
        _Event = event,
        Once = once and true or false,
    })

    obj._Id = Utils.RandomId(event .. "_")

    obj:Register()

    return obj
end

---@class ChainableEvent : Chainable
---@field Source EventListener
---@param event string
---@param once boolean|nil
---@return ChainableEvent
function EventListener.Chainable(event, once)
    local obj = EventListener.New(event, nil, once)

    local chainable = Chainable.Create(obj)
    obj._Func = function(...)
        return chainable:Begin(...)
    end

    local unregisterFunc = obj.Unregister

    obj.Unregister = function(self)
        unregisterFunc(self)
        chainable:End(true)
    end

    return chainable
end

---@param event string
---@param once boolean|nil
---@return ChainableEvent
function M.ChainOn(event, once)
    return EventListener.Chainable(event, once)
end

---@param event string
---@param callback fun(...: any)
---@param once boolean|nil
---@return EventListener
function M.On(event, callback, once)
    return EventListener.New(event, callback, once)
end

---@param event string
---@param ... any
function M.Trigger(event, ...)
    local eventListeners = M.Listeners(event)

    Log.Debug("Event/Trigger", #eventListeners, event)

    for _, l in ipairs(Utils.Table.Values(eventListeners)) do
        l:Exec(...)
    end
end

---@param event string
---@return EventListener[]
function M.Listeners(event)
    return listeners[event] or {}
end

---@return string[]
function M.Events()
    return Utils.Table.Keys(listeners)
end

return M
