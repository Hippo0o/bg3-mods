function Player.FixTadpole()
    for _, p in pairs(GU.DB.GetPlayers()) do
        if Osi.GetTadpolePowersCount(p) > 0 then
            Osi.SetTadpoleTreeState(p, 2)
        end
    end
end

function Player.SetTags()
    for _, p in pairs(GU.Entity.GetParty()) do
        -- Osi.SetTag(p.Uuid.EntityUuid, "64bc9da1-9262-475a-a397-157600b7debd") -- AI_PREFERRED_TARGET
        Osi.SetTag(p.Uuid.EntityUuid, "6d60bed7-10cc-4b52-8fb7-baa75181cd49") -- IGNORE_COMBAT_LATE_JOIN_PENALTY
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
