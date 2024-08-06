-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                          Story? No!                                         --
--                                                                                             --
-------------------------------------------------------------------------------------------------

-- story bypass skips most/all dialogues, combat and interactions that aren't related to a scenario
local function ifBypassStory(func)
    return IfActive(function(...)
        if Config.BypassStory or (S ~= nil and S.OnMap) then
            func(...)
        end
    end)
end

function StoryBypass.CancelDialog(dialog, instanceID)
    for _, player in pairs(GU.DB.GetPlayers()) do
        Osi.DialogRemoveActorFromDialog(instanceID, player)
        Osi.DialogRequestStopForDialog(dialog, player)
    end
end

function StoryBypass.EndLongRest()
    Osi.PROC_Camp_LongRestFinishForAllPlayers()
    Osi.PROC_Camp_EveryoneWakeup()
    Osi.RemoveStatus(GetHostCharacter(), "LONG_REST", "00000000-0000-0000-0000-000000000000")
    -- Osi.RestoreParty(GetHostCharacter())
    Osi.PROC_Camp_SetModeToDay()
end

function StoryBypass.UnblockTravel(entity)
    Osi.RemoveStatus(entity.Uuid.EntityUuid, "TRAVELBLOCK_CANTMOVE")
    Osi.RemoveStatus(entity.Uuid.EntityUuid, "TRAVELBLOCK_BLOCKEDZONE")

    entity.ServerCharacter.PlayerData.IsInDangerZone = false
    entity.CanTravel.ErrorFlags = {}
    entity.CanTravel.field_2 = 0
    entity:Replicate("CanTravel")
end

