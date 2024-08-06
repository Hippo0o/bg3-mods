Require("CombatMod/Shared")

Mod.PersistentVarsTemplate = {
    Asked = false,
    Active = false,
    RogueModeActive = false,
    SpawnedEnemies = {},
    SpawnedItems = {},
    Scenario = {},
    Config = {},
    LastScenario = nil,
    RogueScore = 0,
    HardMode = false, -- applies additional difficulty to the game
    GUIOpen = false,
    History = {},
    RandomLog = { -- log last random values to prevent repeating the same
        Maps = {},
        Items = {},
    },
    LootFilter = {
        CombatObject = UT.Map(C.ItemRarity, function(v, k)
            return true, v
        end),
        Object = UT.Map(C.ItemRarity, function(v, k)
            return true, v
        end),
        Armor = UT.Map(C.ItemRarity, function(v, k)
            return v ~= "Common", v
        end),
        Weapon = UT.Map(C.ItemRarity, function(v, k)
            return v ~= "Common", v
        end),
    },
    Currency = 0,
    RegionsCleared = {},
    Unlocked = {
        ExpMultiplier = false,
        LootMultiplier = false,
        CurrencyMultiplier = false,
        RogueScoreMultiplier = false,
    },
    Unlocks = {},
}

DefaultConfig = {
    BypassStory = true, -- skip dialogues, combat and interactions that aren't related to a scenario
    LootIncludesCampSlot = false, -- include camp clothes in item lists
    Debug = false,
    RandomizeSpawnOffset = 3,
    ExpMultiplier = 3,
    SpawnItemsAtPlayer = false,
    TurnOffNotifications = false,
    ClearAllEntities = true,
    MulitplayerRestrictUnlocks = false,
    AutoTeleport = 30,
}
Config = UT.DeepClone(DefaultConfig)

External = {}
Templates = {}

Require("CombatMod/Server/External")
Require("CombatMod/Server/Templates")

External.LoadConfig()
External.File.ExportIfNeeded("Config", Config)

External.LoadLootRates()

Intro = {}
Player = {}
Commands = {}

Require("CombatMod/Server/Intro")
Require("CombatMod/Server/Player")
Require("CombatMod/Server/Commands")

local isActive = false
function IsActive()
    return isActive
end

local function init()
    if isActive then
        return
    end
    isActive = true

    Require("CombatMod/ModActive/Overwrites")

    Require("CombatMod/ModActive/Server/_Init")

    Event.Trigger(GameState.EventLoad)

    L.Info(L.RainbowText(Mod.Prefix .. " is now active. Have fun!"))
end

Event.On("ModActive", function()
    if not PersistentVars.Active then
        Player.Notify(__("%s is now active.", Mod.Prefix), true)
    end

    PersistentVars.Active = true

    init()
end, true)

Event.On("ModActive", function()
    -- client only listens once for this event
    Net.Send("ModInactive")
end)

GameState.OnLoad(function()
    External.LoadConfig()

    PersistentVars.Asked = PersistentVars.Active
    if PersistentVars.Asked == false then
        Intro.AskOnboarding()
    end

    if not U.Equals(PersistentVars.Config, {}) then
        External.ApplyConfig(UT.Filter(PersistentVars.Config, function(v, k)
            return k ~= "Dev" and k ~= "Debug"
        end, true))
    end
end, true)

GameState.OnLoad(function()
    if PersistentVars.Active then
        Event.Trigger("ModActive")
    end
end)
