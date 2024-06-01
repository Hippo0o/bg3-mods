-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                          Story? No!                                         --
--                                                                                             --
-------------------------------------------------------------------------------------------------

-- story bypass skips most/all dialogues, combat and interactions that aren't related to a scenario
local function ifBypassStory(func)
    return IfActive(function(...)
        if Config.BypassStory and (Config.BypassStoryAlways or S ~= nil) then
            func(...)
        end
    end)
end

local actors = {}
local handlers = {}
local function cancelDialog(dialog, instanceID)
    if handlers[instanceID] then
        handlers[instanceID](dialog, instanceID)
        return
    end

    handlers[instanceID] = Async.Debounce(10, function(dialog, instanceID)
        Schedule(function()
            actors[instanceID] = nil
            handlers[instanceID] = nil
        end)
        local dialogActors = actors[instanceID]

        if UT.Find(dialogActors, Enemy.IsValid) then
            return
        end

        for _, actor in ipairs(dialogActors) do
            local paidActor = US.Contains(actor, {
                "_Daisy_",
                "Jergal",
                -- "Orpheus",
                -- "Volo"
            })
            if paidActor then
                return
            end
        end

        local hasRemovable = UT.Filter(dialogActors, function(actor)
            return UE.IsNonPlayer(actor) and Osi.IsAlly(Player.Host(), actor) ~= 1
        end)

        local hasPlayable = UT.Filter(dialogActors, function(actor)
            return UE.IsPlayable(actor)
        end)

        if #hasPlayable == 0 then
            return
        end

        L.Dump("cancelDialog", dialog, instanceID, dialogActors, hasRemovable, hasPlayable)

        if #hasRemovable > 0 then
            for _, player in pairs(U.DB.GetPlayers()) do
                Osi.DialogRemoveActorFromDialog(instanceID, player)
                Osi.DialogRequestStopForDialog(dialog, player)
            end
        end

        for _, actor in ipairs(hasRemovable) do
            L.Debug("Removing", actor)
            -- UE.Remove(actor)
            Osi.DialogRemoveActorFromDialog(instanceID, actor)
            Osi.DialogRequestStopForDialog(dialog, actor)

            Player.Notify(
                __(
                    "Skipped interaction with %s",
                    Osi.ResolveTranslatedString(Ext.Entity.Get(actor).DisplayName.NameKey.Handle.Handle)
                ),
                true
            )
        end

        if #hasPlayable == #dialogActors then
            Osi.DialogRequestStopForDialog(dialog, dialogActors[1])
        end
    end)

    handlers[instanceID](dialog, instanceID)
end

