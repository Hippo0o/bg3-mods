---@type Mod
Mod = Require("Hlib/Mod")
Mod.Debug = false
Mod.Dev = false
Mod.EnableRCE = true
Mod.Prefix = "Trials of Tav"
Mod.TableKey = "ToT"

---@type Utils
local Utils = Require("Hlib/Utils")

---@type Log
local Log = Require("Hlib/Log")

---@type GameUtils
local GameUtils = Require("Hlib/GameUtils")

U = Utils
L = Log
UT = Utils.Table
US = Utils.String
GU = GameUtils
GE = GameUtils.Entity
GC = GameUtils.Character

---@type IO
IO = Require("Hlib/IO")

---@type Constants
local Constants = Require("Hlib/Constants")

---@class MyConstants : Constants
C = {
    ModUUID = Mod.UUID,
    EnemyFaction = "64321d50-d516-b1b2-cfac-2eb773de1ff6",
    NeutralFaction = "cfb709b3-220f-9682-bcfb-6f0d8837462e", -- NPC Neutral
    ShadowCurseTag = "b47643e0-583c-4808-b108-f6d3b605b0a9",
    CompanionFaction = "4abec10d-c2d1-a505-a09a-719c83999847",
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
            Uncommon = 25,
            Rare = 10,
            VeryRare = 5,
            Legendary = 1,
        },
        Armor = {
            Common = 30, -- has only junk or invalid items
            Uncommon = 65,
            Rare = 20,
            VeryRare = 10,
            Legendary = 2,
        },
        Weapons = {
            Common = 30, -- has only junk or invalid items
            Uncommon = 65,
            Rare = 20,
            VeryRare = 10,
            Legendary = 2,
        },
    },
}
C = UT.Merge(Constants, C)

---@type GameState
GameState = Require("Hlib/GameState")

---@type Async
Async = Require("Hlib/Async")
WaitUntil = Async.WaitUntil
RetryUntil = Async.RetryUntil
Schedule = Async.Schedule
Defer = Async.Defer
Debounce = Async.Debounce

---@type Libs
Libs = Require("Hlib/Libs")

---@type Net
Net = Require("Hlib/Net")

---@type Event
Event = Require("Hlib/Event")

---@type Localization
Localization = Require("Hlib/Localization")
__ = Localization.Localize
