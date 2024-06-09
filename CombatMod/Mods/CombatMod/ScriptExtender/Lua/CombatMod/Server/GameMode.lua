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

            return Player.TeleportToAct("Act1")
        end)
        .After(function()
            Osi.PROC_GLO_Jergal_MoveToCamp()

            return Defer(1000)
        end)
        .After(function()
            -- Osi.TeleportToPosition(Player.Host(), -649.25, -0.0244140625, -184.75, "", 1, 1, 1)
            Osi.PROC_Camp_ForcePlayersToCamp()

            External.LoadConfig()
            return Defer(3000)
        end)
        .After(GameMode.AskRecruit)
end

function GameMode.AskOnboarding()
    PersistentVars.Active = false

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

function GameMode.AskRecruit()
    return Player.AskConfirmation("Recruit Origin characters?").After(function(confirmed)
        if not confirmed then
            return
        end

        local function fixGale()
            Osi.SetFlag("Gale_Recruitment_HasMet_0657f240-7a46-e767-044c-ff8e1349744e", Player.Host())
            Osi.SetFlag(
                "ORI_Gale_Event_DisruptedWaypoint_eb1df53c-f315-fc93-9d83-af3d3aa7411d",
                "NULL_00000000-0000-0000-0000-000000000000"
            )
            Osi.Use(Player.Host(), "S_CHA_WaypointShrine_Top_PreRecruitment_b3c94e77-15ab-404c-b215-0340e398dac0", "")
            Osi.QuestAdd("S_Player_Gale_ad9af97d-75da-406a-ae13-7071c563f604", "ORI_COM_Gale")

            -- Osi.PROC_ORI_Gale_DoINTSetup()
            -- Osi.PROC_ORI_Gale_INTSetup()

            -- Osi.SetFlag(
            --     "ORI_State_Recruited_e78c0aab-fb48-98e9-3ed9-773a0c39988d",
            --     "S_Player_Gale_ad9af97d-75da-406a-ae13-7071c563f604"
            -- )
            -- Osi.SetFlag(
            --     "ORI_Gale_ControlledByUser_7b597686-21d1-43b6-9b4b-e2be86129ab6",
            --     "S_Player_Gale_ad9af97d-75da-406a-ae13-7071c563f604"
            -- )
            -- Osi.SetFlag("ORI_Gale_ControlledByUser_7b597686-21d1-43b6-9b4b-e2be86129ab6", GetHostCharacter())
            -- Osi.SetFlag("GALECAMP_c67a2f36-9984-4097-8c4e-0ba1661b56f2", "NULL_00000000-0000-0000-0000-000000000000")
            -- Osi.SetFlag("GALEPARTY_f173fce5-b79e-4970-b77c-2e3be02b7d34", "NULL_00000000-0000-0000-0000-000000000000")
            -- Osi.SetFlag(
            --     "ORI_Gale_State_WasRecruited_a56d3a51-2983-5f82-25f4-ad142948b133",
            --     "NULL_00000000-0000-0000-0000-000000000000"
            -- )
            -- Osi.RemoveStatus("S_Player_Gale_ad9af97d-75da-406a-ae13-7071c563f604", "INVULNERABLE_NOT_SHOWN")
            --
            -- Osi.SetOnStage("8ebd584c-97e3-42fd-b81f-80d7841ebdf3", 1) -- the waypoint
            -- Osi.SetFlag("ORI_Gale_State_HasRecruited_7548c517-72a8-b9c5-c9e9-49d8d9d71172", Player.Host())
            -- Osi.SetTag("S_Player_Gale_ad9af97d-75da-406a-ae13-7071c563f604", "d27831df-2891-42e4-b615-ae555404918b")
            -- Osi.SetTag("S_Player_Gale_ad9af97d-75da-406a-ae13-7071c563f604", "6fe3ae27-dc6c-4fc9-9245-710c790c396c")
            -- Osi.SetOnStage("c158fa86-3ecf-4d1b-a502-34618f77e3a9", 1)
            -- Osi.SetFlag("GLO_InfernalBox_State_CharacterHasBox_2ff44b15-a351-401b-8da9-cf42364af274", GetHostCharacter())
        end

        local function fixShart()
            -- Osi.QuestAdd("S_Player_ShadowHeart_3ed74f06-3c60-42dc-83f6-f034cb47c679", "ORI_COM_ShadowHeart")
            Osi.PROC_ORI_Shadowheart_COM_Init()
        end

        local function fixMinthara()
            Osi.PROC_RemoveAllDialogEntriesForSpeaker("S_GOB_DrowCommander_25721313-0c15-4935-8176-9f134385451b")
            Osi.DB_Dialogs(
                "S_GOB_DrowCommander_25721313-0c15-4935-8176-9f134385451b",
                "Minthara_InParty_13d72d55-0d47-c280-9e9c-da076d8876d8"
            )
        end

        local function fixHalsin()
            -- TODO not working
            Osi.PROC_RemoveAllPolymorphs("S_GLO_Halsin_7628bc0e-52b8-42a7-856a-13a6fd413323")
            -- Osi.PROC_RemoveAllDialogEntriesForSpeaker("S_GLO_Halsin_7628bc0e-52b8-42a7-856a-13a6fd413323")
            -- Osi.DB_Dialogs(
            --     "S_GLO_Halsin_7628bc0e-52b8-42a7-856a-13a6fd413323",
            --     "Halsin_InParty_890c2586-6b71-ca01-5bd6-19d533181c71"
            -- )
        end

        for _, o in pairs(C.OriginCharactersStarter) do -- C.OriginCharacters for all
            Osi.PROC_ORI_SetupCamp(o, 1)
            Osi.SetFaction(o, "4abec10d-c2d1-a505-a09a-719c83999847")
            Osi.RegisterAsCompanion(o, Player.Host())
            Osi.SetEntityEvent(o, "CampSwapped_WLDMAIN", 1)
            Osi.SetEntityEvent(o, "CAMP_CamperInCamp_WLDMAIN", 1)
            Osi.SetFlag("GLO_InfernalBox_State_CharacterHasBox_2ff44b15-a351-401b-8da9-cf42364af274", o)
        end

        fixGale()
        fixShart()
        -- fixHalsin()
        -- fixMinthara()
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

        PersistentVars.RogueScore = (GE.GetHost().EocLevel.Level - 1) * 10 -- +10 per level

        Event.Trigger("RogueModeChanged", PersistentVars.RogueModeActive)

        return confirmed
    end)
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Events                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

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

