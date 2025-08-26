-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                          Story? No!                                         --
--                                                                                             --
-------------------------------------------------------------------------------------------------

-- story bypass skips most/all dialogues, combat and interactions that aren't related to a scenario
local function ifBypassStory(func)
    return function(...)
        if Config.BypassStory then
            func(...)
        end
    end
end

function StoryBypass.CancelDialog(dialog, instanceID)
    for _, player in pairs(GU.DB.GetPlayers()) do
        Osi.DialogRemoveActorFromDialog(instanceID, player)
        Osi.DialogRequestStopForDialog(dialog, player)
    end
end

function StoryBypass.EndLongRest()
    Osi.PROC_Camp_LongRestFinishForAllPlayers()
    -- Osi.PROC_Camp_EveryoneWakeup()
    for _, p in pairs(GU.DB.GetPlayers()) do
        Osi.RemoveStatus(p, "LONG_REST")
    end
    Osi.PROC_Camp_SetModeToDay()
end

function StoryBypass.UnblockTravel(entity)
    Osi.RemoveStatus(entity.Uuid.EntityUuid, "TRAVELBLOCK_CANTMOVE")
    Osi.RemoveStatus(entity.Uuid.EntityUuid, "TRAVELBLOCK_BLOCKEDZONE")

    if entity.ServerCharacter then
        entity.ServerCharacter.PlayerData.IsInDangerZone = false
    end
    entity.CanTravel.ErrorFlags = {}
    entity.CanTravel.field_2 = 0
    entity:Replicate("CanTravel")

    Osi.UnblockFlee(entity.Uuid.EntityUuid)
end

function StoryBypass.RestoreFlags()
    L.Debug("RestoreFlags")
    -- If we just came from Netherbrain, we need to clear flags preventing Long Rest
    Osi.ClearFlag(
        "CURRENTREGION_END_Main_140b4d3e-6cc7-48cb-b66f-dbc4eba710e1",
        "NULL_00000000-0000-0000-0000-000000000000",
        0
    )
    Osi.ClearFlag(
        "END_BrainBattle_Event_Started_3cd63c2e-7343-45dd-9137-4cabca2179a6",
        "NULL_00000000-0000-0000-0000-000000000000",
        0
    )
    Osi.ClearFlag(
        "END_General_State_CurrentlyInBrainBattle_0d7205b2-0d55-4540-8737-543253873cd6",
        "NULL_00000000-0000-0000-0000-000000000000",
        0
    )
    Osi.PROC_END_BrainBattle_ClearBrainBattle()
    Osi.ClearFlag(
        "END_General_State_Started_a0fd5f91-e4b3-4d01-84d3-9ff484139e99",
        "NULL_00000000-0000-0000-0000-000000000000",
        0
    )
    Osi.DB_Camp_Unlocked(1)
    Osi.SetLongRestAvailable(1)
    Osi.SetTag("S_GLO_JergalAvatar_0133f2ad-e121-4590-b5f0-a79413919805", "TRADER_91d5ebc6-91ea-44db-8a51-216860d69b5b")
    Osi.PROC_GLO_Jergal_SetDialog("CAMP_Jergal_7f4acd9b-15c0-81fe-9409-623634ec3ed3")

    Osi.SetJoinBlock(0)

    for _, player in pairs(GU.DB.GetPlayers()) do
        Osi.SetIsInDangerZone(player, 0)
        Osi.PROC_SetBlockDismiss(player, 0)
        Osi.DB_InDangerZone:Delete(player, "ENDGAME")

        StoryBypass.ConvinceCharacterToBehave(player)
    end
end

