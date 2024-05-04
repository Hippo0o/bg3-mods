---@diagnostic disable: undefined-global

---@type Utils
local Utils = Require("Shared/Utils")

---@type Libs
local Libs = Require("Shared/Libs")

---@class GameState
local M = {}

local actions = {}

---@class StateAction : LibsObject
---@field Id string
---@field Mode number
---@field Once boolean
---@field Func fun()
---@field Exec fun(self:StateAction, e:table)
---@field Unregister fun(self:StateAction)
---@field New fun(mode:number, func:fun(), once:boolean):StateAction
local StateAction = Libs.Object({
    Id = nil,
    Mode = nil,
    Once = false,
    Func = function() end,
    Exec = function(self, e)
        xpcall(function()
            self:Func(e)
        end, function(err)
            Utils.Log.Error(err)
        end)

        if self.Once then
            self:Unregister()
        end
    end,
    Unregister = function(self)
        for i, a in pairs(actions) do
            if a.Id == self.Id then
                table.remove(actions, i)
            end
        end
    end,
})

function StateAction.New(mode, func, once)
    local a = StateAction.Init({
        Id = tostring(func):gsub("function: ", ""),
        Mode = mode,
        Func = func,
        Once = once,
    })

    table.insert(actions, a)
    return a
end

---@param func fun()
---@param once boolean
---@return StateAction
function M.RegisterSavingAction(func, once)
    return StateAction.New(1, func, once)
end

---@param func fun()
---@param once boolean
---@return StateAction
function M.RegisterLoadingAction(func, once)
    return StateAction.New(2, func, once)
end

---@param func fun()
---@param once boolean
---@return StateAction
function M.RegisterUnloadingAction(func, once)
    return StateAction.New(3, func, once)
end

local function runAction(mode, e)
    for i, action in ipairs(actions) do
        if action.Mode == mode then
            action:Exec(e)
        end
    end
end

function M.OnSavingActions(e)
    runAction(1, e)
end

function M.OnLoadedActions(e)
    runAction(2, e)
end

function M.OnUnloadActions(e)
    runAction(3, e)
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