Event.On("ModActivated", function()
    if not PersistentVars.RogueModeActive then
        GameMode.AskEnableRogueMode()
    end
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

    -- Define tiers and their corresponding difficulty values
    local tiers = {
        { name = C.EnemyTier[1], value = 4, amount = #Enemy.GetByTier(C.EnemyTier[1]) },
        { name = C.EnemyTier[2], value = 10, amount = #Enemy.GetByTier(C.EnemyTier[2]) },
        { name = C.EnemyTier[3], value = 20, amount = #Enemy.GetByTier(C.EnemyTier[3]) },
        { name = C.EnemyTier[4], value = 32, amount = #Enemy.GetByTier(C.EnemyTier[4]) },
        { name = C.EnemyTier[5], value = 42, amount = #Enemy.GetByTier(C.EnemyTier[5]) },
        { name = C.EnemyTier[6], value = 69, amount = #Enemy.GetByTier(C.EnemyTier[6]) },
    }

    if cow then
        tiers = { { name = "OX_A", value = 4, amount = 100 } }
    end

    score = score >= tiers[1].value and score or tiers[1].value

    -- Weighted random function to bias towards a preferred number of rounds
    local function weightedRandom(maxValue)
        local weights = {}
        local totalWeight = 0
        for i = minRounds, maxRounds do
            local weight = 1 / (math.abs(i - preferredRounds) + 1) -- Adjusted weight calculation
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

    -- Function to select a tier based on amount of enemies in tier
    local function selectTier(remainingValue)
        local validTiers = {}
        local totalWeight = 0
        for i, tier in ipairs(tiers) do
            if remainingValue >= tier.value then
                -- Bias towards tiers with more enemies
                local weight = (tier.amount - 25) / (100 - 25) * 0.7 + 0.1
                L.Debug("Tier", tier.name, weight)

                table.insert(validTiers, { tier = tier, weight = weight })
                totalWeight = totalWeight + weight
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

        return tiers[1] -- Fallback to the lowest tier
    end

    -- Function to generate a random timeline with bias and possible empty rounds
    local function generateTimeline(maxValue, failed)
        failed = failed + 1
        if failed > 100 then
            L.Error("Failed to generate timeline", maxValue)
            return {}
        end

        local timeline = {}
        local numRounds = weightedRandom()
        local remainingValue = maxValue
        -- Initialize rounds with empty tables
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

            -- Add a chance for the round to remain empty, except for the first round
            if
                roundIndex > 1
                and not roundsSkipped[roundIndex - 1]
                and #timeline[roundIndex] == 0
                and U.Random() < emptyRoundChance
            then -- Chance to skip adding a tier
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

        -- Distribute the total value randomly across rounds
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

        -- Ensure the first round is not empty
        if #timeline[1] == 0 then
            if Mod.Debug then
                L.Error("Empty first round", remainingValue, maxValue)
            end
            return generateTimeline(maxValue, failed)
        end

        -- Ensure no two consecutive rounds exist
        for i = 2, #timeline do
            if #timeline[i] == 0 and #timeline[i - 1] == 0 then
                if Mod.Debug then
                    L.Error("Consecutive empty rounds", remainingValue, maxValue)
                end
                return generateTimeline(maxValue, failed)
            end
        end

        return timeline
    end

    return generateTimeline(score, 0)
end

function GameMode.UpdateRogueScore(scenario)
    -- Always has 1 round more than the timeline because of CombatRoundStarted
    local endRound = scenario.Round - 1

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

    local diff = endRound - scenario:TotalRounds()

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

    local maps = UT.Filter(Map.Get(), function(v)
        return PersistentVars.RogueScore > 20 or v.Region == C.Regions.Act1
    end)

    local map = nil
    if #maps > 0 then
        map = maps[U.Random(#maps)]
    end

    Scenario.Start(rogueTemp, map)
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

Event.On("ScenarioEnded", function(scenario)
    if scenario.Name == C.RoguelikeScenario then
        GameMode.UpdateRogueScore(scenario)

        ifRogueLike(function()
            Player.Notify(__("Teleporting back to camp in %d seconds.", 60), true)
            local d1 = Defer(30000, function()
                Player.Notify(__("Teleporting back to camp in %d seconds.", 30), true)
            end)
            local d2 = Defer(60000, function()
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
