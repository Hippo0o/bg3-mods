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
