---@type Mod
local Mod = Require("Hlib/Mod")

---@type Event
local Event = Require("Hlib/Event")

---@type GameState
local GameState = Require("Hlib/GameState")

---@class ModEvent
local M = {}

---@param event string
---@vararg any
function M.Trigger(event, ...)
    Ext.ModEvents[Mod.TableKey][event]:Throw(...)
end

---@param event string
function M.Register(event)
    Ext.RegisterModEvent(Mod.TableKey, event)

    Event.On(event, function(...)
        M.Trigger(event, ...)
    end)
end

---@param mod string
---@param event string
---@return string
function M.EventName(mod, event)
    return mod .. event
end

---@param mod string
---@param events string|string[]
function M.Subscribe(mod, events)
    if GameState.InitState < GameState.InitStateEnum.SessionLoaded then
        GameState.OnLoadSession(function()
            M.Subscribe(mod, events)
        end, true)

        return
    end

    if type(events) == "string" then
        events = { events }
    end

    if not events then
        events = {}
        for event, _ in pairs(Ext.ModEvents[mod]) do
            table.insert(events, event)
        end
    end

    for _, event in ipairs(events) do
        Ext.ModEvents[mod][event]:Subscribe(function(...)
            Event.Trigger(M.EventName(mod, event), ...)
        end)
    end
end

return M
