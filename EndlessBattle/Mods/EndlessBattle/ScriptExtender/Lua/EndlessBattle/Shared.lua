---@type Mod
Mod = Require("Hlib/Mod")
Mod.Debug = true
Mod.Dev = true
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
C = Require("Hlib/Constants")

UT.Merge(C, {
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
})

Mod.PersistentVarsTemplate = {
    Active = false,
    SpawnedEnemies = {},
    SpawnedItems = {},
    Scenario = S,
    RogueScore = 0,
}

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