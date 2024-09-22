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

function GameMode.IsHardMode()
    return PersistentVars.HardMode
end

function GameMode.StartRoguelike(template)
    if not PersistentVars.RogueModeActive then
        PersistentVars.RogueModeActive = true
        Event.Trigger("RogueModeChanged", PersistentVars.RogueModeActive)
    end

    PersistentVars.RogueScenario = template.Name
end

function GameMode.GetTiers(cow, score)
    -- define tiers and their corresponding difficulty values
    local tiers = {
        { name = C.EnemyTier[1], min = 0, value = 4, amount = #Enemy.GetByTier(C.EnemyTier[1]) },
        { name = C.EnemyTier[2], min = 40, value = 10, amount = #Enemy.GetByTier(C.EnemyTier[2]) },
        { name = C.EnemyTier[3], min = 60, value = 20, amount = #Enemy.GetByTier(C.EnemyTier[3]) },
        { name = C.EnemyTier[4], min = 80, value = 32, amount = #Enemy.GetByTier(C.EnemyTier[4]) },
        { name = C.EnemyTier[5], min = 100, value = 48, amount = #Enemy.GetByTier(C.EnemyTier[5]) },
        { name = C.EnemyTier[6], min = 160, value = 80, amount = #Enemy.GetByTier(C.EnemyTier[6]) },
        { name = C.EnemyTier[7], min = 240, value = 170, amount = #Enemy.GetByTier(C.EnemyTier[7]) },
    }

    if GameMode.IsHardMode() then
        tiers = {
            { name = C.EnemyTier[1], min = 0, value = 4, amount = #Enemy.GetByTier(C.EnemyTier[1]) },
            { name = C.EnemyTier[2], min = 20, value = 8, amount = #Enemy.GetByTier(C.EnemyTier[2]) },
            { name = C.EnemyTier[3], min = 40, value = 15, amount = #Enemy.GetByTier(C.EnemyTier[3]) },
            { name = C.EnemyTier[4], min = 60, value = 27, amount = #Enemy.GetByTier(C.EnemyTier[4]) },
            { name = C.EnemyTier[5], min = 80, value = 35, amount = #Enemy.GetByTier(C.EnemyTier[5]) },
            { name = C.EnemyTier[6], min = 120, value = 56, amount = #Enemy.GetByTier(C.EnemyTier[6]) },
            { name = C.EnemyTier[7], min = 200, value = 100, amount = #Enemy.GetByTier(C.EnemyTier[7]) },
        }
    end

    if cow then
        tiers = { { name = "TOT_OX_A", value = math.max(4, score / 100), amount = 100 } }
    end

    return tiers
end

function GameMode.GenerateScenario(score, tiers)
    -- ChatGPT made this ................................ i made this
    L.Debug("Generate Scenario", score)

    local minRounds = 1
    local maxRounds = 10
    local preferredRounds = 3
    local emptyRoundChance = 0.2 -- 20% chance for a round to be empty
    local scoreTolerance = tiers[1].value
    if score > 1000 then
        maxRounds = 20
        preferredRounds = 5
        emptyRoundChance = 0.1
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

    local playerLevel = Player.Level()

    -- select a tier based on amount of enemies in tier
    local function selectTier(remainingValue)
        local validTiers = {}
        local totalWeight = 0
        for i, tier in ipairs(tiers) do
            if i <= playerLevel and score >= (tier.min or tier.value) then -- handle min score
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
                randomWeight = randomWeight - entry.weight
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
        if failed > 1000 then
            L.Error("Failed to generate timeline", maxValue)
            return {}
        end

        local timeline = {}
        local numRounds = weightedRandom()
        local remainingValue = maxValue
        -- initialize rounds with empty tables
        for i = 1, numRounds do
            table.insert(timeline, {})
        end

        local roundsSkipped = {}
        local function distribute()
            local roundIndex = math.random(1, numRounds)

            if #timeline[roundIndex] > 10 then
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

            local tier = selectTier(remainingValue)

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
                    end
                    if tier.name == C.EnemyTier[6] or tier.name == C.EnemyTier[7] then
                        table.insert(timeline, {})
                        numRounds = numRounds + 1

                        if not timeline[roundIndex + 1] then
                            table.insert(timeline, roundIndex + 1, {})
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

    return generateTimeline(score, 0)
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

    -- If not hard mode, give a bonus for perfect clear
    if not GameMode.IsHardMode() then
        endRound = endRound - 1
    end

    local diff = math.max(0, endRound - scenario:TotalRounds())

    score = score + math.max(baseScore - diff, 1)
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

    local partySizeMod = math.exp((Player.PartySize() - 4) * 0.2)

    local function scale(i, h)
        local x = i / 200
        local max_value = Config.ScalingModifier

        if h then
            x = x * 2
            max_value = Config.ScalingModifier * 1.6666667
        end

        local rate = i / 1000
        return math.floor(max_value * (1 - math.exp(-rate * x)) * partySizeMod)
    end

    local mod = scale(score, GameMode.IsHardMode())
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
        Osi.AddBoosts(enemy.GUID, "IncreaseMaxHP(" .. mod2 .. "%)", Mod.TableKey, Mod.TableKey)
        if mod2 > 0 then
            Osi.AddBoosts(enemy.GUID, "IncreaseMaxHP(" .. mod2 * 10 .. ")", Mod.TableKey, Mod.TableKey)
        end
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
            local acMax = math.max(4, mod3)
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

Event.On(
    "ScenarioStopped",
    ifRogueLike(function(scenario)
        if scenario.OnMap then
            GameMode.UpdateRogueScore(PersistentVars.RogueScore - 10)
        end
    end)
)

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

local function getMap(template)
    local threshold = GameMode.IsHardMode() and 20 or 40

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

local function makeItCow()
    local lolcow = math.random() < 0.001
    if lolcow then
        local hasOX = Enemy.Find("TOT_OX_A")
        lolcow = hasOX and true or false
    end

    if lolcow then
        Defer(1000, function()
            Player.Notify(__("You found the secret cow level!"))
        end)
    end

    return lolcow
end

Schedule(function()
    External.Templates.AddScenario({
        RogueLike = true,
        OnStart = function(template)
            GameMode.StartRoguelike(template)
        end,

        Name = C.RoguelikeScenario .. " (bias lower tier)",
        Map = getMap,

        -- Spawns per Round
        Timeline = function(template)
            local tiers = GameMode.GetTiers(makeItCow(), PersistentVars.RogueScore)

            for i, tier in ipairs(tiers) do
                local weight = tier.amount / 100 * 0.7 -- bias towards tiers with more enemies
                tier.weight = weight + (1 / (i + 1)) -- bias towards lower tiers
                L.Debug("Tier", tier.name, tier.weight)
            end

            return GameMode.GenerateScenario(PersistentVars.RogueScore, tiers)
        end,

        Loot = C.LootRates,
    })
    External.Templates.AddScenario({
        RogueLike = true,
        OnStart = function(template)
            GameMode.StartRoguelike(template)
        end,

        Name = C.RoguelikeScenario .. " (bias balanced)",
        Map = getMap,

        -- Spawns per Round
        Timeline = function(template)
            local tiers = GameMode.GetTiers(makeItCow(), PersistentVars.RogueScore)

            for i, tier in ipairs(tiers) do
                local weight = tier.amount / 100 * 0.9 -- bias towards tiers with more enemies
                tier.weight = weight + (1 / (i + 1) / 2) -- bias towards lower tiers
                L.Debug("Tier", tier.name, tier.weight)
            end

            return GameMode.GenerateScenario(PersistentVars.RogueScore, tiers)
        end,

        Loot = C.LootRates,
    })
    External.Templates.AddScenario({
        RogueLike = true,
        OnStart = function(template)
            GameMode.StartRoguelike(template)
        end,

        Name = C.RoguelikeScenario .. " (bias higher tier)",
        Map = getMap,

        -- Spawns per Round
        Timeline = function(template)
            local tiers = GameMode.GetTiers(makeItCow(), PersistentVars.RogueScore)

            for i, tier in ipairs(tiers) do
                local weight = tier.amount / 100 * 0.7 -- bias towards tiers with more enemies
                tier.weight = weight + (1 / (#tiers + 1 - i)) -- bias towards higher tiers
                L.Debug("Tier", tier.name, tier.weight)
            end

            return GameMode.GenerateScenario(PersistentVars.RogueScore, tiers)
        end,

        Loot = C.LootRates,
    })
end)
