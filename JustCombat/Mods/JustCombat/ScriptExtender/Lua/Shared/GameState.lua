---@diagnostic disable: undefined-global

---@type Utils
local Utils = Require("Shared/Utils")

---@type Event
local Event = Require("Shared/Event")

local modeSave = "GameStateSave"
local modeLoad = "GameStateLoad"
local modeUnload = "GameStateUnload"

Ext.Events.GameStateChanged:Subscribe(function(e)
    if e.FromState == "Sync" and e.ToState == "Running" then
        Utils.Log.Info("Game Loaded.")
        Event.Trigger(modeLoad, e)
    elseif e.FromState == "Running" and e.ToState == "Save" then
        Utils.Log.Info("Saving started.")
        Event.Trigger(modeSave, e)
    elseif e.FromState == "Save" and e.ToState == "Running" then
        Utils.Log.Info("Saving finished.")
        Event.Trigger(modeLoad, e)
    elseif e.FromState == "Running" and e.ToState == "UnloadLevel" then
        Utils.Log.Info("Level unloading.")
        Event.Trigger(modeUnload, e)
    elseif e.FromState == "UnloadSession" and e.ToState == "LoadSession" then
        Utils.Log.Info("Loading another save.")
        Event.Trigger(modeUnload, e)
    end
end)

---@class GameState
local M = {}

---@param callback fun()
---@param once boolean
---@return EventListener
function M.OnSaving(callback, once)
    return Event.On(modeSave, callback, once)
end

---@param callback fun()
---@param once boolean
---@return EventListener
function M.OnLoading(callback, once)
    return Event.On(modeLoad, callback, once)
end

---@param callback fun()
---@param once boolean
---@return EventListener
function M.OnUnloading(callback, once)
    return Event.On(modeUnload, callback, once)
end

return M
