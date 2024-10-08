-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                          Structures                                         --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@class Scenario: Struct
---@field Name string
---@field Enemies table<number, Enemy[]>
---@field KilledEnemies Enemy[]
---@field SpawnedEnemies Enemy[]
---@field Map Map
---@field CombatId string
---@field CombatHelper string
---@field Round integer
---@field Timeline table<string, number> Round, Amount of enemies
---@field Positions table<number, number> Index, Spawn
---@field LootRates table<string, table<string, number>>
---@field OnMap boolean
---@field New fun(self): self
local Object = Libs.Struct({
    Name = nil,
    Enemies = {},
    KilledEnemies = {},
    SpawnedEnemies = {},
    Map = nil,
    CombatId = nil,
    OnMap = false,
    Round = 0,
    Timeline = {},
    Positions = {},
    LootRates = {},
    CombatHelper = nil,
    EnemyFallback = {},
})

---@param round number
---@param enemy Enemy
function Object:AddEnemy(round, enemy)
    for i = 1, round do
        if self.Enemies[i] == nil then
            self.Enemies[i] = {}
        end
    end

    table.insert(self.Enemies[round], enemy)
end

---@return Enemy[]
function Object:SpawnsForRound()
    return self.Enemies[self.Round] or {}
end

function Object:GetPosition(enemyIndex, forRound)
    if not forRound then
        forRound = self.Round
    end

    local posIndex = 0
    for round, enemies in pairs(self.Enemies) do
        if round < forRound then
            posIndex = posIndex + #enemies
        end
    end

    return self.Positions[posIndex + enemyIndex] or -1
end

function Object:TotalRounds()
    return #self.Timeline
end

function Object:HasMoreRounds()
    return self.Round < self:TotalRounds()
end

function Object:HasStarted()
    return #self.SpawnedEnemies > 0 or self.Round > 0
end

function Object:IsRunning()
    return #self.SpawnedEnemies > 0 or self:HasMoreRounds()
end

function Object:KillScore()
    local score = 0
    for _, e in pairs(self.KilledEnemies) do
        local _, value = table.find(C.EnemyTier, function(tier)
            return tier == e.Tier
        end)

        if value == nil then
            L.Error("Invalid tier for enemy", e.Tier, e.Name)
            value = 1
        end

        score = score + value
    end

    return score
end

---@return Scenario|nil
local function S()
    return PersistentVars.Scenario
end

---@return Scenario
local function Current()
    assert(S() ~= nil, "Scenario not started.")

    return S()
end

local function ifScenario(func)
    return function(...)
        if S() == nil then
            return
        end
        func(...)
    end
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Actions                                           --
--                                                                                             --
-------------------------------------------------------------------------------------------------
-- functions that only get called as part of events
-- TODO cleanup code smh

local Action = {}

function Action.GiveReward()
    local reward = Current():KillScore()

    Osi.AddGold(Player.Host(), math.min(reward * 10, 100))
    for _, p in pairs(GU.DB.GetPlayers()) do
        Osi.AddExplorationExperience(p, 100 + reward * 10)
    end
end

function Action.SpawnHelper()
    local s = Current()

    if s.CombatHelper then
        return
    end

    Player.Notify(__("Combat is Starting."))

    local x, y, z = table.unpack(s.Map.Enter)

    local helper = Osi.CreateAt(C.ScenarioHelper.TemplateId, x, y, z, 0, 1, "")
    if not helper then
        L.Error("Failed to create combat helper.")
        Scenario.Stop()
        return
    end

    Osi.SetTag(helper, "9787450d-f34d-43bd-be88-d2bac00bb8ee") -- AI_UNPREFERRED_TARGET
    Osi.SetFaction(helper, C.ScenarioHelper.Faction)
    s.CombatHelper = helper

    Action.UpdateHelperName()

    L.Debug("Combat helper spawned.", helper)
end

