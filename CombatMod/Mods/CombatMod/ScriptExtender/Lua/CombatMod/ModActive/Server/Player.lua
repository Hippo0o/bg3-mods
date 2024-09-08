function Player.FixTadpole()
    for _, p in pairs(GU.DB.GetPlayers()) do
        if Osi.GetTadpolePowersCount(p) > 0 then
            Osi.SetTadpoleTreeState(p, 2)
        end
    end
end

function Player.SetTags()
    for _, p in pairs(GU.DB.GetPlayers()) do
        Osi.SetTag(p, "64bc9da1-9262-475a-a397-157600b7debd") -- AI_PREFERRED_TARGET
        Osi.SetTag(p, "6d60bed7-10cc-4b52-8fb7-baa75181cd49") -- IGNORE_COMBAT_LATE_JOIN_PENALTY
    end
end

function Player.ResetApproval()
    for _, p in pairs(GU.Entity.GetParty()) do
        if p.ApprovalRatings then
            for k, v in pairs(p.ApprovalRatings.Ratings) do
                if v < 30 then
                    p.ApprovalRatings.Ratings[k] = 30
                    p:Replicate("ApprovalRatings")
                end
            end
        end
    end
end

local function runAll()
    xpcall(Player.FixTadpole, L.Error)
    xpcall(Player.SetTags, L.Error)
    xpcall(Player.ResetApproval, L.Error)
end

GameState.OnLoad(runAll)
Ext.Osiris.RegisterListener("CharacterJoinedParty", 1, "after", runAll)
Ext.Osiris.RegisterListener("CharacterLeftParty", 1, "after", runAll)
Ext.Osiris.RegisterListener("LongRestFinished", 0, "after", runAll)

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                       Party expansion                                       --
--                                                                                             --
-------------------------------------------------------------------------------------------------

function Player.RecruitOrigin(id)
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

function Player.OverridePartySize(size)
    Osi.SetMaxPartySizeOverride(size)
end
