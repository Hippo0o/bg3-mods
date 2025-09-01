Event.On("ScenarioStarted", function(scenario)
    Osi.AutoSave()
end)

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                       Rogue-like mode                                       --
--                                                                                             --
-------------------------------------------------------------------------------------------------

local function ifRogueLike(func)
    return function(...)
        if PersistentVars.RogueModeActive then
            func(...)
        end
    end
end

function GameMode.StartRoguelike(template)
    if not PersistentVars.RogueModeActive then
        PersistentVars.RogueModeActive = true
        Event.Trigger("RogueModeChanged", PersistentVars.RogueModeActive)
    end

    PersistentVars.RogueScenario = template.Name
end

function GameMode.GetTiers(score, difficulty)
    -- define tiers and their corresponding difficulty values
    local tiers = {
        { name = C.EnemyTier[1], min = 0, value = 4, amount = #Enemy.GetByTier(C.EnemyTier[1]) },
        { name = C.EnemyTier[2], min = 25, value = 10, amount = #Enemy.GetByTier(C.EnemyTier[2]) },
        { name = C.EnemyTier[3], min = 45, value = 20, amount = #Enemy.GetByTier(C.EnemyTier[3]) },
        { name = C.EnemyTier[4], min = 70, value = 32, amount = #Enemy.GetByTier(C.EnemyTier[4]) },
        { name = C.EnemyTier[5], min = 90, value = 46, amount = #Enemy.GetByTier(C.EnemyTier[5]) },
        { name = C.EnemyTier[6], min = 120, value = 68, amount = #Enemy.GetByTier(C.EnemyTier[6]) },
        { name = C.EnemyTier[7], min = 160, value = 118, amount = #Enemy.GetByTier(C.EnemyTier[7]) },
        { name = C.EnemyTier[8], min = 200, value = 146, amount = #Enemy.GetByTier(C.EnemyTier[8]) },
    }

    if difficulty == 1 then
        tiers = {
            { name = C.EnemyTier[1], min = 0, value = 4, amount = #Enemy.GetByTier(C.EnemyTier[1]) },
            { name = C.EnemyTier[2], min = 15, value = 8, amount = #Enemy.GetByTier(C.EnemyTier[2]) },
            { name = C.EnemyTier[3], min = 30, value = 15, amount = #Enemy.GetByTier(C.EnemyTier[3]) },
            { name = C.EnemyTier[4], min = 50, value = 27, amount = #Enemy.GetByTier(C.EnemyTier[4]) },
            { name = C.EnemyTier[5], min = 70, value = 35, amount = #Enemy.GetByTier(C.EnemyTier[5]) },
            { name = C.EnemyTier[6], min = 90, value = 56, amount = #Enemy.GetByTier(C.EnemyTier[6]) },
            { name = C.EnemyTier[7], min = 120, value = 86, amount = #Enemy.GetByTier(C.EnemyTier[7]) },
            { name = C.EnemyTier[8], min = 150, value = 108, amount = #Enemy.GetByTier(C.EnemyTier[8]) },
        }
    end

    if difficulty == 2 then
        tiers = {
            { name = C.EnemyTier[1], min = 0, value = 1, amount = #Enemy.GetByTier(C.EnemyTier[1]) },
            { name = C.EnemyTier[2], min = 5, value = 4, amount = #Enemy.GetByTier(C.EnemyTier[2]) },
            { name = C.EnemyTier[3], min = 15, value = 8, amount = #Enemy.GetByTier(C.EnemyTier[3]) },
            { name = C.EnemyTier[4], min = 30, value = 20, amount = #Enemy.GetByTier(C.EnemyTier[4]) },
            { name = C.EnemyTier[5], min = 45, value = 24, amount = #Enemy.GetByTier(C.EnemyTier[5]) },
            { name = C.EnemyTier[6], min = 60, value = 32, amount = #Enemy.GetByTier(C.EnemyTier[6]) },
            { name = C.EnemyTier[7], min = 80, value = 60, amount = #Enemy.GetByTier(C.EnemyTier[7]) },
            { name = C.EnemyTier[8], min = 100, value = 86, amount = #Enemy.GetByTier(C.EnemyTier[8]) },
        }
    end

    return table.filter(tiers, function(v)
        return v.amount > 0
    end)
end

function GameMode.GenerateScenario(score, tiers)
    L.Debug("Generate Scenario", score)

    local minRounds = 1
    local maxRounds = 10
    local preferredRounds = 3
    local emptyRoundChance = 0.2 -- 20% chance for a round to be empty
    local scoreTolerance = tiers[1].value
    if score > 70 then
        emptyRoundChance = 0.1
    end
    if score > 120 then
        preferredRounds = 2
        emptyRoundChance = 0.05
    end
    if score > 200 then
        preferredRounds = 2
        emptyRoundChance = 0
    end
    if score > 500 then
        maxRounds = 20
        preferredRounds = 4
        emptyRoundChance = 0
        scoreTolerance = 50
    end
    if score > 3000 then
        maxRounds = math.ceil(score / 100)
        preferredRounds = math.ceil(score / 300)
        emptyRoundChance = 0
        scoreTolerance = math.ceil(score / 30)
    end

    score = score >= tiers[1].value and score or tiers[1].value

    -- weighted random function to bias towards a preferred number of rounds
    local function weightedRandom(maxValue)
        local weights = {}
        local totalWeight = 0
        for i = minRounds, maxRounds do
            local weight = 1 / (math.abs(i - preferredRounds) + 1) -- adjusted weight calculation
            weights[i] = weight
            totalWeight = totalWeight + weight
        end
        local randomWeight = math.random() * totalWeight
        for i = minRounds, maxRounds do
            randomWeight = randomWeight - weights[i]
            if randomWeight <= 0 then
                return i
            end
        end
        return maxRounds
    end

    -- select a tier based on amount of enemies in tier
    local function selectTier(remainingValue, distributed)
        local validTiers = {}
        local totalWeight = 0
        for i, tier in ipairs(tiers) do
            if score >= (tier.min or tier.value) then -- handle min score
                if remainingValue >= tier.value then
                    local weight = tier.weight

                    table.insert(validTiers, { tier = tier, weight = weight })
                    totalWeight = totalWeight + weight
                end
            end
        end
        if #validTiers > 0 then
            local randomWeight = math.random() * totalWeight
            for _, entry in ipairs(validTiers) do
                randomWeight = randomWeight - entry.weight - (distributed[entry.tier] or 0) * 0.1
                if randomWeight <= 0 then
                    return entry.tier
                end
            end
        end

        return tiers[1] -- fallback to the lowest tier
    end

    -- generate a random timeline with bias and possible empty rounds
    local function generateTimeline(maxValue, failed)
        failed = failed + 1
        if failed > 10 then
            L.Error("Failed to generate timeline", maxValue)
            return {}
        end

        local timeline = {}
        local tiersDistribued = {}
        local numRounds = weightedRandom()
        local remainingValue = maxValue
        -- initialize rounds with empty tables
        for i = 1, numRounds do
            table.insert(timeline, {})
        end

        local roundsSkipped = {}
        local maxPerRound = 10
        local function distribute()
            local roundIndex = math.random(1, numRounds)

            if #timeline[roundIndex] > maxPerRound then
                if
                    -- check if timeline has any round that isnt maxed
                    table.find(
                        table.map(timeline, function(round)
                            return #round
                        end),
                        function(count)
                            return count < maxPerRound + 1
                        end
                    )
                then
                    return
                end

                numRounds = numRounds + 1
                maxPerRound = maxPerRound + 1
                table.insert(timeline, roundIndex, {})
                return
            end

            if roundsSkipped[roundIndex] then
                return
            end

            -- add a chance for the round to remain empty, except for the first round
            if
                roundIndex > 1
                and not roundsSkipped[roundIndex - 1]
                and #timeline[roundIndex] == 0
                and math.random() < emptyRoundChance
            then -- chance to skip adding a tier
                roundsSkipped[roundIndex] = true
                remainingValue = remainingValue + maxValue * emptyRoundChance
                return
            end

            local tier = selectTier(remainingValue, tiersDistribued)
            tiersDistribued[tier] = (tiersDistribued[tier] or 0) + 1

            if remainingValue - tier.value >= 0 then
                table.insert(timeline[roundIndex], tier.name)
                remainingValue = remainingValue - tier.value

                local max = math.ceil(maxValue / 100)

                if #timeline[roundIndex] > max and numRounds < maxRounds then
                    -- too strong for single round
                    if tier.name == C.EnemyTier[5] then
                        if not timeline[roundIndex + 1] then
                            table.insert(timeline, roundIndex + 1, {})
                            numRounds = numRounds + 1
                        end
                    elseif tier.name == C.EnemyTier[6] or tier.name == C.EnemyTier[7] then
                        table.insert(timeline, {})
                        numRounds = numRounds + 1
                        if not timeline[roundIndex + 1] then
                            table.insert(timeline, roundIndex + 1, {})
                            numRounds = numRounds + 1
                        end
                    elseif tier.name == C.EnemyTier[8] then
                        table.insert(timeline, {})
                        table.insert(timeline, {})
                        numRounds = numRounds + 2
                        if not timeline[roundIndex + 1] then
                            table.insert(timeline, roundIndex + 1, {})
                            numRounds = numRounds + 1
                        end
                        if not timeline[roundIndex + 2] then
                            table.insert(timeline, roundIndex + 2, {})
                            numRounds = numRounds + 1
                        end
                    end
                end
            end
        end

        -- distribute the total value randomly across rounds
        local failsafe = 0
        while remainingValue > 0 do
            distribute()

            if remainingValue < scoreTolerance then
                break
            end

            failsafe = failsafe + 1

            if failsafe > maxValue * 100 then
                if Mod.Debug then
                    L.Error("Failsafe", remainingValue, maxValue)
                end
                return generateTimeline(maxValue, failed)
            end
        end

        -- ensure the first round is not empty
        if #timeline[1] == 0 then
            if Mod.Debug then
                L.Error("Empty first round", remainingValue, maxValue)
            end
            return generateTimeline(maxValue, failed)
        end

        local maxEmpty = math.min(2, math.max(score / 100, numRounds / 3))

        -- ensure no two consecutive rounds exist
        for i = 2, #timeline do
            if #timeline[i] <= maxEmpty and #timeline[i - 1] <= maxEmpty then
                if Mod.Debug then
                    L.Error("Consecutive empty rounds", remainingValue, maxValue, maxEmpty)
                end
                return generateTimeline(maxValue, failed)
            end
        end

        -- ensure the last round does not exceed the previous round
        if #timeline > 1 and #timeline[#timeline] > #timeline[#timeline - 1] then
            L.Error("Last round is too big", #timeline[#timeline], #timeline[#timeline - 1])
            return generateTimeline(maxValue, failed)
        end

        return timeline
    end

    local partySizeMod = Player.PartySize()
    local spawnValue = score

    if partySizeMod == 1 then
        spawnValue = math.ceil(score * 0.7)
    elseif partySizeMod == 2 then
        spawnValue = math.ceil(score * 0.8)
    elseif partySizeMod == 3 then
        spawnValue = math.ceil(score * 0.9)
    elseif partySizeMod == 5 then
        spawnValue = math.ceil(score * 1.2)
    elseif partySizeMod == 6 then
        spawnValue = math.ceil(score * 1.4)
    elseif partySizeMod == 7 then
        spawnValue = math.ceil(score * 1.6)
    elseif partySizeMod >= 8 then
        spawnValue = math.ceil(score * 2)
    end

    if spawnValue < 4 then
        spawnValue = 4
    end

    return generateTimeline(spawnValue, 0)
end

function GameMode.UpdateRogueScore(score)
    local prev = PersistentVars.RogueScore

    local cap = math.min(100, (Player.Level() - 1) * 10) -- +10 per level, max 100
    if score < cap then
        score = cap
    end

    if prev == score then
        return
    end

    PersistentVars.RogueScore = score

    Event.Trigger("RogueScoreChanged", prev, score)

    Defer(1000, function()
        Player.Notify(__("Your RogueScore changed: %d -> %d!", prev, score))
    end)
end

function GameMode.RewardRogueScore(scenario)
    local score = PersistentVars.RogueScore

    local baseScore = 5
    if PersistentVars.Unlocked.RogueScoreMultiplier then
        baseScore = baseScore * 2
    end

    -- Always has 1 round more than the timeline because of CombatRoundStarted
    local endRound = scenario.Round - 1

    local diff = math.max(0, endRound - scenario:TotalRounds())

    score = score + math.max(baseScore - diff, 2)
    GameMode.UpdateRogueScore(score)

    if endRound <= scenario:TotalRounds() then
        Event.Trigger("ScenarioPerfectClear", scenario)
        Player.AskConfirmation("Perfect Clear! Double your score from %d to %d?", baseScore, baseScore * 2)
            :After(function(confirmed)
                if confirmed then
                    GameMode.UpdateRogueScore(score + baseScore)
                end
            end)
    end
end

function GameMode.StartNext()
    if Scenario.Current() then
        return
    end

    local rogueTemp = table.find(Scenario.GetTemplates(), function(v)
        return v.Name == PersistentVars.RogueScenario
    end)

    if not rogueTemp then
        Player.Notify(__("Select a Roguelike scenario to start!"))
        return
    end

    Scenario.Start(rogueTemp)
end

GameMode.DifficultyAppliedTo = {}

---@param enemy Enemy
---@param score integer
function GameMode.ApplyDifficulty(enemy, score)
    if GameMode.DifficultyAppliedTo[enemy.GUID] then
        return
    end

    -- Legendary Action summons like the Claws of Tu'narath become exponentially more dangerous if they're allowed to scale
    if enemy.Temporary then
        return
    end
    local originalDex = enemy:Entity().Stats.AbilityModifiers[3]

    local function scale(i)
        local x = i / 200
        local rate = i / 1000
        local scalar = Config.ScalingModifier

        local mod = math.floor(scalar * (1 - math.exp(-rate * x)))
        local tierValue = UT.Invert(C.EnemyTier)[enemy.Tier] or 1

        -- funny magic calculation that makes higher tier enemies scale less and lower tiers scale more
        local denom = 0.331 * math.exp(0.318 * tierValue)
        local mod = math.floor(mod / denom)

        -- scale down below 100 score
        local invRatio = (100 - i) / 100
        -- boost higher tiers more aggressively
        local expFactor = math.exp(tierValue - 1)
        return mod - math.max(0, math.floor(invRatio * expFactor))
    end

    local mod = scale(score)
    if mod == 0 then
        return
    end

    local mod2 = math.floor(mod / 2)
    local mod3 = math.floor(mod2 / 2)

    local map = {}
    local abilties = { "Strength", "Dexterity", "Constitution", "Intelligence", "Wisdom", "Charisma" }
    for i, v in pairs(enemy:Entity().Stats.Abilities) do
        if i > 1 and v then
            table.insert(map, { abilties[i - 1], v })
        end
    end
    table.sort(map, function(left, right)
        return left[2] > right[2]
    end)

    if mod ~= 0 then
        Osi.AddBoosts(enemy.GUID, "Ability(" .. map[1][1] .. "," .. mod .. ")", Mod.TableKey, Mod.TableKey)
        Osi.AddBoosts(enemy.GUID, "Ability(" .. map[2][1] .. "," .. mod .. ")", Mod.TableKey, Mod.TableKey)
    end
    if mod2 ~= 0 then
        Osi.AddBoosts(enemy.GUID, "Ability(" .. map[3][1] .. "," .. mod2 .. ")", Mod.TableKey, Mod.TableKey)
        Osi.AddBoosts(enemy.GUID, "Ability(" .. map[4][1] .. "," .. mod2 .. ")", Mod.TableKey, Mod.TableKey)
        -- Osi.AddBoosts(enemy.GUID, "IncreaseMaxHP(" .. mod2 .. "%)", Mod.TableKey, Mod.TableKey)
        Osi.AddBoosts(enemy.GUID, "IncreaseMaxHP(" .. mod2 * 10 .. ")", Mod.TableKey, Mod.TableKey)
    end
    if mod3 ~= 0 then
        Osi.AddBoosts(enemy.GUID, "Ability(" .. map[5][1] .. "," .. mod3 .. ")", Mod.TableKey, Mod.TableKey)
        Osi.AddBoosts(enemy.GUID, "Ability(" .. map[6][1] .. "," .. mod3 .. ")", Mod.TableKey, Mod.TableKey)
        Osi.AddBoosts(enemy.GUID, "AC(" .. mod3 .. ")", Mod.TableKey, Mod.TableKey)
    end

    WaitTicks(6, function()
        local entity = Ext.Entity.Get(enemy.GUID)
        assert(entity, "ApplyDifficulty: entity not found")
        if mod2 > 0 then
            local maxLevel = 12
            if Player.Level() > 12 then
                maxLevel = Player.Level()
            end

            local newLevel = math.max(entity.AvailableLevel.Level, math.min(maxLevel, mod2))
            entity.EocLevel.Level = newLevel
            entity:Replicate("EocLevel")
        end

        local currentAc = entity.Resistances.AC

        local armor = Osi.GetEquippedItem(enemy.GUID, "Breast")
        local dexScaling = true
        if armor then
            dexScaling = Ext.Entity.Get(armor).Armor.ArmorType < 5
        end

        if dexScaling then
            local initialAcMax = math.max(4, mod3)
            local acMax = math.max(initialAcMax, originalDex)
            local dexAc = entity.Stats.AbilityModifiers[3] - acMax
            if dexAc > 0 then
                currentAc = currentAc - dexAc
                Osi.AddBoosts(enemy.GUID, "AC(-" .. dexAc .. ")", Mod.TableKey, Mod.TableKey)
            end
        end

        local acMax = math.max(30, mod)
        local ac = currentAc
        while ac > acMax do
            ac = ac - 3
        end

        ac = ac - currentAc
        if ac < 0 then
            Osi.AddBoosts(enemy.GUID, "AC(" .. ac .. ")", Mod.TableKey, Mod.TableKey)
        end
    end)

    GameMode.DifficultyAppliedTo[enemy.GUID] = true
end

function GameMode.GetRandomMap(template)
    local threshold = 40

    local maps = table.filter(Map.Get(), function(v)
        return PersistentVars.RogueScore > threshold or v.Region == C.Regions.Act1
    end)

    local map = nil
    if #maps > 0 then
        local random = math.random(#maps)

        if table.contains(PersistentVars.RandomLog.Maps, random) then
            random = math.random(#maps)
        end
        LogRandom("Maps", random, 10)

        map = maps[random]
    end

    return map
end

function GameMode.GetFilteredEnemies(timeline, templates)
    local enemies = {}
    local tiers = {}
    for _, definitions in ipairs(timeline) do
        for _, definition in ipairs(definitions) do
            if table.contains(C.EnemyTier, definition) then
                tiers[definition] = (tiers[definition] or 0) + 1
            else
                -- timeline had an explicit enemy
                table.insert(enemies, Enemy.Find(definition, templates))
            end
        end
    end

    for tier, amount in pairs(tiers) do
        local list = Enemy.GetByTier(tier, templates)
        if #list > 0 then
            local tierValue = UT.Invert(C.EnemyTier)[tier]

            local m = table.size(tiers)
            m = math.max(1, m - tierValue)
            m = 10 * m
            local uniqueness = math.ceil(amount / m)

            if tierValue >= 6 then -- legendary or higher is always preferred unique
                uniqueness = amount
            end

            L.Dump("Enemies - Tiers", tier, amount, uniqueness, #list)

            for i = 1, uniqueness do
                table.insert(enemies, list[math.random(#list)])
            end
        end
    end

    L.Dump(
        "Enemies",
        table.map(enemies, function(v)
            return v.Name
        end)
    )

    return enemies
end

function GameMode.GenerateTimeline(difficulty)
    local tiers = GameMode.MakeItCow() or GameMode.GetTiers(PersistentVars.RogueScore, difficulty)

    for i, tier in ipairs(tiers) do
        -- local weight = tier.amount / 2000 -- slight bias towards tiers with more enemies
        -- tier.weight = weight + 1 - ((i + 1) * 0.062) -- slightly descending bias per tier
        local weight = (tier.amount / 100) * 0.3 -- slight bias towards tiers with more enemies
        tier.weight = weight + (1 / (i + 1)) -- strong bias towards lower tiers
        L.Debug("Tier", tier.name, tier.weight)
    end
    L.Dump("Tiers", tiers)
    return GameMode.GenerateScenario(PersistentVars.RogueScore, tiers)
end

function GameMode.MakeItCow()
    local lolcow = math.random() < 0.001
    if lolcow then
        local hasOX = Enemy.Find("TOT_OX_A")
        lolcow = hasOX and true or false
    end

    if lolcow then
        Defer(1000, function()
            Player.Notify(__("You found the secret cow level!"))
        end)
        return { { name = "TOT_OX_A", value = math.max(4, PersistentVars.RogueScore / 100), amount = 100 } }
    end

    return false
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Events                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

Ext.Osiris.RegisterListener(
    "TeleportedToCamp",
    1,
    "after",
    ifRogueLike(function(uuid)
        if U.UUID.Equals(uuid, Player.Host()) then
            GameMode.StartNext()
        end
    end)
)

Event.On("RogueModeChanged", function(bool)
    if not bool then
        return
    end

    if not PersistentVars.GUIOpen then
        Net.Send("OpenGUI")
    end
end)

--Event.On(
--    "ScenarioStopped",
--   ifRogueLike(function(scenario)
--        if scenario.OnMap then
--            GameMode.UpdateRogueScore(PersistentVars.RogueScore - 5)
--        end
--    end)
--)

Event.On(
    "ScenarioEnemySpawned",
    ifRogueLike(function(scenario, enemy)
        GameMode.ApplyDifficulty(enemy, PersistentVars.RogueScore)
    end)
)

Event.On(
    "ScenarioRestored",
    ifRogueLike(function(scenario)
        for _, enemy in pairs(scenario.SpawnedEnemies) do
            GameMode.ApplyDifficulty(enemy, PersistentVars.RogueScore)
        end
    end)
)

Event.On(
    "ScenarioEnded",
    ifRogueLike(function(scenario)
        GameMode.DifficultyAppliedTo = {}

        GameMode.RewardRogueScore(scenario)

        if Config.AutoTeleport > 0 then
            Player.Notify(__("Teleporting back to camp in %d seconds.", Config.AutoTeleport), true)
            local timer = Defer(Config.AutoTeleport * 1000, function()
                Player.ReturnToCamp()
            end)

            Event.On("ScenarioStarted", function(scenario)
                timer.Source:Clear()
            end, true)
        end
    end)
)

Schedule(function()
    External.Templates.AddScenario({
        RogueLike = true,
        OnStart = function(self)
            GameMode.StartRoguelike(self)
        end,

        Name = C.RoguelikeScenario,
        Map = GameMode.GetRandomMap,

        Enemies = function(self)
            return GameMode.GetFilteredEnemies(self._Timeline)
        end,

        -- Spawns per Round
        _Timeline = nil,
        Timeline = function(self)
            self._Timeline = GameMode.GenerateTimeline(0)
            return self._Timeline
        end,
    })
    External.Templates.AddScenario({
        RogueLike = true,
        OnStart = function(self)
            GameMode.StartRoguelike(self)
        end,

        Name = C.RoguelikeScenario .. " (Hard)",
        Map = GameMode.GetRandomMap,

        Enemies = function(self)
            return GameMode.GetFilteredEnemies(self._Timeline)
        end,

        -- Spawns per Round
        _Timeline = nil,
        Timeline = function(self)
            self._Timeline = GameMode.GenerateTimeline(1)
            return self._Timeline
        end,
    })
    External.Templates.AddScenario({
        RogueLike = true,
        OnStart = function(self)
            GameMode.StartRoguelike(self)
        end,

        Name = C.RoguelikeScenario .. " (Hell)",
        Map = GameMode.GetRandomMap,

        Enemies = function(self)
            return GameMode.GetFilteredEnemies(self._Timeline)
        end,

        -- Spawns per Round
        _Timeline = nil,
        Timeline = function(self)
            self._Timeline = GameMode.GenerateTimeline(2)
            return self._Timeline
        end,
    })
end)
