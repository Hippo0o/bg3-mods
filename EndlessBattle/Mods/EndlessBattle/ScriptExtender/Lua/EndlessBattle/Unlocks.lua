function Unlocks.CalculateReward(scenario)
    local endRound = scenario.Round - 1
    local diff = endRound - scenario:TotalRounds()

    local rewardMulti = math.max(5 - diff, 1)
    if PersistentVars.Unlocks.CurrencyMultiplier then
        rewardMulti = rewardMulti * 1.2
    end

    local reward = 0
    for _, e in pairs(scenario.KilledEnemies) do
        local _, value = UT.Find(C.EnemyTier, U.Lambda("e, tier => e.Tier == tier", e)) -- don't tell norbyte
        if value == nil then
            U.Error("Invalid tier for enemy", e.Tier, e.Name)
            value = 1
        end
        reward = reward + value
    end

    PersistentVars.Currency = (PersistentVars.Currency or 0) + math.ceil(reward * rewardMulti)
end

Event.On("ScenarioEnded", function(scenario)
    Unlocks.CalculateReward(scenario)
end)
