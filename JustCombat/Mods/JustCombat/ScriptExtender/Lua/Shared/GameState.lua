---@diagnostic disable: undefined-global

---@type Utils
local Utils = Require("Shared/Utils")

---@class GameState
local M = {}

local savingActions = {}
---@param func fun()
function M.RegisterSavingAction(func, once)
    table.insert(savingActions, { func, once })
end

local loadingActions = {}
---@param func fun()
function M.RegisterLoadingAction(func, once)
    table.insert(loadingActions, { func, once })
end

local unloadingActions = {}
---@param func fun()
function M.RegisterUnloadingAction(func, once)
    table.insert(unloadingActions, { func, once })
end

function M.OnSavingActions(e)
    for i, action in ipairs(savingActions) do
        action[1](e)
        if action[2] then
            table.remove(savingActions, i)
        end
    end
end

function M.OnLoadedActions(e)
    for i, action in ipairs(loadingActions) do
        action[1](e)
        if action[2] then
            table.remove(loadingActions, i)
        end
    end
end

function M.OnUnloadActions(e)
    for i, action in ipairs(unloadingActions) do
        action[1](e)
        if action[2] then
            table.remove(unloadingActions, i)
        end
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
