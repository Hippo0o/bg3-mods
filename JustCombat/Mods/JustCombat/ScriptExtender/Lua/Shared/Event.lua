---@type Utils
local Utils = Require("Shared/Utils")

---@type Libs
local Libs = Require("Shared/Libs")

---@class Event
local M = {}

local listeners = {}

---@class EventListener : LibsObject
---@field private Id string
---@field private Event string
---@field private Func fun(...: any)
---@field Once boolean
---@field Exec fun(self: EventListener, ...: any)
---@field Unregister fun(self: EventListener)
---@field New fun(event: string, callback: fun(event: table), once: boolean|nil): EventListener
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
        for i = #eventListeners, 1, -1 do
            if eventListeners[i].Id == self.Id then
                Utils.Log.Debug("Event/Unregister", self.Event, self.Id)
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
        Once = once and true or false,
        Event = event,
    })
    o.Id = Utils.RandomId(event .. "_")

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

function M.Trigger(event, ...)
    Utils.Log.Debug("Event/Trigger", listeners[event] and #listeners[event] or 0, event)
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
