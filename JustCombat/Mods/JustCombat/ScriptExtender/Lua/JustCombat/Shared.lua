---@type Mod
Mod = Require("Shared/Mod")
Mod.ModPrefix = "JustCombat"

---@type Utils
local Utils = Require("Shared/Utils")

U = Utils
UT = Utils.Table
UE = Utils.Entity
US = Utils.String
L = Utils.Log

---@type Scenario|nil
S = nil

---@type Constants
C = Require("Shared/Constants")

UT.Merge(C, {
    NetChannel = "JC_NET",
    ModUUID = Mod.ModUUID,
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
})

Mod.PersistentVarsTemplate = {
    SpawnedEnemies = {},
    SpawnedItems = {},
    Scenario = S,
}

---@type GameState
GameState = Require("Shared/GameState")

---@type Async
Async = Require("Shared/Async")
WaitFor = Async.WaitFor
RetryFor = Async.RetryFor
Schedule = Async.Schedule
Defer = Async.Defer

---@type Libs
Libs = Require("Shared/Libs")

---@type Net
Net = Require("Shared/Net")

---@type Event
Event = Require("Shared/Event")

