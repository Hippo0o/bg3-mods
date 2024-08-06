---@diagnostic disable: undefined-global

---@type Utils
local Utils = Require("Shared/Utils")

---@type Libs
local Libs = Require("Shared/Libs")

---@class Event
local M = {}

local listeners = {}

---@class EventListener : LibsObject
---@field Id string
---@field Event string
---@field Once boolean
---@field Func fun(...: any)
---@field Exec fun(self: EventListener, ...: any)
---@field Unregister fun(self: EventListener)
---@field New fun(event: string, callback: fun(event: table), once: boolean): EventListener
local EventListener = Libs.Object({
    Id = nil,
    Once = false,
    Event = nil,
    Func = function() end,
    Exec = function(self, ...)
        local args = { ... }

        xpcall(function()
            self.Func(table.unpack(args))
        end, function(err)
            Utils.Log.Error(err)
        end)

        if self.Once then
            self:Unregister()
        end
    end,
    Unregister = function(self)
        local eventListeners = listeners[self.Event]
        for i, listener in ipairs(eventListeners) do
            if listener.Id == self.Id then
                table.remove(eventListeners, i)
            end
        end

        if #eventListeners == 0 then
            listeners[self.Event] = nil
        end
    end,
})

function EventListener.New(event, callback, once)
    local o = EventListener.Init({
        Func = callback,
        Once = once,
        Event = event,
    })
    o.Id = Utils.RandomId(event .. "_")

    if not listeners[event] then
        listeners[event] = {}
    end

    table.insert(listeners[event], o)

    return o
end

function M.On(event, callback, once)
    return EventListener.New(event, callback, once)
end

function M.Trigger(event, ...)
    if listeners[event] then
        Utils.Log.Debug("Handle/Event", #listeners[event], event)
        for _, l in pairs(listeners[event]) do
            l:Exec(...)
        end
    end
end

return M
