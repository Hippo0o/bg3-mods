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
    ScenarioHelper = {
        TemplateId = "b4f5635b-2382-4fb2-ad0d-5be8b363e847",
        Handle = "h09f52fcdg7db3g44ddg91b1gb2b4d69ac32b",
        Faction = "4be9261a-e481-8d9d-3528-f36956a19b17",
    },
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
            Common = 40,
            Uncommon = 20,
            Rare = 10,
            VeryRare = 5,
            Legendary = 2,
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
