-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                    Player introduction                                      --
--                                                                                             --
-------------------------------------------------------------------------------------------------

function Intro.AskTutSkip()
    return Player.AskConfirmation("Skip to Camp?")
        :After(function(confirmed)
            if not confirmed then
                return
            end

            Schedule(function()
                for _, entity in pairs(GE.GetParty()) do
                    for _, item in pairs(entity.InventoryOwner.Inventories[1].InventoryContainer.Items) do
                        xpcall(function()
                            local isFromMod = Ext.Mod.GetMod(Ext.Stats.Get(item.Item.Data.StatsId).ModId).Info.Author
                                ~= ""
                            if not isFromMod then
                                GU.Object.Remove(item.Item.Uuid.EntityUuid)
                            end
                        end, L.Error)
                    end
                end
            end)

            Osi.Use(Player.Host(), "S_TUT_Helm_ControlPanel_bcbba417-6403-40a6-aef6-6785d585df2a", "")
            return Defer(1000)
        end)
        :After(function()
            local done = false
            GameState.OnLoad(function()
                Defer(3000, function()
                    Osi.PROC_GLO_Jergal_MoveToCamp()

                    -- go underdark to trigger tremor
                    Osi.TeleportToPosition(Player.Host(), 149.56359863281, 59.6376953125, -139.54454040527, "", 1, 1, 1)

                    return Defer(1000)
                end):After(function()
                    -- go to first camp
                    Osi.TeleportToPosition(Player.Host(), -649.25, -0.0244140625, -184.75, "", 1, 1, 1)
                    -- Osi.TeleportTo(Player.Host(), C.NPCCharacters.Jergal, "", 1, 1, 1)
                    Osi.PROC_Camp_ForcePlayersToCamp()

                    -- add starting items
                    Osi.AddGold(Player.Host(), 500)
                    Osi.TemplateAddTo("efcb70b7-868b-4214-968a-e23f6ad586bc", Player.Host(), 1, 0) -- camp supply backpack
                    Osi.TemplateAddTo("b7543ff4-5010-4c01-9bcd-4da1047aebfc", Player.Host(), 1, 0) -- alchemy pouch
                    Osi.TemplateAddTo("c1c3e4fb-d68c-4e10-afdc-d4550238d50e", Player.Host(), 4, 1) -- revify scrolls
                    Osi.TemplateAddTo("d47006e9-8a51-453d-b200-9e0d42e9bbab", Player.Host(), 10, 1) -- health potions
                    Osi.PROC_CAMP_GiveFreeSupplies()
                    Osi.PROC_CAMP_GiveFreeSupplies()
                    Osi.PROC_CAMP_GiveFreeSupplies()

                    -- recruitable hirelings at lvl 1
                    Osi.SetFlag("Hirelings_State_FeatureAvailable_66a34105-f02f-4c74-a3c8-085f1de12db8")
                    Osi.SetFlag("Hirelings_State_ShowIntro_b3983f00-096e-4e8b-82d5-8ae92a806dfc")
                    Osi.SetFlag(
                        "FCRD_Jergal_HirelingsIntro_02e588d1-0c38-4743-afba-481d1b842975",
                        C.NPCCharacters.Jergal
                    )

                    for _, p in pairs(GU.DB.GetPlayers()) do
                        Osi.RemoveStatus(p, "TUT_SUMMON_BLOCK")
                    end

                    -- maybe fix random cutscene at goblin camp related to Shadowheart
                    Osi.PROC_GLO_InfernalBox_SetNewOwner(Player.Host())
                    Osi.PROC_GLO_InfernalBox_AddToOwner()

                    Player.Notify(__("Starting items added. Hirelings unlocked."))
                    done = true

                    Osi.AutoSave()
                end)
            end, true)

            return WaitUntil(function()
                return done
            end)
        end)
end

function Intro.AskOnboarding()
    PersistentVars.Active = false
    PersistentVars.Asked = true

    return Player.AskConfirmation("Welcome to %s! Start playing?", Mod.Prefix)
        :After(function(confirmed)
            if not confirmed then
                return
            end

            Event.Trigger("ModActive")

            if Player.Region() == C.Regions.Act0 then
                return Intro.AskTutSkip()
            end
            return true
        end)
        :After(function()
            Intro.AskEnableRogueMode()
        end)
end

function Intro.AskEnableRogueMode()
    return Player.AskConfirmation([[
Play Roguelike mode?
Continuously create new battles.
You will gain a higher score with every completed fight.
Difficulty increases with the score.]]):After(function(confirmed)
        L.Debug("RogueMode", confirmed)

        PersistentVars.RogueModeActive = confirmed

        if PersistentVars.RogueScore == 0 then
            PersistentVars.RogueScore = math.min(100, (Player.Level() - 1) * 10) -- +10 per level, max 100
        end

        Event.Trigger("RogueModeChanged", PersistentVars.RogueModeActive)

        return confirmed
    end)
end

Ext.Osiris.RegisterListener("AutomatedDialogStarted", 2, "after", function(dialog, instanceID)
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
        Intro.AskOnboarding()
    end
end)

Ext.Osiris.RegisterListener("DialogActorJoined", 4, "after", function(dialog, instanceID, actor, speakerIndex)
    if
        US.Contains(dialog, {
            "TUT_Start_PAD_Start_",
            "TUT_Misc_PAD_OriginPod_PlayerEmpty_",
        }) and U.UUID.Equals(actor, Player.Host())
    then
        Intro.AskOnboarding()
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
