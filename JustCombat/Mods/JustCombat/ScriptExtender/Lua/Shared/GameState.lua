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
---@field New fun(mode:number, callback:fun(), once:boolean):StateAction
local StateAction = Libs.Object({
    Id = nil,
    Mode = nil,
    Once = false,
    Func = function() end,
    Exec = function(self, e)
        xpcall(function()
            self.Func(e)
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

function StateAction.New(mode, callback, once)
    local o = StateAction.Init({
        Mode = mode,
        Func = callback,
        Once = once,
    })

    o.Id = tostring(o)

    table.insert(actions, o)

    return o
end

local modeSave = 1
local modeLoad = 2
local modeUnload = 3

---@param callback fun()
---@param once boolean
---@return StateAction
function M.OnSaving(callback, once)
    return StateAction.New(modeSave, callback, once)
end

---@param callback fun()
---@param once boolean
---@return StateAction
function M.OnLoading(callback, once)
    return StateAction.New(modeLoad, callback, once)
end

---@param callback fun()
---@param once boolean
---@return StateAction
function M.OnUnloading(callback, once)
    return StateAction.New(modeUnload, callback, once)
end

local function runAction(mode, e)
    for i, action in ipairs(actions) do
        if action.Mode == mode then
            action:Exec(e)
        end
    end
end

Ext.Events.GameStateChanged:Subscribe(function(e)
    if e.FromState == "Sync" and e.ToState == "Running" then
        Utils.Log.Info("Game Loaded.")
        runAction(modeLoad, e)
    elseif e.FromState == "Running" and e.ToState == "Save" then
        Utils.Log.Info("Saving started.")
        runAction(modeSave, e)
    elseif e.FromState == "Save" and e.ToState == "Running" then
        Utils.Log.Info("Saving finished.")
        runAction(modeLoad, e)
    elseif e.FromState == "Running" and e.ToState == "UnloadLevel" then
        Utils.Log.Info("Level unloading.")
        runAction(modeUnload, e)
    elseif e.FromState == "UnloadSession" and e.ToState == "LoadSession" then
        Utils.Log.Info("Loading another save.")
        runAction(modeUnload, e)
    end
end)

return M