function StoryBypass.ConvinceCharacterToBehave(character)
    L.Debug("ConvinceCharacterToBehave", character)
    if character == C.OriginCharactersStarter.Karlach then
        Osi.DB_OriginInPartyDialog(
            C.OriginCharactersStarter.Karlach,
            "Karlach_InParty_12459660-b66e-9b0b-9963-670e0993543d"
        )

        Osi.RemoveStatus(character, "ORI_KARLACH_ENRAGE")
        Osi.AddBoost(character, "StatusImmunity(ORI_KARLACH_ENRAGE)", Mod.TableKey, Mod.TableKey)
    elseif character == C.OriginCharactersStarter.Gale then
        Osi.DB_OriginInPartyDialog(C.OriginCharactersStarter.Gale, "Gale_InParty_6beb1b10-845f-49fa-6d6d-f425eaa42574")
    elseif character == C.OriginCharactersStarter.Astarion then
        Osi.DB_OriginInPartyDialog(
            C.OriginCharactersStarter.Astarion,
            "Astarion_InParty_53aba16e-55bb-a0fc-a444-522e237dbe46"
        )
    elseif character == C.OriginCharactersStarter.Laezel then
        Osi.DB_OriginInPartyDialog(
            C.OriginCharactersStarter.Laezel,
            "Laezel_InParty_93bf58f5-5111-9730-1ee2-62dfb0b00c96"
        )
    elseif character == C.OriginCharactersStarter.Wyll then
        Osi.DB_OriginInPartyDialog(C.OriginCharactersStarter.Wyll, "Wyll_InParty_6dff0a1f-1a51-725d-6e9a-52b5742ba9e6")
    elseif character == C.OriginCharactersStarter.ShadowHeart then
        Osi.DB_OriginInPartyDialog(
            C.OriginCharactersStarter.ShadowHeart,
            "ShadowHeart_InParty_95ca3833-09d0-5772-b16a-c7a5e9208fe5"
        )
    elseif character == C.OriginCharactersSpecial.Halsin then
        Osi.DB_OriginInPartyDialog(
            C.OriginCharactersSpecial.Halsin,
            "Halsin_InParty_890c2586-6b71-ca01-5bd6-19d533181c71"
        )
    elseif character == C.OriginCharactersSpecial.Minthara then
        Osi.DB_OriginInPartyDialog(
            C.OriginCharactersSpecial.Minthara,
            "Minthara_InParty_13d72d55-0d47-c280-9e9c-da076d8876d8"
        )
        Osi.SetFaction(C.OriginCharactersSpecial.Minthara, C.CompanionFaction)
    elseif character == C.OriginCharactersSpecial.Jaheira then
        Osi.DB_PermaDefeated:Delete(C.OriginCharactersSpecial.Jaheira)
        Osi.ClearTag(C.OriginCharactersSpecial.Jaheira, "BLOCK_RESURRECTION_22a75dbb-1588-407e-b559-5aa4e6d4e6a6")
        Osi.SetHasDialog(C.OriginCharactersSpecial.Jaheira, 1)
        Osi.DB_OriginInPartyDialog(
            C.OriginCharactersSpecial.Jaheira,
            "Jaheira_InParty_e97481ba-961c-50a7-c54f-d34d6b75044d"
        )
    elseif character == C.OriginCharactersSpecial.Minsc then
        Osi.DB_OriginInPartyDialog(
            C.OriginCharactersSpecial.Minsc,
            "Minsc_InParty_d0554ced-ca60-938b-362c-07b0c77610d7"
        )
    elseif character == C.OriginCharactersSpecial.Alfira then
        Osi.DB_OriginInPartyDialog(
            C.OriginCharactersSpecial.Alfira,
            "DEN_Bard_InParty_3c71c397-b378-340b-0da9-ef3d17d14423"
        )
    end
end

function StoryBypass.AllowRemoval(entity)
    return entity.IsCharacter
        and GC.IsNonPlayer(entity.Uuid.EntityUuid)
        and not GU.Object.IsOwned(entity.Uuid.EntityUuid)
        and not entity.PartyMember
        and not U.UUID.Equals(C.NPCCharacters.Jergal, entity.Uuid.EntityUuid) -- No
        and not U.UUID.Equals(C.NPCCharacters.Emperor, entity.Uuid.EntityUuid) -- Gameover if dead
        and not U.UUID.Equals("4f6e63a1-b143-46b1-ac0e-834494dfdc6a", entity.Uuid.EntityUuid) -- Oliver quest endless loop
        and not (entity.ServerCharacter and entity.ServerCharacter.Template.Name:match("Player"))
end

function StoryBypass.RemoveAutosave()
    L.Info("Removing autosave triggers")
    L.Dump(Osi.DB_AutoSaveTrigger:Get(nil))
    L.Dump(Osi.DB_AutosaveGroup:Get(nil, nil))
    Osi.DB_AutosaveGroup:Delete(nil, nil)
    Osi.DB_AutoSaveTrigger:Delete(nil)
