-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                          Story? No!                                         --
--                                                                                             --
-------------------------------------------------------------------------------------------------

-- story bypass skips most/all dialogues, combat and interactions that aren't related to a scenario
local function ifBypassStory(func)
    return function(...)
        if Config.BypassStory then
            func(...)
        end
    end
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

    if entity.ServerCharacter then
        entity.ServerCharacter.PlayerData.IsInDangerZone = false
    end
    entity.CanTravel.ErrorFlags = {}
    entity.CanTravel.field_2 = 0
    entity:Replicate("CanTravel")
end

function StoryBypass.AllowRemoval(entity)
    return entity.IsCharacter
        and GC.IsNonPlayer(entity.Uuid.EntityUuid)
        and not GU.Object.IsOwned(entity.Uuid.EntityUuid)
        and not entity.PartyMember
        and not U.UUID.Equals(C.NPCCharacters.Jergal, entity.Uuid.EntityUuid) -- No
        and not U.UUID.Equals(C.NPCCharacters.Emperor, entity.Uuid.EntityUuid) -- Gameover if dead
        and not U.UUID.Equals("4f6e63a1-b143-46b1-ac0e-834494dfdc6a", entity.Uuid.EntityUuid) -- Oliver quest endless loop
        and not (entity.ServerCharacter and entity.ServerCharacter.Template.Name:match("Player"))
end

function StoryBypass.RemoveAutosave()
    L.Info("Removing autosave triggers")
    L.Dump(Osi.DB_AutosaveTrigger:Get(nil))
    L.Dump(Osi.DB_AutoSaveGroup:Get(nil, nil))

    Osi.DB_AutoSaveGroup:Delete(nil, nil)
    Osi.DB_AutosaveTrigger:Delete(nil)
end

