-- Ext.Utils.Include(nil, "Mods/CombatMod/ScriptExtender/Lua/ListExport.lua")
local MT = Mods.ToT

local str = table.concat({
    "TemplateId",
    "Name",
    "Tier",
    "IsBoss",
    "Archetype",
    "Race",
    "Stats",
    "Equipment",
    "Info.AC",
    "Info.Level",
    "Info.Stats",
    "Info.Vit",
    "Info.Pwr",
}, ",") .. "\n"

for _, tier in pairs(MT.C.EnemyTier) do
    local enemies = MT.Enemy.GetByTier(tier)
    for _, enemy in pairs(enemies) do
        enemy:SyncTemplate()
        _D(enemy.Info)
        str = str
            .. table.concat({
                enemy.TemplateId,
                enemy.Name,
                enemy.Tier,
                enemy.IsBoss and 1 or 0,
                enemy.Archetype,
                enemy.Race,
                enemy.Stats,
                enemy.Equipment,
                enemy.Info.AC,
                enemy.Info.Level,
                enemy.Info.Stats,
                enemy.Info.Vit,
                enemy.Info.Pwr,
            }, ",")
            .. "\n"
    end
end

MT.IO.Save("EnemyList.csv", str)

local str = table.concat({
    "Type",
    "Rarity",
    "RootTemplate",
    "Name",
    "DisplayName",
    "Link",
    "Link2",
}, ",") .. "\n"

local list = {
    Objects = MT.Item.Objects(rarity, false),
    CombatObjects = MT.Item.Objects(rarity, true),
    Armor = MT.Item.Armor(rarity),
    Weapons = MT.Item.Weapons(rarity),
}

for cat, li in pairs(list) do
    _D(cat)
    for _, item in pairs(li) do
        _D(item.Name)
        str = str
            .. table.concat({
                cat,
                item.Rarity,
                item.RootTemplate,
                item.Name,
                '"' .. item:GetTranslatedName() .. '"',
                '"' .. "https://bg3.norbyte.dev/search?q=" .. item.Name .. '"',
                '"' .. "https://bg3.norbyte.dev/search?q=" .. item.RootTemplate .. '"',
            }, ",")
            .. "\n"
    end
end

MT.IO.Save("ItemList.csv", str)
