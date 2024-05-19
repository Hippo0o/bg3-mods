---@type Mod
Mod = Require("Hlib/Mod")
Mod.Debug = true
Mod.Dev = false
Mod.EnableRCE = true
Mod.Prefix = "Endless Battle"

---@type Utils
local Utils = Require("Hlib/Utils")

U = Utils
UT = Utils.Table
UE = Utils.Entity
US = Utils.String
L = Utils.Log

---@type IO
IO = Require("Hlib/IO")

---@type Scenario|nil
S = nil

---@type Constants
local Constants = Require("Hlib/Constants")

---@class MyConstants : Constants
C = {
    ModUUID = Mod.UUID,
    EnemyFaction = "64321d50-d516-b1b2-cfac-2eb773de1ff6",
    NeutralFaction = "cfb709b3-220f-9682-bcfb-6f0d8837462e", -- NPC Neutral
    ItemRarity = {
        "Common",
        "Uncommon",
        "Rare",
        "VeryRare",
        "Legendary",
    },
    EnemyTier = {
        "low",
        "mid",
        "high",
        "ultra",
        "epic",
        "legendary",
    },
    RoguelikeScenario = "roguelike",
}
C = UT.Merge(Constants, C)

Mod.PersistentVarsTemplate = {
    Active = nil,
    RogueModeActive = nil,
    SpawnedEnemies = {},
    SpawnedItems = {},
    Scenario = S,
    RogueScore = 0,
    GUIOpen = false,
}

Mod.PrepareModVars("State", true, Mod.PersistentVarsTemplate)

---@type GameState
GameState = Require("Hlib/GameState")

---@type Async
Async = Require("Hlib/Async")
WaitFor = Async.WaitFor
RetryUntil = Async.RetryUntil
Schedule = Async.Schedule
Defer = Async.Defer

---@type Libs
Libs = Require("Hlib/Libs")

---@type Net
Net = Require("Hlib/Net")

---@type Event
Event = Require("Hlib/Event")

---@type Localization
Localization = Require("Hlib/Localization")
__ = Localization.Localize

if Ext.IsClient() then
    L.Dump(Mod.Vars)
    Defer(1000, function()
        L.Dump(Mod.Vars)
    end)
end

function Sync()
    L.Dump(Mod.Vars)
    Ext.Vars.SyncModVariables(Mod.UUID)
end
