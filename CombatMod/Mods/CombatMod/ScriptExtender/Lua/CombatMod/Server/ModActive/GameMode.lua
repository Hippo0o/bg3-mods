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

function GameMode.StartRoguelike()
    PersistentVars.RogueModeActive = true
    Event.Trigger("RogueModeChanged", PersistentVars.RogueModeActive)
end

function GameMode.GenerateScenario(score, cow)
    -- ChatGPT made this ................................ i made this
    L.Debug("Generate Scenario", score)

    local minRounds = 1
    local maxRounds = 10
    local preferredRounds = 3
    local emptyRoundChance = 0.2 -- 20% chance for a round to be empty
    if score > 1000 then
        maxRounds = 20
        preferredRounds = 5
        emptyRoundChance = 0.1
    end
    if score > 3000 then
        maxRounds = math.ceil(score / 100)
        preferredRounds = math.ceil(score / 300)
        emptyRoundChance = 0
    end

    -- define tiers and their corresponding difficulty values
    local tiers = {
        { name = C.EnemyTier[1], min = 0, value = 4, amount = #Enemy.GetByTier(C.EnemyTier[1]) },
        { name = C.EnemyTier[2], min = 20, value = 10, amount = #Enemy.GetByTier(C.EnemyTier[2]) },
        { name = C.EnemyTier[3], min = 25, value = 20, amount = #Enemy.GetByTier(C.EnemyTier[3]) },
        { name = C.EnemyTier[4], min = 35, value = 32, amount = #Enemy.GetByTier(C.EnemyTier[4]) },
        { name = C.EnemyTier[5], min = 50, value = 48, amount = #Enemy.GetByTier(C.EnemyTier[5]) },
        { name = C.EnemyTier[6], min = 100, value = 69, amount = #Enemy.GetByTier(C.EnemyTier[6]) },
    }

    if PersistentVars.HardMode then
        tiers = {
            { name = C.EnemyTier[1], value = 4, amount = #Enemy.GetByTier(C.EnemyTier[1]) },
            { name = C.EnemyTier[2], value = 8, amount = #Enemy.GetByTier(C.EnemyTier[2]) },
            { name = C.EnemyTier[3], value = 15, amount = #Enemy.GetByTier(C.EnemyTier[3]) },
            { name = C.EnemyTier[4], value = 27, amount = #Enemy.GetByTier(C.EnemyTier[4]) },
            { name = C.EnemyTier[5], value = 35, amount = #Enemy.GetByTier(C.EnemyTier[5]) },
            { name = C.EnemyTier[6], value = 52, amount = #Enemy.GetByTier(C.EnemyTier[6]) },
        }
    end

    if cow then
        tiers = { { name = "OX_A", value = 4, amount = 100 } }
    end

    for i, tier in ipairs(tiers) do
        local weight = tier.amount / 100 * 0.9 -- bias towards tiers with more enemies
        tier.weight = weight + (1 / (i + 1) / 2) -- bias towards lower tiers
        L.Debug("Tier", tier.name, tier.weight)
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
    local function selectTier(remainingValue)
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
        if failed > 100 then
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

                -- too strong for single round
                if tier.name == C.EnemyTier[5] then
                    if not timeline[roundIndex + 1] or numRounds < maxRounds then
                        table.insert(timeline, roundIndex + 1, {})
                        numRounds = numRounds + 1
                    end
                end
                if tier.name == C.EnemyTier[6] then
                    table.insert(timeline, {})
                    numRounds = numRounds + 1

                    if numRounds < maxRounds then
                        table.insert(timeline, roundIndex + 1, {})
                        numRounds = numRounds + 1
                    end
                end
            end
        end

        -- distribute the total value randomly across rounds
        local failsafe = 0
        while remainingValue > 0 do
            distribute()

            if remainingValue < tiers[1].value then
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

function GameMode.UpdateRogueScore(scenario)
    local score = PersistentVars.RogueScore
    local prev = score

    local function updateScore(score)
        PersistentVars.RogueScore = score

        Event.Trigger("RogueScoreChanged", prev, score)

        Defer(1000, function()
            Player.Notify(__("Your RogueScore increased: %d -> %d!", prev, score))
        end)
    end

    local baseScore = 5
    if PersistentVars.Unlocked.RogueScoreMultiplier then
        baseScore = baseScore * 2
    end

    -- Always has 1 round more than the timeline because of CombatRoundStarted
    local endRound = scenario.Round - 1

    -- If not hard mode, give a bonus for perfect clear
    if not PersistentVars.HardMode then
        endRound = endRound - 1
    end

    local diff = math.max(0, endRound - scenario:TotalRounds())

    score = score + math.max(baseScore - diff, 1)
    updateScore(score)

    if endRound <= scenario:TotalRounds() then
        Player.AskConfirmation(__("Perfect Clear! Double your score from %d to %d?", baseScore, baseScore * 2))
            :After(function(confirmed)
                if confirmed then
                    updateScore(score + baseScore)
                end
            end)
    end
end

function GameMode.StartNext()
    if Scenario.Current() then
        return
    end

    local rogueTemp = UT.Find(Scenario.GetTemplates(), function(v)
        return v.Name == C.RoguelikeScenario
    end)

    if not rogueTemp then
        return
    end

    local threshold = PersistentVars.HardMode and 20 or 40

    local maps = UT.Filter(Map.Get(), function(v)
        return PersistentVars.RogueScore > threshold or v.Region == C.Regions.Act1
    end)

    local map = nil
    if #maps > 0 then
        local random = math.random(#maps)

        if UT.Contains(PersistentVars.RandomLog.Maps, random) then
            random = math.random(#maps)
        end
        LogRandom("Maps", random, 30)

        map = maps[random]
    end

    Scenario.Start(rogueTemp, map)
end

GameMode.DifficultyAppliedTo = {}

---@param enemy Enemy
function GameMode.ApplyDifficulty(enemy)
    if GameMode.DifficultyAppliedTo[enemy.GUID] then
        return
    end

    local partySizeMod = math.exp((Player.PartySize() - 4) * 0.2)

    local function scale(i, h)
        local x = i / 200
        local max_value = 30

        if h then
            x = x * 2
            max_value = 50
        end

        local rate = i / 1000
        return math.floor(max_value * (1 - math.exp(-rate * x)) * partySizeMod)
    end

    local mod = scale(PersistentVars.RogueScore, PersistentVars.HardMode)
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

    if mod > 0 then
        Osi.AddBoosts(enemy.GUID, "Ability(" .. map[1][1] .. ",+" .. mod .. ")", Mod.TableKey, Mod.TableKey)
        Osi.AddBoosts(enemy.GUID, "Ability(" .. map[2][1] .. ",+" .. mod .. ")", Mod.TableKey, Mod.TableKey)
    end
    if mod2 > 0 then
        Osi.AddBoosts(enemy.GUID, "Ability(" .. map[3][1] .. ",+" .. mod2 .. ")", Mod.TableKey, Mod.TableKey)
        Osi.AddBoosts(enemy.GUID, "Ability(" .. map[4][1] .. ",+" .. mod2 .. ")", Mod.TableKey, Mod.TableKey)
        Osi.AddBoosts(enemy.GUID, "IncreaseMaxHP(" .. mod2 .. "%)", Mod.TableKey, Mod.TableKey)
        Osi.AddBoosts(enemy.GUID, "IncreaseMaxHP(" .. mod2 * 10 .. ")", Mod.TableKey, Mod.TableKey)
    end
    if mod3 > 0 then
        Osi.AddBoosts(enemy.GUID, "Ability(" .. map[5][1] .. ",+" .. mod3 .. ")", Mod.TableKey, Mod.TableKey)
        Osi.AddBoosts(enemy.GUID, "Ability(" .. map[6][1] .. ",+" .. mod3 .. ")", Mod.TableKey, Mod.TableKey)
        Osi.AddBoosts(enemy.GUID, "AC(" .. mod3 .. ")", Mod.TableKey, Mod.TableKey)
    end

    WaitTicks(6, function()
        local entity = Ext.Entity.Get(enemy.GUID)

        if mod2 > 0 then
            local newLevel = math.max(entity.AvailableLevel.Level, math.min(12, mod2))
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

        local acMax = math.max(25, mod)
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

U.Osiris.On(
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
    GameMode.StartNext()

    if not PersistentVars.GUIOpen then
        Net.Send("OpenGUI")
    end
end)

Event.On(
    "ScenarioStopped",
    ifRogueLike(function(scenario)
        Schedule(GameMode.StartNext)
    end)
)

Event.On("ScenarioEnemySpawned", function(scenario, enemy)
    if scenario.Name ~= C.RoguelikeScenario then
        return
    end
    GameMode.ApplyDifficulty(enemy)
end)

Event.On("ScenarioRestored", function(scenario)
    if scenario.Name ~= C.RoguelikeScenario then
        return
    end
    for _, enemy in pairs(scenario.SpawnedEnemies) do
        GameMode.ApplyDifficulty(enemy)
    end
end)

Event.On("ScenarioEnded", function(scenario)
    if scenario.Name == C.RoguelikeScenario then
        GameMode.DifficultyAppliedTo = {}

        GameMode.UpdateRogueScore(scenario)

        ifRogueLike(function()
            if Config.AutoTeleport > 0 then
                Player.Notify(__("Teleporting back to camp in %d seconds.", Config.AutoTeleport), true)
                local timer = Defer(Config.AutoTeleport * 1000, function()
                    Player.PickupAll()
                    Player.ReturnToCamp()
                end)

                Event.On("ScenarioStarted", function(scenario)
                    timer.Source:Clear()
                end, true)
            end
        end)()
    end
end)

Schedule(function()
    External.Templates.AddScenario({
        Name = C.RoguelikeScenario,

        -- Spawns per Round
        Timeline = function()
            local lolcow = math.random() < 0.001
            if lolcow then
                local hasOX = Enemy.Find("OX_A")
                lolcow = hasOX and true or false
            end

            if lolcow then
                Defer(1000, function()
                    Player.Notify(__("You found the secret cow level!"))
                end)
            end

            return GameMode.GenerateScenario(PersistentVars.RogueScore, lolcow)
        end,

        Loot = C.LootRates,
    })
end)

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                       Party expansion                                       --
--                                                                                             --
-------------------------------------------------------------------------------------------------

function GameMode.RecruitOrigin(id)
    local function fixGale()
        Osi.SetFlag("Gale_Recruitment_HasMet_0657f240-7a46-e767-044c-ff8e1349744e", Player.Host())
        Osi.SetFlag(
            "ORI_Gale_Event_DisruptedWaypoint_eb1df53c-f315-fc93-9d83-af3d3aa7411d",
            "NULL_00000000-0000-0000-0000-000000000000"
        )
        Osi.Use(Player.Host(), "S_CHA_WaypointShrine_Top_PreRecruitment_b3c94e77-15ab-404c-b215-0340e398dac0", "")
        Osi.QuestAdd(C.OriginCharactersStarter.Gale, "ORI_COM_Gale")

        -- Osi.PROC_ORI_Gale_DoINTSetup()
        -- Osi.PROC_ORI_Gale_INTSetup()

        -- Osi.SetFlag(
        --     "ORI_State_Recruited_e78c0aab-fb48-98e9-3ed9-773a0c39988d",
        --     C.OriginCharactersStarter.Gale
        -- )
        -- Osi.SetFlag(
        --     "ORI_Gale_ControlledByUser_7b597686-21d1-43b6-9b4b-e2be86129ab6",
        --     C.OriginCharactersStarter.Gale
        -- )
        -- Osi.SetFlag("ORI_Gale_ControlledByUser_7b597686-21d1-43b6-9b4b-e2be86129ab6", GetHostCharacter())
        -- Osi.SetFlag("GALECAMP_c67a2f36-9984-4097-8c4e-0ba1661b56f2", "NULL_00000000-0000-0000-0000-000000000000")
        -- Osi.SetFlag("GALEPARTY_f173fce5-b79e-4970-b77c-2e3be02b7d34", "NULL_00000000-0000-0000-0000-000000000000")
        -- Osi.SetFlag(
        --     "ORI_Gale_State_WasRecruited_a56d3a51-2983-5f82-25f4-ad142948b133",
        --     "NULL_00000000-0000-0000-0000-000000000000"
        -- )
        -- Osi.RemoveStatus(C.OriginCharactersStarter.Gale, "INVULNERABLE_NOT_SHOWN")
        --
        -- Osi.SetOnStage("8ebd584c-97e3-42fd-b81f-80d7841ebdf3", 1) -- the waypoint
        -- Osi.SetFlag("ORI_Gale_State_HasRecruited_7548c517-72a8-b9c5-c9e9-49d8d9d71172", Player.Host())
        -- Osi.SetTag(C.OriginCharactersStarter.Gale, "d27831df-2891-42e4-b615-ae555404918b")
        -- Osi.SetTag(C.OriginCharactersStarter.Gale, "6fe3ae27-dc6c-4fc9-9245-710c790c396c")
        -- Osi.SetOnStage("c158fa86-3ecf-4d1b-a502-34618f77e3a9", 1)
        -- Osi.SetFlag("GLO_InfernalBox_State_CharacterHasBox_2ff44b15-a351-401b-8da9-cf42364af274", GetHostCharacter())
    end

    local function fixShart()
        Osi.QuestAdd(C.OriginCharactersStarter.ShadowHeart, "ORI_COM_ShadowHeart")
        Osi.PROC_ORI_Shadowheart_COM_Init()
    end

    local function fixMinthara()
        Osi.PROC_RemoveAllDialogEntriesForSpeaker(C.OriginCharactersSpecial.Minthara)
        Osi.DB_Dialogs(C.OriginCharactersSpecial.Minthara, "Minthara_InParty_13d72d55-0d47-c280-9e9c-da076d8876d8")
    end

    local function fixHalsin()
        -- Osi.PROC_GLO_Halsin_DebugReturnVictory()
        -- needs certain story outcome
        Osi.PROC_RemoveAllPolymorphs(C.OriginCharactersSpecial.Halsin)
        Osi.PROC_RemoveAllDialogEntriesForSpeaker(C.OriginCharactersSpecial.Halsin)
        Osi.DB_Dialogs(C.OriginCharactersSpecial.Halsin, "Halsin_InParty_890c2586-6b71-ca01-5bd6-19d533181c71")
    end

    local function recruit(character, dialog)
        Osi.PROC_ORI_SetupCamp(character, 1)
        Osi.SetOnStage(character, 1)

        Osi.RegisterAsCompanion(character, Player.Host())
        -- Osi.SetEntityEvent(character, "CampSwapped_WLDMAIN", 1)
        -- Osi.SetEntityEvent(character, "CAMP_CamperInCamp_WLDMAIN", 1)

        Osi.PROC_GLO_InfernalBox_SetNewOwner(Player.Host())
        Osi.PROC_GLO_InfernalBox_AddToOwner()

        if dialog then
            Osi.QRY_StartDialog_Fixed(dialog, character, Player.Host())
        end

        if Osi.IsPartyMember(character, 0) == 1 then
            return
        end

        Osi.SetFaction(character, C.CompanionFaction)
        Osi.Resurrect(character)

        -- reset level
        Osi.SetLevel(character, 1)
        Osi.RequestRespec(character)

        WaitTicks(20, function()
            local entity = Ext.Entity.Get(character)

            if not entity.Experience then
                entity:CreateComponent("Experience")
            end
            entity.Experience.TotalExperience = 0
            entity.AvailableLevel.Level = 1
            entity:Replicate("AvailableLevel")
            entity:Replicate("Experience")

            local teamExp = 0
            for _, character in pairs(GU.DB.GetPlayers()) do
                local entity = Ext.Entity.Get(character)
                if entity.Experience then
                    if entity.Experience.TotalExperience > teamExp then
                        teamExp = entity.Experience.TotalExperience
                    end
                end
            end

            Osi.AddExplorationExperience(character, teamExp)

            for _, item in pairs(entity.InventoryOwner.Inventories[1].InventoryContainer.Items) do
                GU.Object.Remove(item.Item.Uuid.EntityUuid)
            end
            entity:Replicate("InventoryOwner")

            Osi.TemplateAddTo("efcb70b7-868b-4214-968a-e23f6ad586bc", character, 1, 0) -- camp supply backpack
        end)
    end

    local uuid = C.OriginCharacters[id]
    if not uuid then
        L.Error("Character not found", id)
        return
    end

    ({
        Gale = function()
            recruit(uuid, "4b3ad930-fb84-09ff-eced-37265b7ba8c6")
            -- fixGale()
        end,
        ShadowHeart = function()
            recruit(uuid) -- "0e3f617e-1e5a-838c-6e3f-5f36d0470699")
            fixShart()
        end,
        Minthara = function()
            recruit(uuid, "13d72d55-0d47-c280-9e9c-da076d8876d8")
            fixMinthara()
        end,
        Halsin = function()
            fixHalsin()
            recruit(uuid, "890c2586-6b71-ca01-5bd6-19d533181c71")
        end,
        Astarion = function()
            recruit(uuid) -- "56bc2c0c-f02d-ec4c-ea0b-e7ceac19779a")
        end,
        Laezel = function()
            recruit(uuid) -- "623fcc21-96e1-79c2-5d06-9e48f3a378b3")
        end,
        Wyll = function()
            recruit(uuid) -- "c1a67c7e-ef27-417c-6ef8-ee4af60860cb")
        end,
        Karlach = function()
            recruit(uuid)
        end,
        Jaheira = function()
            recruit(uuid) -- "04443f0f-9c62-d474-a98a-3e13eec31c69")
        end,
        Minsc = function()
            recruit(uuid) -- "630440f5-b71a-8764-94e8-b62544254cff")
        end,
    })[id]()
end

function GameMode.OverridePartySize(size)
    Osi.SetMaxPartySizeOverride(size)
end
