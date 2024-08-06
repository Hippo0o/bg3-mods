
Osi.SetImmortal(GetHostCharacter(), 1)
Osi.SetHitpoints(GetHostCharacter(), 1000)

if DEBUG_ENEMIES then
    return
end

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
                table.insert(round, enemy.TemplateId)
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

MT.External.Templates.AddMap({
    Name = "DebugEnemy",
    Region = "WLD_Main_A",
    Enter = { 96.64624786377, 35.712890625, 573.94073486328 },

    Spawns = {
        { 96.64624786377, 35.712890625, 573.94073486328 },
        { 96.535217285156, 34.791015625, 579.26715087891 },
        { 97.84578704834, 33.4970703125, 586.23681640625 },
        { 98.63484954834, 32.7412109375, 591.91088867188 },
        { 99.325485229492, 32.279296875, 596.90747070312 },
        { 99.862480163574, 31.939453125, 600.79333496094 },
    },
})

-- MT.Event.On("ScenarioEnemySpawned", function(scenario, enemy)
--     if scenario.Map.Name == "DebugEnemy" then
--         Osi.SetCanFight(enemy.GUID, 0)
--     end
-- end)

DEBUG_ENEMIES = true

MT.Api.UI()
