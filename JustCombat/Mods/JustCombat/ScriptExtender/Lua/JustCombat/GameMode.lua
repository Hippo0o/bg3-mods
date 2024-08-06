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

        WaitFor(function()
            return Player.TeleportToAct("Act1")
        end, function()
            Osi.PROC_GLO_Jergal_MoveToCamp()
            Defer(1000, function()
                Osi.TeleportToPosition(Player.Host(), -649.25, -0.0244140625, -184.75, "", 1, 1, 1)
            end)
        end)
    end)
end

function GameMode.AskUnlockAll()
    Player.AskConfirmation("Unlock all?", function(confirmed)
        if not confirmed then
            return
        end

        WaitFor(function()
            return Player.TeleportToAct("Act1")
        end, function()
            Defer(1000, function()
                local function unlockTadpole(object)
                    Osi.SetTag(object, "089d4ca5-2cf0-4f54-84d9-1fdea055c93f")
                    Osi.SetTag(object, "efedb058-d4f5-4ab8-8add-bd5e32cdd9cd")
                    Osi.SetTag(object, "c15c2234-9b19-453e-99cc-00b7358b9fce")
                    Osi.SetTadpoleTreeState(object, 2)
                    Osi.AddTadpole(object, 1)
                    Osi.AddTadpolePower(object, "TAD_IllithidPersuasion", 1)
                    Osi.SetFlag("GLO_Daisy_State_AstralIndividualAccepted_9c5367df-18c8-4450-9156-b818b9b94975", object)
                end

                Osi.TemplateAddTo("4a82e6f2-839f-434e-addf-b07dd1578194", Player.Host(), 1, 1) -- Astral Tadpole

                for _, p in pairs(UE.GetPlayers()) do
                    unlockTadpole(p)
                end

                -- local function fixMinthara()
                --     Osi.PROC_RemoveAllDialogEntriesForSpeaker(
                --         "S_GOB_DrowCommander_25721313-0c15-4935-8176-9f134385451b"
                --     )
                --     Osi.DB_Dialogs(
                --         "S_GOB_DrowCommander_25721313-0c15-4935-8176-9f134385451b",
                --         "Minthara_InParty_13d72d55-0d47-c280-9e9c-da076d8876d8"
                --     )
                -- end
                --
                -- local function fixHalsin()
                --     Osi.PROC_RemoveAllPolymorphs("S_GLO_Halsin_7628bc0e-52b8-42a7-856a-13a6fd413323")
                --     Osi.PROC_RemoveAllDialogEntriesForSpeaker("S_GLO_Halsin_7628bc0e-52b8-42a7-856a-13a6fd413323")
                --     Osi.DB_Dialogs(
                --         "S_GLO_Halsin_7628bc0e-52b8-42a7-856a-13a6fd413323",
                --         "Halsin_InParty_890c2586-6b71-ca01-5bd6-19d533181c71"
                --     )
                -- end
                --
                -- local f = Osi.GetFaction(Player.Host())
                -- for _, o in pairs(C.OriginCharacters) do
                --     Osi.PROC_ORI_SetupCamp(o, 1) -- TODO fix halsin and mithara
                --     Osi.SetFaction(o, f)
                --     Osi.RegisterAsCompanion(o, Player.Host())
                --     Osi.ChangeApprovalRating(o, Player.Host(), 0, 50)
                --
                --     unlockTadpole(o)
                -- end
                -- fixHalsin()
                -- fixMinthara()

            end)
        end)
    end)
end

function GameMode.AskBeginCombat()
    Player.AskConfirmation("Begin combat?", function(confirmed)
        if not confirmed then
            return
        end
    end)
end

-- story bypass skips most/all dialogues, combat and interactions that aren't related to a scenario
local function ifBypassStory(func)
    return function(...)
        if Config.BypassStory and (Config.BypassStoryAlways or S ~= nil) then
            func(...)
        end
    end
end

U.Events.RegisterListener(
    "AutomatedDialogStarted",
    2,
    "after",
    ifBypassStory(function(dialog, instanceID)
        if dialog == "GLO_Jergal_AD_AttackFromDialog_851c058a-3223-3930-05aa-8558a0e36b04" then
            GameMode.AskBeginCombat()
        end
    end)
)

local actors = {}
local handlers = {}
local function cancelDialog(dialog, instanceID)
    if handlers[instanceID] then
        handlers[instanceID](dialog, instanceID)
        return
    end

    handlers[instanceID] = Async.Debounce(100, function(dialog, instanceID)
        Schedule(function()
            actors[instanceID] = nil
            handlers[instanceID] = nil
        end)
        local dialogActors = actors[instanceID]

        if UT.Find(dialogActors, Enemy.IsValid) then
            return
        end

        for _, actor in ipairs(dialogActors) do
            local paidActor = US.Contains(actor, { "_Daisy_", "Jergal", "Orpheus", "Volo" })
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

        if #hasRemovable > 0 then
            for _, player in pairs(UE.GetPlayers()) do
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
                "Skipped interaction with "
                    .. Osi.ResolveTranslatedString(Ext.Entity.Get(actor).DisplayName.NameKey.Handle.Handle),
                true
            )
        end

        if #hasPlayable == #dialogActors then
            L.Info("To disable story bypass, use !JC DisableStoryBypass")
            Osi.DialogRequestStopForDialog(dialog, dialogActors[1])
        end
    end)

    handlers[instanceID](dialog, instanceID)
end

U.Events.RegisterListener(
    "DialogActorJoined",
    4,
    "after",
    ifBypassStory(function(dialog, instanceID, actor, speakerIndex)
        if
            dialog == "TUT_Start_PAD_Start_3ef36a5f-64b2-ce27-0696-f93b1cbd846f"
            and U.UUID.Equals(actor, Player.Host())
        then
            GameMode.AskTutSkip()
        end

        if dialog:match("^CHA_Crypt_SkeletonRisingCinematic") or actor:match("^CHA_Crypt_SkeletonRisingCinematic") then
            Osi.PROC_GLO_Jergal_MoveToCamp()
        end

        if dialog:match("CAMP_") or dialog:match("Tadpole") or dialog:match("InParty_") then
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
U.Events.RegisterListener(
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
U.Events.RegisterListener(
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