function StoryBypass.RemoveAllEntities()
    local toRemove = UT.Filter(Ext.Entity.GetAllEntitiesWithUuid(), function(v)
        return v.IsCharacter
            and GC.IsNonPlayer(v.Uuid.EntityUuid)
            and not v.PartyMember
            and not U.UUID.Equals(C.NPCCharacters.Jergal, v.Uuid.EntityUuid) -- No
            and not U.UUID.Equals(C.NPCCharacters.Emperor, v.Uuid.EntityUuid) -- Gameover if dead
            and not v.ServerCharacter.Template.Name:match("Player")
    end)

    for i, e in ipairs(toRemove) do
        L.Debug("Removing", e.Uuid.EntityUuid, e.ServerCharacter.Template.Name)
        GU.Object.Remove(e.Uuid.EntityUuid)
    end
    L.Info("Clear All Entities", "Removed " .. tostring(#toRemove) .. " entities")

    return toRemove
end

function StoryBypass.ClearArea(character)
    if Ext.Entity.Get(character).CampPresence then
        L.Error("ClearArea", "Cannot clear area while in camp.")
        return
    end

    local nearby = GE.GetNearby(character, 100, true)

    local toRemove = UT.Filter(nearby, function(v)
        return v.Entity.IsCharacter and not v.Entity.PartyMember and not U.UUID.Equals(C.NPCCharacters.Jergal, v.Guid)
    end)

    for _, batch in pairs(UT.Batch(toRemove, math.ceil(#toRemove / 5))) do
        Schedule(function()
            for _, b in pairs(batch) do
                if GC.IsPlayable(b.Guid) then
                    Osi.TeleportTo(b.Guid, C.NPCCharacters.Jergal, "", 1, 1, 1)
                else
                    GU.Object.Remove(b.Guid)
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
                -- Osi.CreateSurface(b.Guid, "None", 10, -1)
                if b.Entity.ServerItem then
                    if b.Entity.ServerItem.IsLadder or b.Entity.ServerItem.IsDoor or b.Entity.GameplayLight then
                        b.Entity.ServerItem.CanBePickedUp = false
                        b.Entity.ServerItem.CanBeMoved = false
                        if b.Entity.ServerItem.IsDoor then
                            Osi.Unlock(b.Guid)
                            Osi.Open(b.Guid)
                        end
                        if b.Entity.Health then
                            b.Entity.Health.Hp = 666
                            b.Entity.Health.MaxHp = 666
                            b.Entity:Replicate("Health")
                            b.Entity.Resistances.Resistances = UT.Map(
                                { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 }, -- 14
                                function()
                                    return {
                                        "ImmuneToMagical",
                                        "ImmuneToNonMagical",
                                    }
                                end
                            )
                            b.Entity:Replicate("Resistances")
                        end
                    elseif b.Entity.Health or b.Entity.ServerItem.CanBePickedUp or b.Entity.ServerItem.CanUse then -- TODO remove more CanUse objects
                        GU.Object.Remove(b.Guid)
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

        if UT.Find(dialogActors, Enemy.IsValid) then
            return
        end

        for _, actor in ipairs(dialogActors) do
            local paidActor = US.Contains(actor, {
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

        local hasRemovable = UT.Filter(dialogActors, function(actor)
            return GC.IsNonPlayer(actor) and Osi.IsAlly(Player.Host(), actor) ~= 1
        end)

        local hasPlayable = UT.Filter(dialogActors, function(actor)
            return GC.IsPlayable(actor)
        end)

        if #hasPlayable == 0 then
            return
        end

        L.Dump("cancelDialog", dialog, instanceID, dialogActors, hasRemovable, hasPlayable)

        if #hasRemovable > 0 then
            StoryBypass.CancelDialog(dialog, instanceID)
        end

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

U.Osiris.On(
    "DialogActorJoined",
    4,
    "after",
    ifBypassStory(function(dialog, instanceID, actor, speakerIndex)
        if
            dialog:match("CAMP_")
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

U.Osiris.On(
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
U.Osiris.On(
    "EnteredCombat",
    2,
    "after",
    ifBypassStory(function(object, combatGuid)
        if not S and GC.IsNonPlayer(object) and GC.IsValid(object) then
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
    end)
)

U.Osiris.On(
    "Resurrected",
    1,
    "after",
    ifBypassStory(function(character)
        if not S and GC.IsNonPlayer(character) and GC.IsValid(character) then
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

local entityListener = nil
GameState.OnLoad(function()
    if not entityListener then
        entityListener = Ext.Entity.Subscribe(
            "CanTravel",
            ifBypassStory(function(e)
                if e.PartyMember then
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
        if not GC.IsPlayable(character) then
            return
        end

        Schedule(function()
            if not Ext.Entity.Get(C.NPCCharacters.Jergal).CampPresence then
                Osi.PROC_GLO_Jergal_MoveToCamp()
            end
        end)

        -- workaround for blocked travel
        -- TODO fix this
        -- Defer(1000, function()
        --     if S and not S.OnMap then
        --         L.Error("Teleport workaround", character)
        --         -- Scenario.Teleport(character)
        --     end
        -- end)

        if not Ext.Entity.Get(character).CampPresence or not S then
            L.Debug("ReturnToCamp", character)
            -- need ~2 ticks for changing CampPresence
            Schedule().After(Schedule).After(function()
                Player.ReturnToCamp()
            end)
        end
    end)
)

U.Osiris.On(
    "LongRestStarted",
    0,
    "after",
    ifBypassStory(function()
        StoryBypass.EndLongRest()
    end)
)

Event.On(
    "ScenarioCombatStarted",
    ifBypassStory(function()
        StoryBypass.ClearArea(Player.Host())
        for _, player in pairs(GU.DB.GetPlayers()) do
            Osi.RemoveStatus(player, "SURPRISED", C.NullGuid)
        end
    end)
)

Event.On(
    "ScenarioMapEntered",
    ifBypassStory(function()
        StoryBypass.ClearArea(Player.Host())
    end)
)

GameState.OnLoad(ifBypassStory(function()
    Defer(1000, function()
        if S or not Config.ClearAllEntities then
            return
        end
        if UT.Contains(PersistentVars.RegionsCleared, Player.Region()) then
            return
        end

        Schedule(function()
            StoryBypass.RemoveAllEntities()
            table.insert(PersistentVars.RegionsCleared, Player.Region())
        end)
    end)
end))
