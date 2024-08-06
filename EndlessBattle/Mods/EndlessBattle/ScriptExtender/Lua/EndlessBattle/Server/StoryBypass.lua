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
                "Orpheus",
                --"Volo"
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
            L.Info(__("To disable story bypass, use !EB DisableStoryBypass"))
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
U.Osiris.On("EnteredForceTurnBased", 1, "before", function(object)
    if Osi.IsCharacter(object) ~= 1 then
        return
    end

    if not UE.IsNonPlayer(object) then
        Osi.ForceTurnBasedMode(object, 0)
        return
    end

    UE.Remove(object)
    Player.Notify(
        __(
            "Skipped event with %s",
            Osi.ResolveTranslatedString(Ext.Entity.Get(object).DisplayName.NameKey.Handle.Handle)
        ),
        true
    )
end)

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
            L.Info(__("To disable story bypass, use !EB DisableStoryBypass"))
            Player.Notify(__("Auto unlocking"), true)
            Osi.Unlock(item, character)
        end
        if Osi.IsTrapArmed(item) == 1 then
            L.Debug("Auto disarming", item)
            L.Info(__("To disable story bypass, use !EB DisableStoryBypass"))
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
        Schedule(function()
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
    end)
)

function StoryBypass.ClearArea(character)
    local toRemove = UT.Filter(UE.GetNearby(character, 50, true), function(v)
        return v.Entity.IsCharacter and UE.IsNonPlayer(v.Guid)
            or (
                v.Entity.ServerItem
                and not Item.IsOwned(v.Guid)
                and (v.Entity.ServerItem.CanUse or v.Entity.ServerItem.CanBePickedUp)
            )
    end)

    for _, batch in pairs(UT.Batch(toRemove, 20)) do
        Schedule(function()
            for _, b in pairs(batch) do
                L.Debug("Removing entity.", b.Guid)
                UE.Remove(b.Guid)
                -- Osi.SetOnStage(v.Guid, 0)
                -- Osi.DisappearOutOfSightTo(v.Guid, Player.Host(), "Run", 1, "")
            end
        end)
    end
end
