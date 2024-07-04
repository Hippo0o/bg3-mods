Scenario = {}
Enemy = {}
Map = {}
Item = {}
GameMode = {}
StoryBypass = {}
Unlock = {}

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

Require("CombatMod/Server/ModActive/Scenario")
Require("CombatMod/Server/ModActive/Enemy")
Require("CombatMod/Server/ModActive/Map")
Require("CombatMod/Server/ModActive/Item")
Require("CombatMod/Server/ModActive/StoryBypass")
Require("CombatMod/Server/ModActive/GameMode")
Require("CombatMod/Server/ModActive/NetEvents")
Require("CombatMod/Server/ModActive/Unlock")

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Events                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

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
    if PersistentVars.GUIOpen then
        Defer(1000, function()
            Net.Send("OpenGUI")
        end)
    end
end)

-- collect stats
Event.On("ScenarioEnded", function(scenario)
    table.insert(PersistentVars.History, {
        HardMode = PersistentVars.HardMode,
        RogueScore = PersistentVars.RogueScore,
        Currency = PersistentVars.Currency,
        Scenario = {
            Enemies = UT.Size(scenario.KilledEnemies),
            Rounds = scenario.Round - 1,
            Map = scenario.Map.Name,
        },
    })
end)