end

function StoryBypass.RemoveAllEntities()
    StoryBypass.ExpLock.ResumeTemporary()

    Osi.PROC_MOO_Execution_StartFallbackExecutionCombat() -- prevent infinite timer loop
    -- Osi.PROC_CRE_BloodOfLathander_BarrierTrap_TurnOff()

    -- give netherstones to quest progress set flags
    Osi.PROC_GEN_OrinsAbduction_InCampAbductions_Disable()
    Osi.PROC_GEN_OrinsAbduction_Debug_SetKilledGortash()
    Osi.ToInventory("S_COL_CrownController_Ketheric_06b8891b-e71c-423b-8482-2680c3c16a4d", Player.Host())
    Osi.ToInventory("S_WYR_CrownController_Gortash_383be300-d328-4152-86df-4927482d1fd7", Player.Host())
    Osi.ToInventory("S_LOW_CrownController_Orin_360b0dfd-8e0b-48d2-a079-fcf68c104d6b", Player.Host())

    local toRemove = table.filter(Ext.Entity.GetAllEntitiesWithUuid(), StoryBypass.AllowRemoval)

    for i, e in ipairs(toRemove) do
        L.Debug("Removing", e.Uuid.EntityUuid, e.ServerCharacter.Template.Name)
        GU.Object.Remove(e.Uuid.EntityUuid)
    end

    GU.Object.Remove("S_GLO_DriderMoonlantern_4591d212-8f1b-4b85-880c-dc94f76702f4") -- will endlessly loop dialog

    L.Info("Clear All Entities", "Removed " .. tostring(#toRemove) .. " entities")

    table.insert(PersistentVars.RegionsCleared, Player.Region())

    return toRemove
end

function StoryBypass.ClearArea(character)
    if Ext.Entity.Get(character).CampPresence then
        L.Error("ClearArea", "Cannot clear area while in camp.")
        return
    end

    local nearby = GE.GetNearby(character, 150, true)

    for _, v in pairs(nearby) do
        if v.Entity.IsCharacter and not v.Entity.PartyMember and GC.IsOrigin(v.Guid) then
            Osi.SetOnStage(v.Guid, 0)
        end
    end

    local toRemove = table.filter(nearby, function(v)
        return StoryBypass.AllowRemoval(v.Entity)
    end)

    for _, batch in pairs(UT.Batch(toRemove, math.ceil(#toRemove / 5))) do
        Schedule(function()
            for _, b in pairs(batch) do
                GU.Object.Remove(b.Guid)
            end
        end)
    end

    local objects = table.filter(nearby, function(v)
        return v.Entity.ServerItem and not GU.Object.IsOwned(v.Guid) and not Scenario.IsHelper(v.Guid)
    end)
    for _, batch in pairs(UT.Batch(objects, math.ceil(#objects / 5))) do
        Schedule(function()
            for _, b in pairs(batch) do
                -- Osi.CreateSurface(b.Guid, "None", 10, -1)
                local removeItems = {
                    "40c79f34-a39d-4495-9145-08a16cde2159", -- S_IRN_LobbyLadder_000
                    "8f766750-9d29-4170-b898-57b95e92e3c0", -- S_SHA_PUZ_SilentLibrary_Librarian_Item
                }
                if table.contains(removeItems, b.Guid) then
                    GU.Object.Remove(b.Guid)
                end

                if b.Entity.ServerItem then
                    if
                        b.Entity.ServerItem.IsLadder
                        or b.Entity.ServerItem.IsDoor
                        or table.contains(get(Ext.Stats.Get(b.Entity.ServerItem.Stats), "Flags", {}), "Torch")
                    then
                        b.Entity.ServerItem.CanBePickedUp = false
                        b.Entity.ServerItem.CanBeMoved = false
                        if b.Entity.ServerItem.IsDoor then
                            Osi.Unlock(b.Guid)
                            Osi.Open(b.Guid)
                        end
                    elseif
                        b.Entity.ServerItem.CanBePickedUp
                        or b.Entity.ServerDisarmAttempt
                        or b.Entity.UseAction
                        or b.Entity.ServerItem.Template.Id == C.ScenarioHelper.TemplateId
                        or b.Entity.ServerItem.Template.Id == C.MapHelper
                    then -- TODO remove more CanUse objects
                        GU.Object.Remove(b.Guid)
                    elseif b.Entity.ServerItem.CanUse then
                        b.Entity.ServerItem.CanUse = false
                    end

                    b.Entity.ServerItem.CanBeMoved = false

                    xpcall(function()
                        if b.Entity.InventoryOwner then
                            for _, item in pairs(b.Entity.InventoryOwner.Inventories[1].InventoryContainer.Items) do
                                GU.Object.Remove(item.Item.Uuid.EntityUuid)
                            end
                        end
                    end, L.Error)

                    if b.Entity.Health then
                        b.Entity.Health.Hp = 666
                        b.Entity.Health.MaxHp = 666
                        b.Entity:Replicate("Health")
                        b.Entity.Resistances.Resistances = table.map(
                            { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 }, -- 14
                            function()
                                return {
                                    "ImmuneToMagical",
                                    "ImmuneToNonMagical",
                                }
                            end
                        )
                        b.Entity:Replicate("Resistances")
                        Osi.ApplyStatus(b.Guid, "INVULNERABLE_NOT_SHOWN", -1)
                    end
                end
            end
        end)
    end

    -- Osi.RemoveSurfaceLayer(character, "Cloud", 100)
    -- Osi.RemoveSurfaceLayer(character, "Ground", 100)
    -- Osi.CreateSurface(character, "None", 100, -1)
    -- Osi.ClearTag(v.Guid, "867f3a1e-1e4b-48c2-869e-343415231727")
    -- Osi.ClearTag(v.Guid, "f0020818-86f1-4ee9-a5a9-9ace9ecc9010")
    -- Osi.Resurrect(v.Guid)
    -- Osi.SetHitpointsPercentage(v.Guid, 100)
    -- L.Dump(Osi.IsDestroyed(v.Guid))
end

function StoryBypass.ClearSurfaces(guid, strength)
    local x, y, z = Osi.GetPosition(guid)

    local function generateSpiral(x, y, numPoints, angleIncrement, radiusIncrement)
        local points = {}
        local angle = 0
        local radius = 0
        for i = 1, numPoints do
            local newX = x + radius * math.cos(angle)
            local newY = y + radius * math.sin(angle)
            table.insert(points, { newX, newY })
            angle = angle + angleIncrement
            radius = radius + radiusIncrement
        end
        return points
    end

    local centerX, centerY = x, z
    local numPoints = strength or 20
    local angleIncrement = math.pi / 4 -- Adjust as needed
    local radiusIncrement = 1 -- Adjust as needed
    local spiralPoints = generateSpiral(centerX, centerY, numPoints, angleIncrement, radiusIncrement)

    for i, point in ipairs(spiralPoints) do
        if i % 2 == 0 then
            WaitTicks(4 * i, function()
                local nx, ny, nz = Osi.FindValidPosition(point[1], y, point[2], 100, C.NPCCharacters.Volo, 1) -- avoiding dangerous surfaces
                -- Osi.CreateSurfaceAtPosition(nx, ny, nz, "None", 100, -1)
                -- Osi.RemoveSurfaceLayerAtPosition(nx, ny, nz, "Ground", 100)
                Osi.TeleportToPosition(guid, nx, y, nz)
                Osi.UseSpell(guid, "TOT_Zone_Clear", guid)
                -- Osi.RequestPing(nx, ny, nz, "", character)
            end):Catch(function() end)
        end
    end

    return WaitTicks(5 * #spiralPoints, function()
        Osi.TeleportToPosition(guid, x, y, z)
        return true
    end)
end

do -- EXP Lock
    StoryBypass.ExpLock = {}

    local entityData = {}
    local function snapEntity(entity)
        if entity.Experience == nil then
            return
        end

        entityData[entity.Uuid.EntityUuid] = {
            exp = UT.Clean(entity.Experience),
            level = entity.EocLevel.Level,
            avail = entity.AvailableLevel.Level,
        }
    end

    function StoryBypass.ExpLock.SnapshotEntitiesExp()
        entityData = {}
        for i, e in pairs(GE.GetParty()) do
            snapEntity(e)
        end
    end

    local paused = false
    function StoryBypass.ExpLock.IsPaused()
        return paused
    end

    function StoryBypass.ExpLock.Pause()
        paused = true
        L.Debug("ExpLock Paused")
    end
    local debouncedSnap = Debounce(1000, StoryBypass.ExpLock.SnapshotEntitiesExp)

    function StoryBypass.ExpLock.Resume()
        paused = false
        StoryBypass.ExpLock.SnapshotEntitiesExp()
        L.Debug("ExpLock Resumed")
    end

    function StoryBypass.ExpLock.ResumeTemporary()
        if paused then
            StoryBypass.ExpLock.DebouncedPause()
        end

        StoryBypass.ExpLock.Resume()
    end

    function StoryBypass.ExpLock.PauseTemporary()
        if not paused then
            StoryBypass.ExpLock.DebouncedResume()
        end

        StoryBypass.ExpLock.Pause()
    end

    StoryBypass.ExpLock.DebouncedResume = Async.Debounce(1000, StoryBypass.ExpLock.Resume)
    StoryBypass.ExpLock.DebouncedPause = Async.Debounce(1000, StoryBypass.ExpLock.Pause)

    local entityListener = nil

    local function unsubscribeEntitiesExp()
        if entityListener then
            Ext.Entity.Unsubscribe(entityListener)
            entityListener = nil
        end
    end

    local function subscribeEntitiesExp()
        if not entityListener then
            StoryBypass.ExpLock.SnapshotEntitiesExp()
            entityListener = Ext.Entity.Subscribe(
                "Experience",
                ifBypassStory(function(e)
                    if paused or not e.Experience then
                        return
                    end

                    local data = entityData[e.Uuid.EntityUuid]

                    if data then
                        local exp = data.exp
                        local level = data.level
                        local avail = data.avail
                        if e.Experience.CurrentLevelExperience == exp.CurrentLevelExperience then
                            L.Debug("Experience unchanged", e.Uuid.EntityUuid)
                            return
                        end

                        e.EocLevel.Level = level
                        e.AvailableLevel.Level = avail

                        e.Experience.CurrentLevelExperience = exp.CurrentLevelExperience
                        e.Experience.TotalExperience = exp.TotalExperience
                        e.Experience.NextLevelExperience = exp.NextLevelExperience
                        -- e.Experience.field_28 = exp.field_28 -- dunno

                        e:Replicate("EocLevel")
                        e:Replicate("AvailableLevel")
                        e:Replicate("Experience")
                        L.Debug("Experience restored", e.Uuid.EntityUuid)
                    end

                    debouncedSnap()
                end)
            )
        end
    end

    subscribeEntitiesExp()

    Event.On("ScenarioRoundStarted", StoryBypass.ExpLock.Pause)
    Event.On("ScenarioRestored", function(scenario)
        if scenario:HasStarted() then
            StoryBypass.ExpLock.Pause()
        end
    end)

    local toggleCamp = Throttle(100, function()
        if Scenario.HasStarted() then
            StoryBypass.ExpLock.Pause()
            return
        end

        if Player.InCamp() then
            StoryBypass.ExpLock.Pause()
        else
            StoryBypass.ExpLock.Resume()
        end
        WaitTicks(12, function()
            if Player.InCamp() then
                StoryBypass.ExpLock.Pause()
            else
                StoryBypass.ExpLock.Resume()
            end
        end)
    end)

    Ext.Osiris.RegisterListener("TeleportedFromCamp", 1, "before", toggleCamp)
    Ext.Osiris.RegisterListener("TeleportedToCamp", 1, "before", toggleCamp)
    GameState.OnLoad(toggleCamp)
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Events                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

local actors = {}
local handlers = {}
local function cancelDialog(dialog, instanceID)
    if handlers[instanceID] then
        handlers[instanceID](dialog, instanceID)
        return
    end

    handlers[instanceID] = Debounce(10, function(dialog, instanceID)
        Schedule(function()
            actors[instanceID] = nil
            handlers[instanceID] = nil
        end)
        local dialogActors = actors[instanceID]

        if table.find(dialogActors, Enemy.IsValid) then
            return
        end

        for _, actor in ipairs(dialogActors) do
            local paidActor = string.contains(actor, {
                "_Daisy_",
                "Jergal",
                -- "OathbreakerKnight",
                -- "Orpheus",
                -- "Volo",
            })
            if paidActor then
                return
            end
        end

        local hasRemovable = table.filter(dialogActors, function(actor)
            return GC.IsNonPlayer(actor) and Osi.IsAlly(Player.Host(), actor) ~= 1
        end)

        local hasPlayable = table.filter(dialogActors, function(actor)
            return GC.IsPlayable(actor)
        end)

        if #hasPlayable == 0 then
            return
        end

        L.Dump("cancelDialog", dialog, instanceID, dialogActors, hasRemovable, hasPlayable)

        StoryBypass.CancelDialog(dialog, instanceID)
        -- if #hasRemovable > 0 then
        -- end

        for _, actor in ipairs(hasRemovable) do
            L.Debug("Removing", actor)
            Osi.DialogRemoveActorFromDialog(instanceID, actor)
            Osi.DialogRequestStopForDialog(dialog, actor)

            Player.Notify(
                __(
                    "Skipped interaction with %s",
                    Osi.ResolveTranslatedString(Ext.Entity.Get(actor).DisplayName.NameKey.Handle.Handle)
                ),
                true
            )
            L.Info("Bypass Story", "Dialog cancelled " .. dialog)
        end

        if #hasPlayable == #dialogActors then
            Osi.DialogRequestStopForDialog(dialog, dialogActors[1])
        end
    end)

    handlers[instanceID](dialog, instanceID)
end

Ext.Osiris.RegisterListener(
    "DialogActorJoined",
    4,
    "after",
    ifBypassStory(function(dialog, instanceID, actor, speakerIndex)
        L.Debug("DialogActorJoined", dialog, actor)

        if
            dialog:match("CAMP_")
            or dialog:match("^Hireling_")
            or dialog:match("Tadpole")
            or dialog:match("Recruitment")
            or dialog:match("InParty")
            or dialog:match("^BHVR_WRLD")
            or dialog:match("^GLO_Avatar")
            or dialog:match("^GLO_MagicMirror")
        then
            return
        end

        if Osi.DialogIsCrimeDialog(instanceID) == 1 then
            Osi.CrimeClearAll()
        end

        actors[instanceID] = actors[instanceID] or {}
        table.insert(actors[instanceID], actor)
        cancelDialog(dialog, instanceID)
    end)
)

Ext.Osiris.RegisterListener(
    "UseFinished",
    3,
    "before",
    ifBypassStory(function(character, item, sucess)
        if GC.IsNonPlayer(character, true) then
            return
        end
        if Osi.IsLocked(item) == 1 then
            L.Debug("Auto unlocking", item)
            Player.Notify(__("Auto unlocking"), true)
            Osi.Unlock(item, character)
        end
        if Osi.IsTrapArmed(item) == 1 then
            L.Debug("Auto disarming", item)
            Player.Notify(__("Auto disarming"), true)
            Osi.SetTrapArmed(item, 0)
        end
    end)
)
Ext.Osiris.RegisterListener(
    "EnteredCombat",
    2,
    "after",
    ifBypassStory(function(object, combatGuid)
        if not Scenario.Current() and GC.IsNonPlayer(object) and GC.IsValid(object) then
            Osi.LeaveCombat(object)
            GU.Object.Remove(object)
            Player.Notify(
                __(
                    "Skipped combat with %s",
                    Osi.ResolveTranslatedString(Ext.Entity.Get(object).DisplayName.NameKey.Handle.Handle)
                ),
                true
            )
        end

        if object == "S_END_CrownProxy_b06e8326-a034-4480-8652-6a66b3bd7d0a" then
            L.Debug("Removing story object ", object)
            Osi.TurnBasedTimerCancel("S_END_CrownProxy_b06e8326-a034-4480-8652-6a66b3bd7d0a", "END_NautiloidCountdown")
            Osi.DB_END_BrainBattle_TadpoleReminderActive:Delete(1)
            Osi.LeaveCombat(object)
            GU.Object.Remove(object)
        elseif object == "S_END_Nautiloid_002_f50dc928-bb2d-48b6-a2dd-98fce0a47d28" then
            L.Debug("Removing story object ", object)
            Osi.RemoveStatus(object, "END_NAUTILOID_SPAWN_VFX", "NULL_00000000-0000-0000-0000-000000000000")
            Osi.LeaveCombat(object)
            GU.Object.Remove(object)
        end
    end)
)

Ext.Osiris.RegisterListener(
    "Resurrected",
    1,
    "after",
    ifBypassStory(function(character)
        if not Scenario.Current() and GC.IsNonPlayer(character) and GC.IsValid(character) then
            GU.Object.Remove(character)
            Player.Notify(
                __(
                    "Skipped combat with %s",
                    Osi.ResolveTranslatedString(Ext.Entity.Get(character).DisplayName.NameKey.Handle.Handle)
                ),
                true
            )
        end
    end)
)

Ext.Entity.Subscribe(
    "CanTravel",
    ifBypassStory(function(e)
        if e.PartyMember then
            StoryBypass.UnblockTravel(e)
        end
    end)
)

Ext.Osiris.RegisterListener(
    "TeleportToFromCamp",
    1,
    "after",
    ifBypassStory(function(character)
        if not GC.IsPlayable(character) then
            return
        end

        Schedule(function()
            if not Ext.Entity.Get(C.NPCCharacters.Jergal).CampPresence then
                Osi.PROC_GLO_Jergal_MoveToCamp()
                Osi.PROC_GLO_Jergal_Appear()
                Osi.PROC_Foop("S_GLO_JergalAvatar_0133f2ad-e121-4590-b5f0-a79413919805")
            end
        end)

        -- workaround for blocked travel
        -- TODO fix this
        -- Defer(1000, function()
        --     if Scenario.Current() and not S.OnMap then
        --         L.Error("Teleport workaround", character)
        --         -- Scenario.Teleport(character)
        --     end
        -- end)

        if not Ext.Entity.Get(character).CampPresence or not Scenario.Current() then
            L.Debug("ReturnToCamp", character)
            -- need ~2 ticks for changing CampPresence
            WaitTicks(3, function()
                Player.ReturnToCamp()
            end)
        end
    end)
)

Ext.Osiris.RegisterListener(
    "LongRestStarted",
    0,
    "after",
    ifBypassStory(function()
        Defer(2000, function()
            local dialog, instance = Osi.SpeakerGetDialog(Player.Host(), 1)
            if dialog then
                StoryBypass.CancelDialog(dialog, instance)
            end
            StoryBypass.EndLongRest()
        end)
    end)
)

Event.On(
    "MapTeleported",
    ifBypassStory(function(_, character)
        if Scenario.HasStarted() then
            return
        end

        if U.UUID.Equals(Player.Host(), character) then
            StoryBypass.ClearArea(Player.Host())
        end

        Osi.RemoveStatus(character, "SURPRISED", C.NullGuid)
        Osi.RemoveStatus(character, "END_NETHERBRAIN_SLOW", C.NullGuid)
    end)
)
Event.On(
    "ScenarioMapEntered",
    ifBypassStory(function()
        StoryBypass.ClearArea(Player.Host())
    end)
)

Event.On(
    "ReturnToCamp",
    ifBypassStory(function()
        StoryBypass.RestoreFlags()
        for _, p in pairs(GU.DB.GetPlayers()) do
            StoryBypass.ConvinceCharacterToBehave(p)
        end
    end)
)
GameState.OnLoad(ifBypassStory(function()
    StoryBypass.RestoreFlags()
    for _, p in pairs(GU.DB.GetPlayers()) do
        StoryBypass.ConvinceCharacterToBehave(p)
    end
end))

local function removeAllEntities()
    if Scenario.HasStarted() or not Config.ClearAllEntities then
        return
    end

    if Player.Region() == C.Regions.Act0 then
        return
    end

    if table.contains(PersistentVars.RegionsCleared, Player.Region()) then
        return
    end

    Player.Notify(__("Clearing all entities"), true)

    StoryBypass.RemoveAllEntities()

    Osi.Resurrect(C.OriginCharacters.Halsin) -- Halsin will be dead once entering Act 2 for the first time
end
GameState.OnLoad(ifBypassStory(removeAllEntities))

GameState.OnLoad(ifBypassStory(StoryBypass.RemoveAutosave))
