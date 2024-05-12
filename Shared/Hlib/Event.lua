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
---@field private _Func fun(...: any)
---@field UnregisterOnError boolean
---@field Once boolean
---@field Exec fun(self: EventListener, ...: any)
---@field Unregister fun(self: EventListener)
---@field New fun(event: string, callback: fun(event: table), once: boolean|nil): EventListener
local EventListener = Libs.Class({
    _Id = nil,
    _Event = nil,
    _Func = function() end,
    Once = false,
    UnregisterOnError = false,
    Exec = function(self, ...)
        local args = { ... }

        xpcall(function()
            self._Func(table.unpack(args))
        end, function(err)
            if self.UnregisterOnError then
                if Mod.Debug then
                    Utils.Log.Debug(err)
                end

                self:Unregister()
            else
                Utils.Log.Error(err)
            end
        end)

        if self.Once then
            self:Unregister()
        end
    end,
    Unregister = function(self)
        local eventListeners = listeners[self._Event]

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

function EventListener.New(event, callback, once)
    local o = EventListener.Init({
        _Func = callback,
        _Event = event,
        Once = once and true or false,
    })

    o._Id = Utils.RandomId(event .. "_")

    if not listeners[event] then
        listeners[event] = {}
    end

    table.insert(listeners[event], o)

    return o
end

---@param event string
---@param callback fun(...: any)
---@param once boolean|nil
function M.On(event, callback, once)
    return EventListener.New(event, callback, once)
end

---@param event string
---@param ... any
function M.Trigger(event, ...)
    if Mod.Dev then
        Utils.Log.Debug("Event/Trigger", listeners[event] and #listeners[event] or 0, event)
    end

    if listeners[event] then
        for _, l in ipairs(Utils.Table.Values(listeners[event])) do
            l:Exec(...)
        end
    end
end

---@param event string
---@return EventListener[]
function M.Listeners(event)
    return listeners[event] or {}
end

return M
