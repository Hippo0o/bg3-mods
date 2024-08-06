-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                          Story? No!                                         --
--                                                                                             --
-------------------------------------------------------------------------------------------------

function GameMode.AskTutSkip()
    Player.AskConfirmation("Skip to Camp?", function(confirmed)
        if not confirmed then
            return
        end

        Osi.PROC_DEBUG_TeleportToAct("Act1")
        GameState.RegisterLoadingAction(function()
            Osi.PROC_GLO_Jergal_MoveToCamp()
            Defer(1000, function()
                Osi.TeleportToPosition(Player.Host(), -649.25, -0.0244140625, -184.75, "", 1, 1, 1)
            end)
        end, true)
    end)
end

function GameMode.AskUnlockAll()
    Player.AskConfirmation("Unlock all?", function(confirmed)
        if not confirmed then
            return
        end

        L.Debug(Osi.PROC_DEBUG_TeleportToAct("Act3"))
        GameState.RegisterLoadingAction(function()
            local f = Osi.GetFaction(Player.Host())
            for _, o in pairs(C.OriginCharacters) do
                Osi.PROC_ORI_SetupCamp(o, 1) -- TODO fix halsin and mithara
                Osi.SetFaction(o, f)
                Osi.SetTadpoleTreeState(o, 2)
                Osi.ChangeApprovalRating(o, Player.Host(), 0, 50)
            end

            Osi.TemplateAddTo("4a82e6f2-839f-434e-addf-b07dd1578194", Player.Host(), 1, 1) -- Astral Tadpole

            for _, p in pairs(UE.GetPlayers()) do
                Osi.SetTadpoleTreeState(p, 2) -- TODO fix astral tad
                Osi.AddTadpole(p, 1)
            end
        end, true)
    end)
end

local function ifBypassStory(func)
    return function(...)
        if Config.BypassStory and (Config.BypassStoryAlways or S ~= nil) then
            func(...)
        end
    end
end

-- story bypass skips most/all dialogues, combat and interactions that aren't related to a scenario

local actors = {}
local cancelDialog = Async.Debounce(1000, function(dialog, instanceID)
    Schedule(function()
        actors[instanceID] = nil
    end)
    local dialogActors = actors[instanceID]

    if UT.Find(dialogActors, Enemy.IsValid) then
        return
    end

    for _, actor in ipairs(dialogActors) do
        local paidActor = US.Contains(actor, { "_Daisy_", "Jergal", "Orpheus", "Emperor" })
        if paidActor then
            return
        end
    end

    local hasRemovable = UT.Filter(dialogActors, function(actor)
        return UE.IsNonPlayer(actor) and Osi.IsAlly(Player.Host(), actor) == 0
    end)

    local hasPlayable = UT.Filter(dialogActors, function(actor)
        return UE.IsPlayable(actor)
    end)

    L.Dump("cancelDialog", dialog, instanceID, dialogActors, hasRemovable, hasPlayable)

    for _, actor in ipairs(hasRemovable) do
        L.Debug("Removing", actor)
        UE.Remove(actor)
        Osi.DialogRemoveActorFromDialog(instanceID, actor)

        Player.Notify(
            "Skipped interaction with "
                .. Osi.ResolveTranslatedString(Ext.Entity.Get(actor).DisplayName.NameKey.Handle.Handle),
            true
        )
    end

    if #hasRemovable > 0 then
        Osi.DialogRequestStopForDialog(dialog, dialogActors[1])
        for _, player in pairs(UE.GetPlayers()) do
            Osi.DialogRemoveActorFromDialog(instanceID, player)
        end
    end

    if #hasPlayable == #UE.GetPlayers() then
        L.Info("To disable story bypass, use !JC DisableStoryBypass")
        Osi.DialogRequestStopForDialog(dialog, dialogActors[1])
    end
end)
Ext.Osiris.RegisterListener(
    "DialogActorJoined",
    4,
    "after",
    ifBypassStory(function(dialog, instanceID, actor, speakerIndex)
        if
            dialog == "TUT_Start_PAD_Start_3ef36a5f-64b2-ce27-0696-f93b1cbd846f"
            and U.UUID.Equals(actor, Player.Host())
        then
            askTutSkip()
        end

        L.Debug("DialogActorJoined", dialog, actor, instanceID, speakerIndex)

        if dialog:match("^CHA_Crypt_SkeletonRisingCinematic") or actor:match("^CHA_Crypt_SkeletonRisingCinematic") then
            Osi.PROC_GLO_Jergal_MoveToCamp()
        end

        if dialog:match("CAMP_") then
            return
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
        if UE.IsNonPlayer(character, true) then
            return
        end
        if Osi.IsLocked(item) == 1 then
            L.Debug("Auto unlocking", item)
            L.Info("To disable story bypass, use !JC DisableStoryBypass")
            Player.Notify("Auto unlocking", true)
            Osi.Unlock(item, character)
        end
        if Osi.IsTrapArmed(item) == 1 then
            L.Debug("Auto disarming", item)
            L.Info("To disable story bypass, use !JC DisableStoryBypass")
            Player.Notify("Auto disarming", true)
            Osi.SetTrapArmed(item, 0)
        end
    end)
)
Ext.Osiris.RegisterListener(
    "EnteredCombat",
    2,
    "after",
    ifBypassStory(function(object, combatGuid)
        Schedule(function()
            if not Enemy.IsValid(object) and UE.IsNonPlayer(object) then
                L.Debug("Removing", object)
                Osi.LeaveCombat(object)
                UE.Remove(object)
                Player.Notify(
                    "Skipped combat with "
                        .. Osi.ResolveTranslatedString(Ext.Entity.Get(object).DisplayName.NameKey.Handle.Handle),
                    true
                )
            end
        end)
    end)
)