function StoryBypass.RemoveAllEntities()
    StoryBypass.ExpLock.ResumeTemporary()

    local toRemove = UT.Filter(Ext.Entity.GetAllEntitiesWithUuid(), StoryBypass.AllowRemoval)

    for i, e in ipairs(toRemove) do
        L.Debug("Removing", e.Uuid.EntityUuid, e.ServerCharacter.Template.Name)
        GU.Object.Remove(e.Uuid.EntityUuid)
    end

    GU.Object.Remove("S_GLO_DriderMoonlantern_4591d212-8f1b-4b85-880c-dc94f76702f4") -- will endlessly loop dialog

    L.Info("Clear All Entities", "Removed " .. tostring(#toRemove) .. " entities")

    table.insert(PersistentVars.RegionsCleared, Player.Region())

    return toRemove
end

function StoryBypass.ClearArea(character)
    if Ext.Entity.Get(character).CampPresence then
        L.Error("ClearArea", "Cannot clear area while in camp.")
        return
    end

    local nearby = GE.GetNearby(character, 150, true)

    for _, v in pairs(nearby) do
        if v.Entity.IsCharacter and not v.Entity.PartyMember and GC.IsOrigin(v.Guid) then
            Osi.SetOnStage(v.Guid, 0)
        end
    end

    local toRemove = UT.Filter(nearby, function(v)
        return StoryBypass.AllowRemoval(v.Entity)
    end)

    for _, batch in pairs(UT.Batch(toRemove, math.ceil(#toRemove / 5))) do
        Schedule(function()
            for _, b in pairs(batch) do
                GU.Object.Remove(b.Guid)
            end
        end)
    end

    local objects = UT.Filter(nearby, function(v)
        return v.Entity.ServerItem and not GU.Object.IsOwned(v.Guid)
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
                    elseif
                        b.Entity.Health
                        or b.Entity.ServerItem.CanBePickedUp
                        or b.Entity.ServerItem.CanUse
                        or (
                            b.Entity.ServerItem.Template.Id == C.ScenarioHelper.TemplateId
                            and not Scenario.IsHelper(b.Guid)
                        )
                    then -- TODO remove more CanUse objects
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

function StoryBypass.ClearSurfaces(guid, strength)
    local x, y, z = Osi.GetPosition(guid)

    local function generateSpiral(x, y, numPoints, angleIncrement, radiusIncrement)
        local points = {}
        local angle = 0
        local radius = 0
        for i = 1, numPoints do
            local newX = x + radius * math.cos(angle)
            local newY = y + radius * math.sin(angle)
            table.insert(points, { newX, newY })
            angle = angle + angleIncrement
            radius = radius + radiusIncrement
        end
        return points
    end

    local centerX, centerY = x, z
    local numPoints = strength or 20
    local angleIncrement = math.pi / 4 -- Adjust as needed
    local radiusIncrement = 1 -- Adjust as needed
    local spiralPoints = generateSpiral(centerX, centerY, numPoints, angleIncrement, radiusIncrement)

    for i, point in ipairs(spiralPoints) do
        if i % 2 == 0 then
            WaitTicks(4 * i, function()
                local nx, ny, nz = Osi.FindValidPosition(point[1], y, point[2], 100, C.NPCCharacters.Volo, 1) -- avoiding dangerous surfaces
                -- Osi.CreateSurfaceAtPosition(nx, ny, nz, "None", 100, -1)
                -- Osi.RemoveSurfaceLayerAtPosition(nx, ny, nz, "Ground", 100)
                Osi.TeleportToPosition(guid, nx, y, nz)
                Osi.UseSpell(guid, "TOT_Zone_Clear", guid)
                -- Osi.RequestPing(nx, ny, nz, "", character)
            end):Catch(function() end)
        end
    end

    return WaitTicks(5 * #spiralPoints, function()
        Osi.TeleportToPosition(guid, x, y, z)
        return true
    end)
end

do -- EXP Lock
    StoryBypass.ExpLock = {}

    local entityData = {}
    local function snapEntity(entity)
        if entity.Experience == nil then
            return
        end

        entityData[entity.Uuid.EntityUuid] = {
            exp = UT.Clean(entity.Experience),
            level = entity.EocLevel.Level,
            avail = entity.AvailableLevel.Level,
        }
    end

    function StoryBypass.ExpLock.SnapshotEntitiesExp()
        entityData = {}
        for i, e in pairs(GE.GetParty()) do
            snapEntity(e)
        end
    end

    local paused = false
    function StoryBypass.ExpLock.IsPaused()
        return paused
    end

    function StoryBypass.ExpLock.Pause()
        paused = true
        L.Debug("ExpLock Paused")
    end
    local debouncedSnap = Debounce(1000, StoryBypass.ExpLock.SnapshotEntitiesExp)

    function StoryBypass.ExpLock.Resume()
        paused = false
        StoryBypass.ExpLock.SnapshotEntitiesExp()
        L.Debug("ExpLock Resumed")
    end

    function StoryBypass.ExpLock.ResumeTemporary()
        if paused then
            StoryBypass.ExpLock.DebouncedPause()
        end

        StoryBypass.ExpLock.Resume()
    end

    function StoryBypass.ExpLock.PauseTemporary()
        if not paused then
            StoryBypass.ExpLock.DebouncedResume()
        end

        StoryBypass.ExpLock.Pause()
    end

    StoryBypass.ExpLock.DebouncedResume = Async.Debounce(1000, StoryBypass.ExpLock.Resume)
    StoryBypass.ExpLock.DebouncedPause = Async.Debounce(1000, StoryBypass.ExpLock.Pause)

    local entityListener = nil

    local function unsubscribeEntitiesExp()
        if entityListener then
            Ext.Entity.Unsubscribe(entityListener)
            entityListener = nil
        end
    end

    local function subscribeEntitiesExp()
        if not entityListener then
            StoryBypass.ExpLock.SnapshotEntitiesExp()
            entityListener = Ext.Entity.Subscribe(
                "Experience",
                ifBypassStory(function(e)
                    if paused or not e.Experience then
                        return
                    end

                    local data = entityData[e.Uuid.EntityUuid]

                    if data then
                        local exp = data.exp
                        local level = data.level
                        local avail = data.avail
                        if e.Experience.CurrentLevelExperience == exp.CurrentLevelExperience then
                            L.Debug("Experience unchanged", e.Uuid.EntityUuid)
                            return
                        end

                        e.EocLevel.Level = level
                        e.AvailableLevel.Level = avail

                        e.Experience.CurrentLevelExperience = exp.CurrentLevelExperience
                        e.Experience.TotalExperience = exp.TotalExperience
                        e.Experience.NextLevelExperience = exp.NextLevelExperience
                        -- e.Experience.field_28 = exp.field_28 -- dunno

                        e:Replicate("EocLevel")
                        e:Replicate("AvailableLevel")
                        e:Replicate("Experience")
                        L.Debug("Experience restored", e.Uuid.EntityUuid)
                    end

                    debouncedSnap()
                end)
            )
        end
    end

    subscribeEntitiesExp()

    Event.On("ScenarioRoundStarted", StoryBypass.ExpLock.Pause)
    Event.On("ScenarioRestored", function(scenario)
        if scenario:HasStarted() then
            StoryBypass.ExpLock.Pause()
        end
    end)

    local toggleCamp = Async.Throttle(100, function()
        if Scenario.HasStarted() then
            StoryBypass.ExpLock.Pause()
            return
        end

        if Player.InCamp() then
            StoryBypass.ExpLock.Pause()
        else
            StoryBypass.ExpLock.Resume()
        end
        WaitTicks(12, function()
            if Player.InCamp() then
                StoryBypass.ExpLock.Pause()
            else
                StoryBypass.ExpLock.Resume()
            end
        end)
    end)

    U.Osiris.On("TeleportedFromCamp", 1, "before", toggleCamp)
    U.Osiris.On("TeleportedToCamp", 1, "before", toggleCamp)
    GameState.OnLoad(toggleCamp)
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
        L.Debug("DialogActorJoined", dialog, actor)

        if
            dialog:match("CAMP_")
            or dialog:match("^Hireling_")
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
        if not Scenario.Current() and GC.IsNonPlayer(object) and GC.IsValid(object) then
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
        if not Scenario.Current() and GC.IsNonPlayer(character) and GC.IsValid(character) then
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

Ext.Entity.Subscribe(
    "CanTravel",
    ifBypassStory(function(e)
        if e.PartyMember then
            StoryBypass.UnblockTravel(e)
        end
    end)
)

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
        --     if Scenario.Current() and not S.OnMap then
        --         L.Error("Teleport workaround", character)
        --         -- Scenario.Teleport(character)
        --     end
        -- end)

        if not Ext.Entity.Get(character).CampPresence or not Scenario.Current() then
            L.Debug("ReturnToCamp", character)
            -- need ~2 ticks for changing CampPresence
            WaitTicks(3, function()
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
    "MapTeleported",
    ifBypassStory(function(_, character)
        if Scenario.HasStarted() then
            return
        end

        if U.UUID.Equals(Player.Host(), character) then
            StoryBypass.ClearArea(Player.Host())
        end

        Osi.RemoveStatus(character, "SURPRISED", C.NullGuid)
    end)
)
Event.On(
    "ScenarioCombatStarted",
    ifBypassStory(function()
        StoryBypass.ClearArea(Player.Host())
    end)
)

local function removeAllEntities()
    if Scenario.HasStarted() or not Config.ClearAllEntities then
        return
    end

    if UT.Contains(PersistentVars.RegionsCleared, Player.Region()) then
        return
    end

    Player.Notify(__("Clearing all entities"), true)

    StoryBypass.RemoveAllEntities()

    Osi.Resurrect(C.OriginCharacters.Halsin) -- Halsin will be dead once entering Act 2 for the first time
end
GameState.OnLoad(ifBypassStory(removeAllEntities))

GameState.OnLoad(ifBypassStory(StoryBypass.RemoveAutosave))
