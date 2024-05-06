---@type Mod
local Mod = Require("Shared/Mod")
Mod.ModPrefix = "JustCombat"
Mod.ModUUID = "e1fb0ff5-dd5e-471d-b2c4-c19c288fa5e7"

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
