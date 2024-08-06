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

Require("CombatMod/Server/Scenario")
Require("CombatMod/Server/Enemy")
Require("CombatMod/Server/Map")
Require("CombatMod/Server/Item")
Require("CombatMod/Server/StoryBypass")
Require("CombatMod/Server/GameMode")
Require("CombatMod/Server/NetEvents")
Require("CombatMod/Server/Unlock")

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Events                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

GameState.OnSave(function()
    PersistentVars.Scenario = S
    PersistentVars.Config = Config

    for obj, _ in pairs(PersistentVars.SpawnedEnemies) do
        if not Ext.Entity.Get(obj) then
            L.Debug("Cleaning up SpawnedEnemies", obj)
            PersistentVars.SpawnedEnemies[obj] = nil
        end
    end

    for obj, _ in pairs(PersistentVars.SpawnedItems) do
        if
            Item.IsOwned(obj) or Osi.IsItem(obj) ~= 1 -- was used
        then
            L.Debug("Cleaning up SpawnedItems", obj)
            PersistentVars.SpawnedItems[obj] = nil
        end
    end
end)

GameState.OnLoad(function()
    if U.Equals(PersistentVars.Scenario, {}) then
        PersistentVars.Scenario = nil
    end

    S = PersistentVars.Scenario
    if S ~= nil then
        Scenario.RestoreFromState(S)
    end
end, true)

GameState.OnLoad(function()
    if PersistentVars.GUIOpen then
        Defer(1000, function()
            Net.Send("OpenGUI")
        end)
    end
end)

GameState.OnUnload(function()
    if PersistentVars then
        PersistentVars.Scenario = S
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
