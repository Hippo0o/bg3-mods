---@type Mod
local Mod = Require("Hlib/Mod")

---@type Utils
local Utils = Require("Hlib/Utils")

---@type Log
local Log = Require("Hlib/Log")

---@type Event
local Event = Require("Hlib/Event")

---@class GameState
local M = {}

M.EventSave = "_GameStateSave"
M.EventLoad = "_GameStateLoad"
M.EventLoadSession = "_GameStateLoadSession"
M.EventUnload = "_GameStateUnload"
M.EventUnloadLevel = "_GameStateUnloadLevel"
M.EventUnloadSession = "_GameStateUnloadSession"

Ext.Events.GameStateChanged:Subscribe(function(e)
    if Mod.Dev then
        Log.Debug("GameState", e.FromState, e.ToState)
    end
    if e.FromState == "LoadSession" and e.ToState == "LoadLevel" then
        Event.Trigger(M.EventLoadSession)
    elseif (e.FromState == "Sync" or e.FromState == "PrepareRunning") and e.ToState == "Running" then
        Event.Trigger(M.EventLoad)
    elseif e.FromState == "Running" and e.ToState == "Save" then
        Event.Trigger(M.EventSave)
    elseif e.FromState == "Save" and e.ToState == "Running" then
        Event.Trigger(M.EventLoad)
    elseif (e.FromState == "Running" or e.FromState == "Idle") and e.ToState == "UnloadLevel" then
        Event.Trigger(M.EventUnload)
    elseif e.FromState == "UnloadSession" and e.ToState == "LoadSession" then
        Event.Trigger(M.EventUnloadSession)
    elseif e.FromState == "UnloadLevel" and (e.ToState == "LoadLevel" or e.ToState == "Idle") then
        Event.Trigger(M.EventUnloadLevel)
    end
end)

Ext.Events.ResetCompleted:Subscribe(function()
    Event.Trigger(M.EventLoadSession)
    Event.Trigger(M.EventLoad)
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
-- same time as Ext.Events.SessionLoaded
function M.OnLoadSession(callback, once)
    return Event.On(M.EventLoadSession, callback, once)
end

---@param callback fun()
---@param once boolean|nil
---@return EventListener
function M.OnUnloadLevel(callback, once)
    return Event.On(M.EventUnloadLevel, callback, once)
end

if Ext.IsServer() then
    ---@param callback fun()
    ---@param once boolean|nil
    ---@return EventListener
    function M.OnUnloadSession(callback, once)
        return Event.On(M.EventUnloadSession, callback, once)
    end
end

return M
