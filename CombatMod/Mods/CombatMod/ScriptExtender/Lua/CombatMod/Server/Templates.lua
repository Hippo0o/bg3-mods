local enemyTemplates = Require("CombatMod/Server/Templates/Enemies.lua")
local mapTemplates = Require("CombatMod/Server/Templates/Maps.lua")
local scenarioTemplates = Require("CombatMod/Server/Templates/Scenarios.lua")
local unlockTemplates = Require("CombatMod/Server/Templates/Unlocks.lua")
local itemBlacklist = Require("CombatMod/Server/Templates/ItemBlacklist.lua")
local originalLootRates = UT.DeepClone(C.LootRates)

External.File.ExportIfNeeded("Enemies", enemyTemplates)
External.File.ExportIfNeeded("Maps", mapTemplates)
External.File.ExportIfNeeded("Scenarios", scenarioTemplates)
External.File.ExportIfNeeded("LootRates", originalLootRates)
External.File.ExportIfNeeded("ItemFilters", { Names = {}, Mods = {} })

function Templates.ExportEnemies()
    External.File.Export("Enemies", enemyTemplates)
end

function Templates.ExportMaps()
    External.File.Export("Maps", mapTemplates)
end

function Templates.ExportScenarios()
    External.File.Export("Scenarios", scenarioTemplates)
end

function Templates.ExportLootRates()
    External.File.Export("LootRates", originalLootRates)
end

function Templates.GetEnemies()
    return UT.DeepClone(enemyTemplates)
end

function Templates.GetMaps()
    return UT.DeepClone(mapTemplates)
end

function Templates.GetScenarios()
    return UT.DeepClone(scenarioTemplates)
end

function Templates.GetUnlocks()
    return UT.DeepClone(unlockTemplates)
end

function Templates.GetItemFilters()
    return UT.DeepClone({ Names = itemBlacklist, Mods = {} })
end
