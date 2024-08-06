-- Ext.Utils.Include(nil, "Mods/CombatMod/ScriptExtender/Lua/Generate.lua")

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
local map = {}

local file = Mods.ToT.IO.LoadJson("EnemiesMap.json")
for _, e in pairs(file) do
    map[e.Name] = e.TemplateId
end

for _, template in pairs(Mods.ToT.External.Templates.GetEnemies()) do
    local add = {}
    local newId = map[template.Name] or Mods.ToT.UUID.Random()
    if map[template.Name] == nil then
        Mods.ToT.L.Error(map[template.Name], newId)
    end

    table.insert(add, string.format([[<attribute id="MapKey" type="FixedString" value="%s" />]], newId))
    table.insert(
        add,
        string.format([[<attribute id="ParentTemplateId" type="FixedString" value="%s" />]], template.TemplateId)
    )
    table.insert(add, string.format([[<attribute id="Name" type="LSString" value="%s" />]], "TOT_" .. template.Name))

    if template.AiHint ~= nil then
        table.insert(add, string.format([[<attribute id="AiHint" type="guid" value="%s" />]], template.AiHint))
    end
    if template.Archetype ~= nil then
        table.insert(
            add,
            string.format([[<attribute id="Archetype" type="FixedString" value="%s" />]], template.Archetype)
        )
    end
    if template.Stats ~= nil then
        table.insert(add, string.format([[<attribute id="Stats" type="FixedString" value="%s" />]], template.Stats))
    end
    if template.CharacterVisualResourceID ~= nil then
        table.insert(
            add,
            string.format(
                [[<attribute id="CharacterVisualResourceID" type="FixedString" value="%s" />]],
                template.CharacterVisualResourceID
            )
        )
    end
    if template.Icon ~= nil then
        table.insert(add, string.format([[<attribute id="Icon" type="FixedString" value="%s" />]], template.Icon))
    end
    if template.Equipment ~= nil then
        table.insert(
            add,
            string.format([[<attribute id="Equipment" type="FixedString" value="%s" />]], template.Equipment)
        )
    end
    if template.SpellSet ~= nil then
        table.insert(
            add,
            string.format([[<attribute id="SpellSet" type="FixedString" value="%s" />]], template.SpellSet)
        )
    end
    if template.LevelOverride ~= nil then
        table.insert(
            add,
            string.format([[<attribute id="LevelOverride" type="int32" value="%d" />]], template.LevelOverride)
        )
    end

    table.insert(all, string.format(wrap, table.concat(add, "\n")))

    table.insert(
        new,
        { TemplateId = newId, Name = "TOT_" .. template.Name, Info = template.Info, Tier = template.Tier }
    )
end

Mods.ToT.IO.Save("Enemies.lsx", table.concat(all, "\n"))
Mods.ToT.IO.SaveJson("Enemies.json", new)
