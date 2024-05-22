local MT = Mods.EndlessBattle

for _, tier in pairs(MT.C.EnemyTier) do
    local timeline = {}
    local enemies = MT.Enemy.GetByTier(tier)
    local rounds = math.ceil(#enemies / 10)

    for i = 1, rounds do
        local round = {}
        for j = 1, 10 do
            local enemy = enemies[(i - 1) * 10 + j]
            if enemy then
                table.insert(round, { enemy.TemplateId })
            end
        end
        table.insert(timeline, round)
    end

    MT.External.Templates.AddScenario({
        Name = "DebugEnemy " .. tier,
        Timeline = timeline,
        Loot = MT.C.LootRates,
    })
end
