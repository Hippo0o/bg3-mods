---@diagnostic disable: undefined-global

---@type Utils
local Utils = Require("Shared/Utils")

---@class GameState
local M = {}

local savingActions = {}
---@param func fun()
function M.RegisterSavingAction(func)
    table.insert(savingActions, func)
end

local loadingActions = {}
---@param func fun()
function M.RegisterLoadingAction(func)
    table.insert(loadingActions, func)
end

local unloadingActions = {}
---@param func fun()
function M.RegisterUnloadingAction(func)
    table.insert(unloadingActions, func)
end

function M.OnSavingActions(e)
    for _, action in ipairs(savingActions) do
        action(e)
    end
end

function M.OnLoadedActions(e)
    for _, action in ipairs(loadingActions) do
        action(e)
    end
end

function M.OnUnloadActions(e)
    for _, action in ipairs(unloadingActions) do
        action(e)
    end
end

Ext.Events.GameStateChanged:Subscribe(function(e)
    if e.FromState == "Sync" and e.ToState == "Running" then
        Utils.Log.Info("Game Loaded.")
        M.OnLoadedActions(e)
    elseif e.FromState == "Running" and e.ToState == "Save" then
        Utils.Log.Info("Saving started.")
        M.OnSavingActions(e)
    elseif e.FromState == "Save" and e.ToState == "Running" then
        Utils.Log.Info("Saving finished.")
        M.OnLoadedActions(e)
    elseif e.FromState == "Running" and e.ToState == "UnloadLevel" then
        Utils.Log.Info("Level unloading.")
        M.OnUnloadActions(e)
    elseif e.FromState == "UnloadSession" and e.ToState == "LoadSession" then
        Utils.Log.Info("Loading another save.")
        M.OnUnloadActions(e)
    end
end)

return M
