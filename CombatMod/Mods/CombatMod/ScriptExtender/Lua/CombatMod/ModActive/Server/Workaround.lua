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


local function runAll()
    Workaround.Tadpole()
    Workaround.Tags()
end

GameState.OnLoad(runAll)
U.Osiris.On("CharacterJoinedParty", 1, "after", runAll)
U.Osiris.On("CharacterLeftParty", 1, "after", runAll)
U.Osiris.On("LongRestFinished", 0, "after", runAll)