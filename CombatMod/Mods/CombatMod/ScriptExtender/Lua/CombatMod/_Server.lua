Require("CombatMod/Shared")

Mod.PersistentVarsTemplate = {
    Asked = false,
    Active = false,
    RogueModeActive = false,
    RogueScenario = "",
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
        CombatObject = table.map(C.ItemRarity, function(v, k)
            return true, v
        end),
        Object = table.map(C.ItemRarity, function(v, k)
            return true, v
        end),
        Armor = table.map(C.ItemRarity, function(v, k)
            return v ~= "Common", v
        end),
        Weapon = table.map(C.ItemRarity, function(v, k)
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
    GroupDistantEnemies = true,
    TurnOffNotifications = false,
    ClearAllEntities = true,
    AutoResurrect = true,
    MulitplayerRestrictUnlocks = false,
    AutoTeleport = 30,
    ScalingModifier = 30,
}
Config = table.deepclone(DefaultConfig)

External = {}
Templates = {}

Require("CombatMod/Server/External")

External.LoadConfig()
External.File.ExportIfNeeded("Config", Config)

External.LoadLootRates()

Intro = {}
Player = {}
Commands = {}

Require("CombatMod/Server/Intro")
Require("CombatMod/Server/Player")
Require("CombatMod/Server/Commands")
Require("CombatMod/Server/ModEvents")

GameState.OnLoad(function()
    External.LoadConfig()

    if PersistentVars.Asked == false then
        Intro.AskOnboarding()
    end
    PersistentVars.Asked = PersistentVars.Active

    if not eq(PersistentVars.Config, {}) then
        External.ApplyConfig(table.filter(PersistentVars.Config, function(v, k)
            return k ~= "Dev" and k ~= "Debug"
        end, true))
    end
end, true)

ModEvent.Register("ModInit")

local isActive = false
function IsActive()
    return isActive
end

local function init()
    if isActive then
        return
    end
    isActive = true

    Require("CombatMod/ModActive/Server/_Init")

    Event.Trigger(GameState.EventLoad)

    L.Info(L.RainbowText(Mod.Prefix .. " is now active. Have fun!"))

    Event.Trigger("ModInit")
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
    Net.Send("ModActive")
end)

GameState.OnLoad(function()
    L.Debug("Check if mod is active", PersistentVars.Active)
    if PersistentVars.Active then
        Event.Trigger("ModActive")
    end
end)

Require("CombatMod/Overwrites")
