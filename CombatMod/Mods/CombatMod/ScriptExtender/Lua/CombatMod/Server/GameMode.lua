-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                     Player interaction                                      --
--                                                                                             --
-------------------------------------------------------------------------------------------------

function GameMode.AskTutSkip()
    Config.BypassStory = true

    return Player.AskConfirmation("Skip to Camp?")
        .After(function(confirmed)
            if not confirmed then
                return
            end

            Osi.Use(Player.Host(), "S_TUT_Helm_ControlPanel_bcbba417-6403-40a6-aef6-6785d585df2a", "")
            return Defer(1000)
        end)
        .After(function()
            GameState.OnLoad(function()
                Defer(3000, function()
                    Osi.PROC_GLO_Jergal_MoveToCamp()
                    return Defer(1000)
                end).After(function()
                    -- Osi.TeleportToPosition(Player.Host(), -649.25, -0.0244140625, -184.75, "", 1, 1, 1)
                    -- Osi.TeleportTo(Player.Host(), C.NPCCharacters.Jergal, "", 1, 1, 1)
                    Osi.PROC_Camp_ForcePlayersToCamp()
                    Osi.AddGold(Player.Host(), 500)

                    External.LoadConfig()

                    if Config.ClearAllEntities then
                        StoryBypass.RemoveAllEntities()
                    end
                end)
            end, true)
        end)
end

function GameMode.AskOnboarding()
    PersistentVars.Active = false
    PersistentVars.Asked = true

    return Player.AskConfirmation("Welcome to %s! Start playing?", Mod.Prefix)
        .After(function(confirmed)
            if not confirmed then
                return
            end

            Event.Trigger("ModActive")

            return GameMode.AskEnableRogueMode()
        end)
        .After(function()
            if Player.Region() == C.Regions.Act0 then
                GameMode.AskTutSkip()
            end
        end)
end

function GameMode.AskEnableRogueMode()
    return Player.AskConfirmation([[
Play Roguelike mode?
Continuously create new battles.
You will gain a higher score with every completed fight.
Difficulty increases with the score.]]).After(function(confirmed)
        L.Debug("RogueMode", confirmed)

        PersistentVars.RogueModeActive = confirmed

        if PersistentVars.RogueScore == 0 then
            PersistentVars.RogueScore = math.min(100, (GE.GetHost().EocLevel.Level - 1) * 10) -- +10 per level, max 100
        end

        Event.Trigger("RogueModeChanged", PersistentVars.RogueModeActive)

        return confirmed
    end)
end

U.Osiris.On("AutomatedDialogStarted", 2, "after", function(dialog, instanceID)
    -- if
    --     US.Contains(dialog, {
    --         "GLO_Jergal_AD_AttackFromDialog",
    --         "GLO_Jergal_AD_AttackedByPlayer",
    --     })
    -- then
    --     if PersistentVars.Active then
    --         Net.Send("OpenGUI", {})
    --     end
    -- end

    if not PersistentVars.Active and dialog:match("GLO_Jergal_AD_AttackFromDialog") then
        GameMode.AskOnboarding()
    end
end)

U.Osiris.On("DialogActorJoined", 4, "after", function(dialog, instanceID, actor, speakerIndex)
    if
        US.Contains(dialog, {
            "TUT_Start_PAD_Start_",
            "TUT_Misc_PAD_OriginPod_PlayerEmpty_",
        }) and U.UUID.Equals(actor, Player.Host())
    then
        GameMode.AskOnboarding()
    end

    -- if dialog:match("CAMP_Jergal_") then
    --     if PersistentVars.Active and not PersistentVars.GUIOpen then
    --         Osi.DialogRemoveActorFromDialog(instanceID, actor)
    --         Osi.DialogRequestStopForDialog(dialog, actor)
    --
    --         if U.UUID.Equals(actor, Player.Host()) then
    --             Net.Send("OpenGUI", {})
    --         end
    --     end
    -- end
end)

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                       Rogue-like mode                                       --
--                                                                                             --
-------------------------------------------------------------------------------------------------