U.Osiris.On(
    "DialogActorJoined",
    4,
    "after",
    ifBypassStory(function(dialog, instanceID, actor, speakerIndex)
        if dialog:match("^CHA_Crypt_SkeletonRisingCinematic") or actor:match("^CHA_Crypt_SkeletonRisingCinematic") then
            Osi.PROC_GLO_Jergal_MoveToCamp()
        end

        if
            dialog:match("CAMP_")
            or dialog:match("Tadpole")
            or dialog:match("Recruitment")
            or dialog:match("InParty")
            or dialog:match("^BHVR_WRLD")
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

U.Osiris.On(
    "UseFinished",
    3,
    "before",
    ifBypassStory(function(character, item, sucess)
        if UE.IsNonPlayer(character, true) then
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
U.Osiris.On(
    "EnteredCombat",
    2,
    "after",
    ifBypassStory(function(object, combatGuid)
        if not Enemy.IsValid(object) and UE.IsNonPlayer(object) and Osi.IsCharacter(object) == 1 then
            L.Debug("Removing", object)
            Osi.LeaveCombat(object)
            UE.Remove(object)
            Player.Notify(
                __(
                    "Skipped combat with %s",
                    Osi.ResolveTranslatedString(Ext.Entity.Get(object).DisplayName.NameKey.Handle.Handle)
                ),
                true
            )
        end
    end)
)

U.Osiris.On(
    "Resurrected",
    1,
    "after",
    ifBypassStory(function(character)
        if not S and UE.IsNonPlayer(character) and Osi.IsCharacter(character) == 1 then
            UE.Remove(character)
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

local entityListener = nil
GameState.OnLoad(function()
    if not entityListener then
        entityListener = Ext.Entity.Subscribe(
            "CanTravel",
            ifBypassStory(function(e)
                if e.PartyMember then
                    L.Debug("UnblockTravel", e.Uuid.EntityUuid)
                    StoryBypass.UnblockTravel(e)
                end
            end)
        )
    end
end)
GameState.OnUnload(function()
    if entityListener then
        Ext.Entity.Unsubscribe(entityListener)
        entityListener = nil
    end
end)

U.Osiris.On(
    "TeleportToFromCamp",
    1,
    "after",
    ifBypassStory(function(character)
        if not UE.IsPlayable(character) then
            return
        end

        -- workaround for blocked travel
        -- TODO fix this
        Defer(1000, function()
            if S and not S.OnMap then
                L.Error("Teleport workaround", character)
                -- Scenario.Teleport(character)
            end
        end)

        if U.UUID.Equals(Player.Host(), character) then
            if not Ext.Entity.Get(character).CampPresence or not S then
                L.Debug("ReturnToCamp", character)
                Player.ReturnToCamp()
            end
        end
    end)
)

U.Osiris.On(
    "LongRestStarted",
    0,
    "after",
    ifBypassStory(function()
        Osi.PROC_Camp_LongRestFinishForAllPlayers()
        Osi.PROC_Camp_EveryoneWakeup()
        Osi.RemoveStatus(GetHostCharacter(), "LONG_REST", "00000000-0000-0000-0000-000000000000")
        -- Osi.RestoreParty(GetHostCharacter())
        Osi.PROC_Camp_SetModeToDay()
    end)
)

function StoryBypass.UnblockTravel(entity)
    Osi.RemoveStatus(entity.Uuid.EntityUuid, "TRAVELBLOCK_CANTMOVE")
    Osi.RemoveStatus(entity.Uuid.EntityUuid, "TRAVELBLOCK_BLOCKEDZONE")

    entity.ServerCharacter.PlayerData.IsInDangerZone = false
    entity.CanTravel.ErrorFlags = {}
    entity.CanTravel.field_2 = 0
    entity:Replicate("CanTravel")
end

function StoryBypass.ClearArea(character)
    local nearby = UE.GetNearby(character, 100, true)

    local toRemove = UT.Filter(nearby, function(v)
        return v.Entity.IsCharacter and UE.IsNonPlayer(v.Guid)
    end)

    for _, batch in pairs(UT.Batch(toRemove, math.ceil(#toRemove / 5))) do
        Schedule(function()
            for _, b in pairs(batch) do
                if UE.IsImportant(b.Guid) and not b.Entity.PartyMember then
                    Osi.TeleportTo(b.Guid, C.NPCCharacters.Jergal, "", 1, 1, 1, 1, 0)
                else
                    UE.Remove(b.Guid)
                end
            end
        end)
    end

    local objects = UT.Filter(nearby, function(v)
        return v.Entity.ServerItem and not Item.IsOwned(v.Guid)
    end)
    for _, batch in pairs(UT.Batch(objects, math.ceil(#objects / 5))) do
        Schedule(function()
            for _, b in pairs(batch) do
                if b.Entity.ServerItem then
                    if b.Entity.ServerItem.IsLadder or b.Entity.ServerItem.IsDoor or b.Entity.GameplayLight then
                        b.Entity.ServerItem.CanBePickedUp = false
                        b.Entity.ServerItem.CanBeMoved = false
                        if b.Entity.ServerItem.IsDoor then
                            Osi.Unlock(b.Guid)
                        end
                        if b.Entity.Health then
                            b.Entity.Health.Hp = 999
                            b.Entity.Health.MaxHp = 999
                            b.Entity:Replicate("Health")
                        end
                    elseif b.Entity.Health or b.Entity.ServerItem.CanBePickedUp or b.Entity.ServerItem.CanUse then -- TODO remove more CanUse objects
                        UE.Remove(b.Guid)
                    end
                end
            end
        end)
    end

    -- Osi.ClearTag(v.Guid, "867f3a1e-1e4b-48c2-869e-343415231727")
    -- Osi.ClearTag(v.Guid, "f0020818-86f1-4ee9-a5a9-9ace9ecc9010")
    -- Osi.Resurrect(v.Guid)
    -- Osi.SetHitpointsPercentage(v.Guid, 100)
    -- L.Dump(Osi.IsDestroyed(v.Guid))
end