function Action.RemoveHelper()
    local s = Current()
    if s.CombatHelper then
        GU.Object.Remove(s.CombatHelper)
    end
end

function Action.UpdateHelperName()
    local s = Current()

    local text = {
        __("Scenario: %s", tostring(s.Name)),
        __("Round: %s", tostring(s.Round)),
        __("Total Rounds: %s", tostring(#s.Timeline)),
        __("Upcoming Spawns: %s", tostring(#(s.Enemies[s.Round + 1] or {}))),
        __("Kill Score: %s", s:KillScore()),
    }

    Ext.Loca.UpdateTranslatedString(C.ScenarioHelper.Handle, table.concat(text, "\n"))
end

function Action.StartCombat()
    local s = Current()

    Scenario.DetectCombatId()

    -- s.Map:PingSpawns()

    Event.Trigger("ScenarioCombatStarted", s)
end

---@return ChainableRunner
function Action.SpawnRound()
    local s = Current()
    local toSpawn = s:SpawnsForRound()

    if #toSpawn == 0 then
        L.Debug("No enemies to spawn.", s.Round)

        return Schedule()
    end

    local triesToSpawn = #s.Map.Spawns
    if triesToSpawn < 5 then
        triesToSpawn = 5
    end
    triesToSpawn = triesToSpawn * 2

    local waitSpawn = 0
    for i, e in ipairs(toSpawn) do
        table.insert(s.SpawnedEnemies, e)
        waitSpawn = waitSpawn + 1

        -- spawning multiple enemies at once will cause bugs when templates get overwritten
        RetryUntil(function(_, triesLeft)
                local posIndex = s:GetPosition(i)
                if triesLeft < triesToSpawn / 2 then
                    posIndex = -1
                end

                L.Debug("Spawning enemy.", e:GetId(), posIndex)

                local ok, chainable = s.Map:SpawnIn(e, posIndex, s.CombatHelper)

                if not ok then
                    return false
                end

                return chainable
            end, {
                immediate = true,
                retries = triesToSpawn,
                interval = 100,
            })
            :After(function(enemy, posCorrectionChainable)
                Player.Notify(__("Enemy %s spawned.", enemy:GetTranslatedName()), true, enemy:GetId())
                Event.Trigger("ScenarioEnemySpawned", Current(), enemy)

                return posCorrectionChainable
            end)
            :After(function(e, corrected)
                Action.EnemyAdded(e)

                Scenario.CloseEnemyDistance(e)

                return Defer(1000)
            end)
            :Catch(function()
                L.Error("Spawn limit exceeded.", e:GetId())
                table.removevalue(s.SpawnedEnemies, e)
                Action.EnemyRemoved()

                if e:IsSpawned() then
                    e:Clear()
                end
            end)
            :Final(function()
                waitSpawn = waitSpawn - 1
            end)
    end

    L.Debug("Enemies queued for spawning.", #toSpawn)
    local failsafe = 0
    return WaitUntil(function()
        failsafe = failsafe + 1
        return waitSpawn == 0 or failsafe > #toSpawn * 10
    end)
end

---@return ChainableRunner
function Action.StartRound()
    local s = Current()

    if s.Round == 0 then
        Action.StartCombat()
    end

    s.Round = s.Round + 1
    Player.Notify(__("Round %d", s.Round))

    Event.Trigger("ScenarioRoundStarted", s)

    Action.UpdateHelperName()

    return Action.SpawnRound():After(function()
        Scenario.MarkSpawns(s.Round + 1)

        Event.Trigger("ScenarioRoundSpawned", s)

        return true
    end)
end

function Action.NotifyStarted()
    local id = tostring(S())

    return RetryUntil(function(self)
        if tostring(S()) ~= id then
            self:Clear()
            return
        end
        if S().OnMap then
            return true
        end

        Player.Notify(__("Leave camp to join the battle."))

        return false
    end, {
        retries = 5,
        interval = 30000,
        immediate = true,
    })
end

-- map entered from camp or teleport
function Action.MapEntered()
    if Current():HasStarted() then
        return
    end

    Action.SpawnHelper()

    Schedule(function()
        -- remove corpses from previous combat
        Enemy.Cleanup()

        Event.Trigger("ScenarioMapEntered", Current())
        Player.Notify(__("Entered combat area."))

        for i, guid in pairs(Current().Map.Helpers) do
            StoryBypass.ClearSurfaces(guid, 4)
        end

        -- clearing should be over by then
        WaitTicks(33, function()
            Scenario.MarkSpawns(1)
        end)
    end)

    RetryUntil(function()
        if not S() then
            return true
        end

        for _, player in pairs(GU.DB.GetPlayers()) do
            if Osi.HasActiveStatus(player, "SNEAKING") == 1 then
                Osi.RemoveStatus(player, "SNEAKING")

                Defer(1000, function()
                    Osi.ApplyStatus(player, "SNEAKING", -1)
                end)
            end

            Osi.SetHostileAndEnterCombat(C.ScenarioHelper.Faction, Osi.GetFaction(player), S().CombatHelper, player)
        end

        return Player.InCombat()
    end, {
        immediate = true,
        retries = -1,
        interval = 200,
    })
end

function Action.EnemyAdded(enemy)
    Scenario.CombatSpawned(enemy)
end

-- Enemy died or couldnt spawn
function Action.EnemyRemoved()
    Scenario.CheckEnded()
end

-- Enemy spawned but is out of bounds
-- Player needs to be in combat for this to work
function Action.Failsafe(enemy)
    if not Player.InCombat() then
        return
    end

    local s = Current()

    local list = enemy and { enemy } or s.SpawnedEnemies
    if #list > 0 then
        L.Dump("Running failsafe.", list)

        for _, e in pairs(list) do
            if not e:IsSpawned() then
                L.Error("Failsafe triggered.", e:GetId(), e.GUID)
                table.removevalue(s.SpawnedEnemies, e)
            elseif Osi.IsDead(e.GUID) ~= 1 and Osi.IsInCombat(e.GUID) ~= 1 then
                L.Error("Failsafe triggered.", e:GetId(), e.GUID)
                Osi.SetVisible(e.GUID, 1) -- sneaky shits never engage combat

                s.Map:TeleportToSpawn(e.GUID, -1)

                e:Combat(true)

                Defer(2000):After(function()
                    if Osi.IsInCombat(e.GUID) == 1 then
                        return
                    end

                    L.Error("Failsafe 2 triggered.", e:GetId(), e.GUID)

                    e:Combat(true)

                    return Defer(3000)
                end):After(function()
                    if Osi.IsInCombat(e.GUID) ~= 1 then
                        L.Error("Failsafe 3 triggered.", e:GetId(), e.GUID)

                        table.removevalue(s.SpawnedEnemies, e)
                        e:Clear()
                    end
                end)
            end
        end
    end
end

function Action.EnemyFallback(enemy)
    local s = Current()

    local uuid = enemy.GUID

    if Enemy.IsValid(uuid) and GC.IsValid(uuid) then
        local resources = get(Ext.Entity.Get(uuid).ActionResources, "Resources")
        if
            resources
            and resources["734cbcfb-8922-4b6d-8330-b2a7e4c14b6a"][1].Amount > 0
            and Osi.GetHitpointsPercentage(uuid) > 95
        then
            s.EnemyFallback[uuid] = (s.EnemyFallback[uuid] or 0) + 1
        else
            s.EnemyFallback[uuid] = (s.EnemyFallback[uuid] or 0) - 1
        end

        if s.EnemyFallback[uuid] > 2 then
            s.Map:TeleportToSpawn(uuid, -1)

            s.EnemyFallback[uuid] = 2
        end
    end
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                            Public                                           --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@return table
function Scenario.GetTemplates()
    return External.Templates.GetScenarios()
end

---@return Scenario|nil
function Scenario.Current()
    return S()
end

---@param state Scenario
function Scenario.RestoreFromSave(state)
    xpcall(function()
        PersistentVars.Scenario = Scenario.Restore(state)

        Player.Notify(__("Scenario restored."))

        if not S():HasStarted() then
            if S().OnMap then
                Action.MapEntered()
            else
                Action.NotifyStarted()
            end
        else
            -- to not break older saves, will add a filler turn
            if not S().CombatHelper then
                Action.SpawnHelper()
            end
        end

        Event.Trigger("ScenarioRestored", S())
    end, function(err)
        L.Error(err)
        Enemy.Cleanup()
        PersistentVars.Scenario = nil
        Player.Notify(__("Failed to restore scenario."))
    end)
end

---@param scenario Scenario
---@return Scenario
function Scenario.Restore(scenario)
    local s = Object.Init(scenario)

    s.KilledEnemies = table.map(s.KilledEnemies, function(v, k)
        return Enemy.Restore(v), tonumber(k)
    end)
    s.SpawnedEnemies = table.map(s.SpawnedEnemies, function(v, k)
        return Enemy.Restore(v), tonumber(k)
    end)
    s.Enemies = table.map(s.Enemies, function(v, k)
        return table.map(v, function(e)
            return Enemy.Restore(e)
        end), tonumber(k)
    end)

    s.Timeline = table.map(s.Timeline, function(v, k)
        return v, tonumber(k)
    end)

    s.Map = Map.Restore(scenario.Map)

    return s
end

---@param template table
---@param map Map|nil
function Scenario.Start(template, map)
    if S() ~= nil then
        L.Error("Scenario already started.")
        return
    end

    ---@type Enemy[]
    local enemies = {}

    ---@type Scenario
    local scenario = Object.New()

    local maps = Map.Get()
    if #maps == 0 then
        L.Error("Starting scenario failed.", "No maps found.")
        return
    end

    if type(template.OnStart) == "function" then
        template:OnStart()
    end

    if template.Map ~= nil then
        if type(template.Map) == "function" then
            map = template:Map()
        else
            map = table.find(maps, function(m)
                return m.Name == template.Map
            end) or map
        end
    end

    if map == nil then
        map = maps[math.random(#maps)]
    end

    local timeline = template.Timeline

    if type(timeline) == "function" then
        timeline = timeline(template, map)
    end

    scenario.Name = template.Name
    scenario.Map = map
    scenario.Timeline = timeline
    scenario.Positions = template.Positions or {}

    scenario.LootRates = template.Loot or C.LootRates

    local enemyTemplates = nil
    if template.Enemies then
        if type(template.Enemies) == "function" then
            enemyTemplates = template:Enemies()
        else
            enemyTemplates = template.Enemies
        end
    end
    local function getEnemy(definition)
        if table.contains(C.EnemyTier, definition) then
            local enemies = Enemy.GetByTier(definition, enemyTemplates)

            return enemies[math.random(#enemies)]
        end

        return Enemy.Find(definition, enemyTemplates)
    end

    local enemyCount = 0
    for round, definitions in pairs(scenario.Timeline) do
        L.Dump("Adding enemies for round.", round, definitions)
        for _, definition in pairs(definitions) do
            local e = getEnemy(definition)

            if e == nil then
                L.Error("Starting scenario failed.", "Enemy configuration is wrong.")
                return
            end
            enemyCount = enemyCount + 1
            scenario:AddEnemy(round, e)
        end
    end

    if map.Timeline and table.size(map.Timeline) > 0 then
        -- append positions from the map timeline until we have enough positions
        while table.size(scenario.Positions) < enemyCount do
            table.extend(scenario.Positions, map.Timeline)
        end
    end

    -- get spawn positions for every enemy
    while table.size(scenario.Positions) < enemyCount do
        table.insert(scenario.Positions, math.random(#map.Spawns))
    end

    Player.Notify(__("Scenario %s started.", template.Name))
    PersistentVars.Scenario = scenario

    Action.NotifyStarted()

    Enemy.Cleanup()
    Player.ReturnToCamp()

    Event.Trigger("ScenarioStarted", Current())
end

function Scenario.End()
    Action.RemoveHelper()

    Player.Notify(__("Scenario ended."))
    Current().Map:Clear()
    Action.GiveReward()

    Event.Trigger("ScenarioEnded", Current())

    PersistentVars.LastScenario = S()
    PersistentVars.Scenario = nil
end

function Scenario.Stop()
    Action.RemoveHelper()
    Event.Trigger("ScenarioStopped", Current())
    Enemy.Cleanup()
    Current().Map:Clear()

    PersistentVars.Scenario = nil
    Player.Notify(__("Scenario stopped."))
end

Scenario.Teleport = Throttle(3000, function()
    local s = Current()

    for _, p in pairs(GE.GetParty()) do
        s.Map:Teleport(p.Uuid.EntityUuid)
    end

    Event.Trigger("ScenarioTeleporting", s)
end)

function Scenario.CheckEnded()
    local s = Current()
    if not s:HasMoreRounds() then
        if #s.SpawnedEnemies == 0 then
            Player.Notify(__("All enemies are dead."))
            Scenario.End()
        else
            Player.Notify(__("%d enemies left.", #s.SpawnedEnemies))
        end
    end
end

function Scenario.CheckShouldStop()
    if not Current().OnMap then
        return
    end

    if Player.InCamp() and not Player.InCombat() then
        Scenario.Stop()
        Player.Notify(__("Returned to camp."))
    end
end

function Scenario.IsHelper(uuid)
    if not S() then
        return false
    end

    return U.UUID.Equals(S().CombatHelper, uuid)
        or table.find(S().Map.Helpers, function(helper)
                return U.UUID.Equals(helper, uuid)
            end)
            ~= nil
end

function Scenario.HasStarted()
    return getmetatable(S()) and S():HasStarted()
end

function Scenario.MarkSpawns(round, duration)
    local s = Current()

    local toSpawn = s.Enemies[round]

    local spawns = {}
    for i, e in ipairs(toSpawn or {}) do
        local posIndex = s:GetPosition(i, round)
        if posIndex == -1 then
            return
        end

        table.insert(spawns, posIndex)
    end

    s.Map:VFXSpawns(spawns, duration or 6)
end

function Scenario.ForwardCombat()
    local s = Current()
    if not s:IsRunning() then
        L.Error("Scenario has ended.")
        Scenario.CheckEnded()

        return
    end

    if not s.OnMap then
        return
    end

    Action.StartRound()

    Osi.ResumeCombat(s.CombatId)
end

function Scenario.DetectCombatId()
    local s = Current()

    s.CombatId = Osi.CombatGetGuidFor(s.CombatHelper)
end

function Scenario.TeleportHelper()
    local s = Current()

    RetryUntil(function()
        local x1, y1, z1 = table.unpack(s.Map.Enter)

        local x2, y2, z2 = table.unpack(s.Map.Enter)

        local max = 0
        for _, player in ipairs(GU.DB.GetPlayers()) do
            local d = Osi.GetDistanceTo(player, s.CombatHelper)
            if d > max then
                max = d
                x2, y2, z2 = Osi.GetPosition(player)
            end
        end

        local x3, y3, z3 = table.unpack(s.Map.Enter)

        local max = 0
        for _, enemy in ipairs(s.SpawnedEnemies) do
            local d = Osi.GetDistanceTo(enemy.GUID, s.CombatHelper)
            if d > max then
                max = d
                x3, y3, z3 = Osi.GetPosition(enemy.GUID)
            end
        end

        local x = (x1 + x2 + x3) / 3
        local y = (y1 + y2 + y3) / 3
        local z = (z1 + z2 + z3) / 3

        if Osi.GetDistanceToPosition(s.CombatHelper, x, y, z) < 10 then
            return true
        end

        Osi.TeleportToPosition(s.CombatHelper, x, y, z, "", 1, 1, 1, 0, 0)
        return false
    end)
end

---@param specific Enemy|nil
-- we want to have all enemies on the map in combat
function Scenario.CombatSpawned(specific)
    local s = Current()

    local enemies = table.filter(s.SpawnedEnemies, function(e)
        return specific == nil or eq(e, specific)
    end)

    L.Debug("Combat spawned.", #enemies)

    for _, enemy in ipairs(enemies) do
        RetryUntil(function()
            if not S() then
                return true
            end

            if not enemy:IsSpawned() then
                return false
            end

            -- if Osi.IsDead(enemy.GUID) == 1 then
            --     return true
            -- end

            enemy:Combat(true)

            Osi.SetHostileAndEnterCombat(C.ScenarioHelper.Faction, C.EnemyFaction, s.CombatHelper, enemy.GUID)

            if S().CombatId then -- TODO check if works
                Osi.PROC_EnterCombatByID(enemy.GUID, S().CombatId)
            end

            return Osi.IsInCombat(enemy.GUID) == 1
        end, {
            immediate = true,
            retries = 5,
            interval = 1000,
        }):Catch(ifScenario(function()
            Action.Failsafe(enemy)
        end))
    end
end

function Scenario.GroupDistantEnemies()
    local s = Current()

    if not Config.GroupDistantEnemies then
        return
    end

    local enemies = table.filter(s.SpawnedEnemies, function(e)
        return e:IsSpawned() and string.contains(e.Tier, { table.unpack(C.EnemyTier, 1, 3) })
    end)

    for _, enemy in ipairs(enemies) do
        local uuid = enemy.GUID

        local x, y, z = Osi.GetPosition(uuid)

        local distance = Enemy.DistanceToParty(uuid)

        local shouldSwarm = #s.SpawnedEnemies > 11 and distance > 20 or distance > 30

        if shouldSwarm then
            Osi.RequestSetSwarmGroup(uuid, "TOT_Swarm_Group")
            L.Debug("Enemy added to swarm", uuid, distance, Osi.GetSwarmGroup(uuid))
        else
            if Osi.GetSwarmGroup(uuid) then
                Osi.RequestSetSwarmGroup(uuid, "")
            end
        end
    end
    -- local enemy = table.find(s.SpawnedEnemies, function(e)
    --     return U.UUID.Equals(e.GUID, uuid)
    -- end)
    --
    -- if not enemy or enemy.Temporary or enemy.IsBoss then
    --     return
    -- end
    -- for i, tier in ipairs(C.EnemyTier) do
    --     if i > 3 then
    --         break
    --     end
    --
    --     if enemy.Tier == tier then
    --         Osi.StopFollow(uuid)
    --         if #s.SpawnedEnemies > i * 11 then
    --             -- Osi.ApplyStatus(uuid, "COMMAND_APPROACH", -1)
    --
    --             Defer(2000, function()
    --                 Osi.Follow(uuid, Osi.GetClosestAlivePlayer(uuid) or Player.Host())
    --                 Osi.EndTurn(uuid)
    --             end)
    --
    --             Defer(4000, function()
    --                 Osi.StopFollow(uuid)
    --             end)
    --         end
    --
    --         break
    --     end
    -- end
end

---@param specific Enemy|nil
function Scenario.CloseEnemyDistance(specific, maxDistance)
    local s = Current()

    local enemies = table.filter(s.SpawnedEnemies, function(e)
        return specific == nil or eq(e, specific)
    end)

    if not maxDistance then
        maxDistance = 40
    end

    local adjusting = table.map(enemies, function(enemy)
        local x, y, z = Osi.GetPosition(enemy.GUID)

        local distance, x2, y2, z2 = Enemy.DistanceToParty(enemy.GUID)

        if distance < maxDistance then
            return
        end

        local closestSpawn = -1
        local closest = 999
        for i, spawn in ipairs(s.Map.Spawns) do
            local d = Ext.Math.Distance({ x, y, z }, spawn)
            local d2 = Ext.Math.Distance({ x2, y2, z2 }, spawn)

            if d < d2 and d2 < maxDistance and closest > d then
                closestSpawn = i
                closest = d
            end
        end

        local _, chainable = s.Map:TeleportToSpawn(enemy.GUID, closestSpawn, true)

        return chainable
    end)

    return WaitUntil(function()
        return #table.filter(adjusting, function(chainable)
            return chainable:IsDone()
        end) == 0
    end)
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Events                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

Ext.Osiris.RegisterListener(
    "TeleportedFromCamp",
    1,
    "after",
    ifScenario(function(uuid)
        if not Player.IsPlayer(uuid) then
            return
        end

        Osi.DetachFromPartyGroup(uuid)

        WaitTicks(6, function()
            if Ext.Entity.Get(uuid).CampPresence or not Ext.Entity.Get(uuid).ClientControl then
                return
            end

            Scenario.Teleport()
        end)
    end)
)

Event.On(
    "MapTeleported",
    ifScenario(function(map, character)
        local s = Current()
        if map.Name == s.Map.Name and not GameState.IsLoading() then
            if not s.OnMap and U.UUID.Equals(character, Player.Host()) then
                s.OnMap = true
                WaitTicks(33, Action.MapEntered)
                if not s.Map:Prepare() then
                    Scenario.Stop()
                end
            end

            Event.Trigger("ScenarioTeleported", character)
        end
    end)
)

Ext.Osiris.RegisterListener(
    "TeleportedToCamp",
    1,
    "after",
    ifScenario(function(uuid)
        Scenario.CheckShouldStop()
    end)
)

Ext.Osiris.RegisterListener(
    "EnteredCombat",
    2,
    "after",
    ifScenario(function(object, combatGuid)
        local s = Current()

        if not s:HasStarted() then
            return
        end

        if s.CombatId ~= combatGuid then
            Scenario.DetectCombatId()
        end

        if s.CombatId ~= combatGuid then -- should not happen
            return
        end

        if Osi.IsCharacter(object) ~= 1 then
            return
        end

        local guid = U.UUID.Extract(object)

        if not GC.IsNonPlayer(guid) then
            Schedule(function()
                Osi.ResumeCombat(combatGuid)
            end)
            return
        end

        if table.find(s.SpawnedEnemies, function(e)
            return U.UUID.Equals(e.GUID, guid)
        end) then
            return
        end

        if PersistentVars.SpawnedEnemies[guid] then
            return
        end

        L.Debug("Entered combat.", guid, combatGuid)
        Schedule(function()
            local e = Enemy.CreateTemporary(guid)

            if Osi.IsAlly(Player.Host(), guid) == 0 then
                table.insert(s.SpawnedEnemies, e)
                Player.Notify(__("Enemy %s joined.", e:GetTranslatedName()))

                Event.Trigger("ScenarioEnemySpawned", Current(), e)

                Action.EnemyAdded(e)
            end
        end)
    end)
)

-- TODO maybe move to entity events
Ext.Osiris.RegisterListener(
    "Resurrected",
    1,
    "before",
    ifScenario(function(uuid)
        local s = Current()

        if not s:HasStarted() then
            return
        end

        for i, e in ipairs(s.KilledEnemies) do
            if U.UUID.Equals(e.GUID, uuid) then
                if Osi.IsDead(e.GUID) ~= 0 then
                    -- manually killed on resurrection
                    return
                end
                if Osi.IsAlly(e.GUID, Player.Host()) == 1 then
                    -- resurrected enemy as ally
                    return
                end

                -- let it count twice for loot
                table.insert(s.SpawnedEnemies, e)
                Player.Notify(__("Enemy %s rejoined.", e:GetTranslatedName()))
                -- table.remove(s.KilledEnemies, i)

                Action.EnemyAdded(e)
                return
            end
        end

        Enemy.Combat(uuid, true)
    end)
)

-- TODO maybe move to entity events
Ext.Osiris.RegisterListener(
    "Died",
    1,
    "before",
    ifScenario(function(uuid)
        local s = Current()

        if not s:HasStarted() then
            return
        end

        local spawnedKilled = false
        for i, e in ipairs(s.SpawnedEnemies) do
            if U.UUID.Equals(e.GUID, uuid) then
                -- avoid rewarding summons
                if Osi.IsSummon(e.GUID) ~= 1 then
                    table.insert(s.KilledEnemies, e)
                end

                table.remove(s.SpawnedEnemies, i)

                -- might revive and rejoin battle
                Player.Notify(__("Enemy %s killed.", e:GetTranslatedName()))
                Event.Trigger("ScenarioEnemyKilled", Current(), e)

                spawnedKilled = true
                break
            end
        end

        if not spawnedKilled then
            L.Debug("Non-spawned enemy killed.", uuid)
            return
        end

        Action.EnemyRemoved()
    end)
)

Ext.Osiris.RegisterListener(
    "TurnEnded",
    1,
    "after",
    ifScenario(function(uuid)
        local s = Current()

        if Player.IsPlayer(uuid) then
            Scenario.GroupDistantEnemies()
        end

        local enemy = table.find(s.SpawnedEnemies, function(e)
            return U.UUID.Equals(e.GUID, uuid)
        end)

        if enemy then
            Action.EnemyFallback(enemy)
        end
    end)
)

Ext.Osiris.RegisterListener(
    "TurnStarted",
    1,
    "before",
    ifScenario(function(uuid)
        local s = Current()

        if not U.UUID.Equals(uuid, s.CombatHelper) then
            return
        end
        L.Debug("Combat helper turn started.", uuid)

        -- fallback check
        if not s:IsRunning() then
            Scenario.End()

            return
        end

        Scenario.DetectCombatId()
        Osi.PauseCombat(s.CombatId)

        Action.StartRound()
            :After(function()
                if Current().Round == 1 then
                    for _, p in pairs(GE.GetParty()) do
                        Osi.LeaveCombat(p.Uuid.EntityUuid)
                        Defer(1000, function()
                            Osi.ForceTurnBasedMode(p.Uuid.EntityUuid, 1)
                        end)
                    end

                    Player.Notify(__("Combat started."))

                    Scenario.CombatSpawned()
                end

                return Defer(1000)
            end)
            :After(function()
                if Player.InCombat() then
                    return true
                end

                return WaitUntil(function(self)
                    if S() ~= s then
                        self:Clear()
                        return
                    end

                    return Player.InCombat()
                end)
            end)
            :After(function()
                Osi.ResumeCombat(s.CombatId)

                Osi.EndTurn(uuid)
            end)
    end)
)

Ext.Osiris.RegisterListener(
    "CombatRoundStarted",
    2,
    "before",
    ifScenario(function(combatGuid, round)
        local s = Current()

        if not s:HasStarted() then
            return
        end

        if not Player.InCombat() then
            Osi.PauseCombat(combatGuid)
            return
        end

        Scenario.DetectCombatId()

        Scenario.TeleportHelper()

        Scenario.CheckShouldStop()

        Scenario.CloseEnemyDistance():After(function()
            Scenario.GroupDistantEnemies()
        end)

        Scenario.CombatSpawned()

        Scenario.CheckEnded()
    end)
)
