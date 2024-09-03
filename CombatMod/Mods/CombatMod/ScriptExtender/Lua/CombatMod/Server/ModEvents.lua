ModEvent.Register("ScenarioCombatStarted")
ModEvent.Register("ScenarioRoundStarted")
ModEvent.Register("ScenarioRoundSpawned")
ModEvent.Register("ScenarioEnemySpawned")
ModEvent.Register("ScenarioEnemyKilled")
ModEvent.Register("ScenarioRestored")
ModEvent.Register("ScenarioStarted")
ModEvent.Register("ScenarioEnded")
ModEvent.Register("ScenarioStopped")
ModEvent.Register("ScenarioMapEntered")
ModEvent.Register("ScenarioTeleporting")
ModEvent.Register("ScenarioTeleported")
ModEvent.Register("ScenarioPerfectClear")
ModEvent.Register("MapTeleported")

-- Example usage:
-- Ext.ModEvents.ToT.ScenarioCombatStarted:Subscribe(function(scenario) ---@param scenario Scenario
--
-- end)