local function ifRogueLike(func)
    return IfActive(function(...)
        if PersistentVars.RogueModeActive then
            func(...)
        end
    end)
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
        local randomWeight = U.Random() * totalWeight
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
                    -- bias towards tiers with more enemies
                    local weight = tier.amount / 100 * 0.7 + 0.1
                    L.Debug("Tier", tier.name, weight)

                    table.insert(validTiers, { tier = tier, weight = weight })
                    totalWeight = totalWeight + weight
                end
            end
        end
        if #validTiers > 0 then
            local randomWeight = U.Random() * totalWeight
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
            local roundIndex = U.Random(1, numRounds)

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
                and U.Random() < emptyRoundChance
            then -- chance to skip adding a tier
                roundsSkipped[roundIndex] = true
                remainingValue = remainingValue + maxValue * emptyRoundChance
                return
            end

            local tier = selectTier(remainingValue)

            if remainingValue - tier.value >= 0 then
                table.insert(timeline[roundIndex], tier.name)
                remainingValue = remainingValue - tier.value
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

        -- ensure no two consecutive rounds exist
        for i = 2, #timeline do
            if #timeline[i] == 0 and #timeline[i - 1] == 0 then
                if Mod.Debug then
                    L.Error("Consecutive empty rounds", remainingValue, maxValue)
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

        Player.Notify(__("Your RogueScore increased: %d -> %d!", prev, score))
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
            .After(function(confirmed)
                if confirmed then
                    updateScore(score + baseScore)
                end
            end)
    end
end

function GameMode.StartNext()
    if S then
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
        map = maps[U.Random(#maps)]
    end

    Net.Send("OpenGUI")
    Scenario.Start(rogueTemp, map)
end

---@param enemy Enemy
function GameMode.ApplyDifficulty(enemy)
    local function scale(i, h)
        local x = i / 200
        local max_value = 30

        if h then
            x = x * 2
            max_value = 50
        end

        local rate = i / 1000
        return math.floor(max_value * (1 - math.exp(-rate * x)))
    end

    local mod = scale(PersistentVars.RogueScore, PersistentVars.HardMode)
    local mod2 = math.floor(mod / 2)

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
        Osi.AddBoosts(enemy.GUID, "AC(" .. math.min(6, math.ceil(mod2 / 2)) .. ")", Mod.TableKey, Mod.TableKey)
        Osi.AddBoosts(enemy.GUID, "IncreaseMaxHP(" .. mod2 .. "%)", Mod.TableKey, Mod.TableKey)
        Osi.AddBoosts(enemy.GUID, "IncreaseMaxHP(" .. mod2 * 10 .. ")", Mod.TableKey, Mod.TableKey)
    end
end

U.Osiris.On(
    "TeleportedToCamp",
    1,
    "after",
    ifRogueLike(function(uuid)
        if U.UUID.Equals(uuid, Player.Host()) then
            GameMode.StartNext()
            Player.PickupAll()
            Osi.PROC_LockAllUnlockedWaypoints()
        end
    end)
)

Event.On("RogueModeChanged", function(bool)
    if not bool then
        return
    end
    GameMode.StartNext()

    if not PersistentVars.GUIOpen then
        Net.Send("OpenGUI", {})
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
        GameMode.UpdateRogueScore(scenario)

        ifRogueLike(function()
            Player.Notify(__("Teleporting back to camp in %d seconds.", 30), true)
            local d1 = Defer(10000, function()
                Player.Notify(__("Teleporting back to camp in %d seconds.", 20), true)
            end)
            local d2 = Defer(30000, function()
                Player.PickupAll()
                Player.ReturnToCamp()
            end)

            Event.On("ScenarioStarted", function(scenario)
                d1.Source:Clear()
                d2.Source:Clear()
            end, true)
        end)()
    end
end)

Schedule(function()
    External.Templates.AddScenario({
        Name = C.RoguelikeScenario,

        -- Spawns per Round
        Timeline = function()
            local lolcow = U.Random() < 0.001
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

        Osi.PROC_GLO_InfernalBox_SetNewOwner(character)
        Osi.PROC_GLO_InfernalBox_AddToOwner()

        if dialog then
            Osi.QRY_StartDialog_Fixed(dialog, character, Player.Host())
        end

        if U.UUID.Equals(Osi.GetFaction(character), C.CompanionFaction) then
            return
        end

        Osi.SetFaction(character, C.CompanionFaction)
        Osi.Resurrect(character)

        -- reset level
        Osi.SetLevel(character, 1)
        Osi.RequestRespec(character)

        Async.WaitTicks(9, function()
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
