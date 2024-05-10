---@type Utils
local Utils = Require("Shared/Utils")

---@type Event
local Event = Require("Shared/Event")

---@class GameState
local M = {}

M.EventSave = "GameStateSave"
M.EventLoad = "GameStateLoad"
M.EventLoadSession = "GameStateLoadSession"
M.EventUnload = "GameStateUnload"
M.EventUnloadSession = "GameStateUnloadSession"

Ext.Events.GameStateChanged:Subscribe(function(e)
    if e.FromState == "LoadSession" and e.ToState == "LoadLevel" then
        Utils.Log.Info("Session Loaded.")
        Event.Trigger(M.EventLoadSession, e)
    elseif e.FromState == "Sync" and e.ToState == "Running" then
        Utils.Log.Info("Game Loaded.")
        Event.Trigger(M.EventLoad, e)
    elseif e.FromState == "Running" and e.ToState == "Save" then
        Utils.Log.Info("Saving started.")
        Event.Trigger(M.EventSave, e)
    elseif e.FromState == "Save" and e.ToState == "Running" then
        Utils.Log.Info("Saving finished.")
        Event.Trigger(M.EventLoad, e)
    elseif e.FromState == "Running" and e.ToState == "UnloadLevel" then
        Utils.Log.Info("Level unloading.")
        Event.Trigger(M.EventUnload, e)
    elseif e.FromState == "UnloadSession" and e.ToState == "LoadSession" then
        Utils.Log.Info("Loading another save.")
        Event.Trigger(M.EventUnloadSession, e)
    end
end)

---@param callback fun()
---@param once boolean|nil
---@return EventListener
function M.OnSave(callback, once)
    return Event.On(M.EventSave, callback, once)
end

---@param callback fun()
---@param once boolean|nil
---@return EventListener
function M.OnLoad(callback, once)
    return Event.On(M.EventLoad, callback, once)
end

---@param callback fun()
---@param once boolean|nil
---@return EventListener
function M.OnUnload(callback, once)
    return Event.On(M.EventUnload, callback, once)
end

---@param callback fun()
---@param once boolean|nil
---@return EventListener
function M.OnLoadSession(callback, once)
    return Event.On(M.EventLoadSession, callback, once)
end

---@param callback fun()
---@param once boolean|nil
---@return EventListener
function M.OnUnloadSession(callback, once)
    return Event.On(M.EventUnloadSession, callback, once)
end

return M
