function Workaround.Tadpole()
    for _, p in pairs(GU.DB.GetPlayers()) do
        if Osi.GetTadpolePowersCount(p) > 0 then
            Osi.SetTadpoleTreeState(p, 2)
        end
    end
end

function Workaround.Tags()
    for _, p in pairs(GU.Entity.GetParty()) do
        -- Osi.SetTag(p.Uuid.EntityUuid, "64bc9da1-9262-475a-a397-157600b7debd") -- AI_PREFERRED_TARGET
        Osi.SetTag(p.Uuid.EntityUuid, "6d60bed7-10cc-4b52-8fb7-baa75181cd49") -- IGNORE_COMBAT_LATE_JOIN_PENALTY
    end
end

function Workaround.ResetApproval()
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

local function party()
    xpcall(Workaround.Tadpole, L.Error)
    xpcall(Workaround.Tags, L.Error)
    xpcall(Workaround.ResetApproval, L.Error)
end

GameState.OnLoad(party)
Ext.Osiris.RegisterListener("CharacterJoinedParty", 1, "after", party)
Ext.Osiris.RegisterListener("CharacterLeftParty", 1, "after", party)
Ext.Osiris.RegisterListener("LongRestFinished", 0, "after", party)

function Workaround.UndeadImmunity(guid)
    if Osi.IsTagged(guid, "33c625aa-6982-4c27-904f-e47029a9b140") == 1 then -- UNDEAD
        Osi.SetTag(guid, C.ShadowCurseTag) -- ACT2_SHADOW_CURSE_IMMUNE
    end
end

Ext.Osiris.RegisterListener("EnteredCombat", 2, "after", Workaround.UndeadImmunity)
