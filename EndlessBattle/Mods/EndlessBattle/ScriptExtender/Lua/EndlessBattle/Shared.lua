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
    RoguelikeScenario = "Roguelike",
    LootRates = {
        Objects = {
            Common = 60,
            Uncommon = 30,
            Rare = 20,
            VeryRare = 5,
            Legendary = 0,
        },
        Armor = {
            Common = 60,
            Uncommon = 30,
            Rare = 20,
            VeryRare = 5,
            Legendary = 1,
        },
        Weapons = {
            Common = 60,
            Uncommon = 30,
            Rare = 20,
            VeryRare = 5,
            Legendary = 1,
        },
    },
}
C = UT.Merge(Constants, C)

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
