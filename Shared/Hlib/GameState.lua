---@type Mod
local Mod = Require("Hlib/Mod")

---@type Utils
local Utils = Require("Hlib/Utils")

---@type Event
local Event = Require("Hlib/Event")

---@class GameState
local M = {}

M.EventSave = "GameStateSave"
M.EventLoad = "GameStateLoad"
M.EventLoadSession = "GameStateLoadSession"
M.EventUnload = "GameStateUnload"
M.EventUnloadLevel = "GameStateUnloadLevel"
M.EventUnloadSession = "GameStateUnloadSession"

Ext.Events.GameStateChanged:Subscribe(function(e)
    if Mod.Dev then
        Utils.Log.Debug("GameState", e.FromState, e.ToState)
    end
    if e.FromState == "LoadSession" and e.ToState == "LoadLevel" then
        Event.Trigger(M.EventLoadSession, e)
    elseif (e.FromState == "Sync" or e.FromState == "PrepareRunning") and e.ToState == "Running" then
        Event.Trigger(M.EventLoad, e)
    elseif e.FromState == "Running" and e.ToState == "Save" then
        Event.Trigger(M.EventSave, e)
    elseif e.FromState == "Save" and e.ToState == "Running" then
        Event.Trigger(M.EventLoad, e)
    elseif (e.FromState == "Running" or e.FromState == "Idle") and e.ToState == "UnloadLevel" then
        Event.Trigger(M.EventUnload, e)
    elseif e.FromState == "UnloadSession" and e.ToState == "LoadSession" then
        -- only on server between bg3se::ExtensionStateBase::LuaResetInternal(): LUA VM reset
        Event.Trigger(M.EventUnloadSession, e)
    elseif e.FromState == "UnloadLevel" and (e.ToState == "LoadLevel" or e.ToState == "Idle") then
        Event.Trigger(M.EventUnloadLevel, e)
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
