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

function Templates.GetItemBlacklist()
    return UT.DeepClone(itemBlacklist)
end

function Templats.GenerateEnemyLsx()
    local wrap = [[
    <node id="GameObjects">
        <attribute id="LevelName" type="FixedString" value="" />
        <attribute id="Type" type="FixedString" value="character" />
        <attribute id="Flag" type="int32" value="0" />
        <attribute id="IsEquipmentLootable" type="bool" value="False" />
        <attribute id="IsLootable" type="bool" value="False" />
        %s
        <children>
            <node id="Treasures">
                <children>
                    <node id="TreasureItem">
                        <attribute id="Object" type="FixedString" value="Empty" />
                    </node>
                </children>
            </node>
        </children>
    </node>
    ]]

    local all = {}
    local new = {}
    for _, template in pairs(External.Templates.GetEnemies()) do
        local add = {}
        local newId = U.UUID.Random()
        table.insert(add, string.format([[<attribute id="MapKey" type="FixedString" value="%s" />]], newId))
        table.insert(add, string.format([[<attribute id="ParentTemplateId" type="FixedString" value="%s" />]], template.TemplateId))
        table.insert(add, string.format([[<attribute id="Name" type="LSString" value="%s" />]], "TOT_" .. template.Name))

        if template.AiHint ~= nil then
            table.insert(add, string.format([[<attribute id="AiHint" type="guid" value="%s" />]], template.AiHint))
        end
        if template.Archetype ~= nil then
            table.insert(add, string.format([[<attribute id="Archetype" type="FixedString" value="%s" />]], template.Archetype))
        end
        if template.Stats ~= nil then
            table.insert(add, string.format([[<attribute id="Stats" type="FixedString" value="%s" />]], template.Stats))
        end
        if template.Icon ~= nil then
            table.insert(add, string.format([[<attribute id="Icon" type="FixedString" value="%s" />]], template.Icon))
        end
        if template.Equipment ~= nil then
            table.insert(add, string.format([[<attribute id="Equipment" type="FixedString" value="%s" />]], template.Equipment))
        end
        if template.SpellSet ~= nil then
            table.insert(add, string.format([[<attribute id="SpellSet" type="FixedString" value="%s" />]], template.SpellSet))
        end
        if template.LevelOverride ~= nil then
            table.insert(add, string.format([[<attribute id="LevelOverride" type="int32" value="%d" />]], template.LevelOverride))
        end

        table.insert(all, string.format(wrap, table.concat(add, "\n")))

        table.insert(new, { TemplateId = newId, Name = "TOT_" .. template.Name, Info = template.Info, Tier = template.Tier })
    end

    IO.Save("Enemies.lsx", table.concat(all, "\n"))
    IO.SaveJson("Enemies.json", new)
end
