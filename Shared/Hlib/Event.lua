---@type Utils
local Utils = Require("Hlib/Utils")

---@type Libs
local Libs = Require("Hlib/Libs")

---@class Event
local M = {}

local listeners = {}

-- exposed
---@class EventListener : LibsClass
---@field private _Id string
---@field private _Event string
---@field private _Func fun( ...: any)
---@field Once boolean
---@field Exec fun(self: EventListener, ...: any)
---@field Unregister fun(self: EventListener)
local EventListener = Libs.Class({
    _Id = nil,
    _Event = nil,
    _Func = function() end,
    Once = false,
    Exec = function(self, ...)
        local args = { ... }

        xpcall(function()
            self._Func(table.unpack(args))
        end, function(err)
            Utils.Log.Error(err)
        end)

        if self.Once then
            self:Unregister()
        end
    end,
    Unregister = function(self)
        local eventListeners = listeners[self._Event]
        if not eventListeners then
            return
        end

        for i = #eventListeners, 1, -1 do
            if eventListeners[i]._Id == self._Id then
                if Mod.Dev then
                    Utils.Log.Debug("Event/Unregister", self._Event, self._Id)
                end
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

    if not listeners[event] then
        listeners[event] = {}
    end

    table.insert(listeners[event], obj)

    return obj
end

---@class ChainableEvent : LibsChainable
---@field Source EventListener
---@field After fun(func: fun(self: EventListener, ...: any): any): LibsChainable
---@param event string
---@param once boolean|nil
---@return ChainableEvent
function EventListener.Chainable(event, once)
    local obj = EventListener.New(event, nil, once)

    local chainable = Libs.Chainable(obj)

    obj._Func = function(...)
        chainable.Begin(obj, ...)
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

    if Mod.Dev then
        Utils.Log.Debug("Event/Trigger", #eventListeners, event)
    end

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
