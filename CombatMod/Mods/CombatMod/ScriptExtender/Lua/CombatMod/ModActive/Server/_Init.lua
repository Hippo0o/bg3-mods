Scenario = {}
Enemy = {}
Map = {}
Item = {}
GameMode = {}
StoryBypass = {}
Unlock = {}
Workaround = {}

function LogRandom(key, value, max)
    if not max then
        max = 10
    end

    if not PersistentVars.RandomLog[key] then
        PersistentVars.RandomLog[key] = {}
    end

    table.insert(PersistentVars.RandomLog[key], value)
    if #PersistentVars.RandomLog[key] > max then
        table.remove(PersistentVars.RandomLog[key], 1)
    end
end

GameState.OnSave(function()
    PersistentVars.Config = Config

    for obj, _ in pairs(PersistentVars.SpawnedEnemies) do
        if not Ext.Entity.Get(obj) then
            L.Debug("Cleaning up SpawnedEnemies", obj)
            PersistentVars.SpawnedEnemies[obj] = nil
        end
    end

    for obj, _ in pairs(PersistentVars.SpawnedItems) do
        if
            GU.Object.IsOwned(obj) or Osi.IsItem(obj) ~= 1 -- was used
        then
            L.Debug("Cleaning up SpawnedItems", obj)
            PersistentVars.SpawnedItems[obj] = nil
        end
    end
end)

GameState.OnLoad(function()
    Enemy.RestoreFromSave(PersistentVars.SpawnedEnemies)

    if U.Equals(PersistentVars.Scenario, {}) then
        PersistentVars.Scenario = nil
    end

    if PersistentVars.Scenario ~= nil then
        Scenario.RestoreFromSave(PersistentVars.Scenario)
    end
end, true)

Require("CombatMod/ModActive/Server/Scenario")
Require("CombatMod/ModActive/Server/Enemy")
Require("CombatMod/ModActive/Server/Map")
Require("CombatMod/ModActive/Server/Item")
Require("CombatMod/ModActive/Server/StoryBypass")
Require("CombatMod/ModActive/Server/GameMode")
Require("CombatMod/ModActive/Server/NetEvents")
Require("CombatMod/ModActive/Server/Unlock")
Require("CombatMod/ModActive/Server/Workaround")

-- collect stats
Event.On("ScenarioEnded", function(scenario)
    table.insert(PersistentVars.History, {
        HardMode = PersistentVars.HardMode,
        RogueScore = PersistentVars.RogueScore,
        Currency = PersistentVars.Currency,
        Scenario = {
            Enemies = table.size(scenario.KilledEnemies),
            Rounds = scenario.Round - 1,
            Map = scenario.Map.Name,
        },
    })
end)
