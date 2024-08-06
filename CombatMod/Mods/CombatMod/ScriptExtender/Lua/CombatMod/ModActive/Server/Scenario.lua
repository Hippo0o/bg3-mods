-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                          Structures                                         --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@class Scenario: LibsStruct
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
        local _, value = UT.Find(C.EnemyTier, function(tier)
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

function Object:DetectCombatId()
    self.CombatId = Osi.CombatGetGuidFor(self.CombatHelper)
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

function Action.CalculateLoot()
    local scenario = Current()

    local lootMultiplier = 1
    if PersistentVars.Unlocked.LootMultiplier then
        lootMultiplier = 1.5
    end

    local rolls = scenario:KillScore() * lootMultiplier

    local loot = Item.GenerateLoot(math.floor(rolls), scenario.LootRates)
    L.Dump("Loot", loot, rolls, scenario.LootRates)
    return loot
end

function Action.CalculateKillLoot()
    local scenario = Current()

    local nr = #scenario.KilledEnemies

    local chanceFood = 1
    if nr <= 6 then
        chanceFood = 0.9
    else
        chanceFood = math.max(1, 10 - nr) / 10
    end

    if PersistentVars.Unlocked.LootMultiplier then
        rolls = nr % 2 == 0 and 2 or 1
    end

    local loot = Item.GenerateSimpleLoot(rolls, chanceFood, scenario.LootRates)
    L.Dump(L.ColorText("Kill loot", { 0, 255, 0 }), loot, rolls, chanceFood)
    return loot
end

function Action.GiveReward()
    Player.Notify(__("Dropping loot."))

    local map = Current().Map
    local loot = Action.CalculateLoot()
    Event.Trigger("ScenarioLoot", Current(), loot)

    local reward = Current():KillScore()
    Osi.AddGold(Player.Host(), math.min(reward * 10, 100))
    for _, p in pairs(GU.DB.GetPlayers()) do
        Osi.AddExplorationExperience(p, 100 + reward * 10)
    end

    map:SpawnLoot(loot)
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

    s:DetectCombatId()

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
            :After(function(spawnedChainable)
                return spawnedChainable
                    :After(function(e, posCorrectionChainable)
                        Player.Notify(__("Enemy %s spawned.", e:GetTranslatedName()), true, e:GetId())
                        Event.Trigger("ScenarioEnemySpawned", Current(), e)

                        return posCorrectionChainable
                    end)
                    :After(function(e, corrected)
                        Action.EnemyAdded(e)

                        return Defer(1000)
                    end)
            end)
            :Catch(function()
                waitSpawn = waitSpawn - 1

                L.Error("Spawn limit exceeded.", e:GetId())
                UT.Remove(s.SpawnedEnemies, e)
                Action.EnemyRemoved()
            end)
            :After(function()
                waitSpawn = waitSpawn - 1
            end)
    end

    L.Debug("Enemies queued for spawning.", #toSpawn)
    return WaitUntil(function()
        return waitSpawn == 0
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
            Osi.RemoveStatus(player, "SNEAKING")

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

function Action.EnemyKilled(enemy)
    local loot = Action.CalculateKillLoot()

    local x, y, z = Osi.GetPosition(enemy.GUID)

    Item.SpawnLoot(loot, x, y, z)
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
                UT.Remove(s.SpawnedEnemies, e)
            elseif Osi.IsDead(e.GUID) ~= 1 and Osi.IsInCombat(e.GUID) ~= 1 then
                L.Error("Failsafe triggered.", e:GetId(), e.GUID)
                Osi.SetVisible(e.GUID, 1) -- sneaky shits never engage combat

                local x, y, z = s.Map:GetSpawn(-1)
                Osi.TeleportToPosition(e.GUID, x, y, z, "", 1, 1, 1, 0, 1)

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

                        UT.Remove(s.SpawnedEnemies, e)
                        e:Clear()
                    end
                end)
            end
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

    s.KilledEnemies = UT.Map(s.KilledEnemies, function(v, k)
        return Enemy.Restore(v), tonumber(k)
    end)
    s.SpawnedEnemies = UT.Map(s.SpawnedEnemies, function(v, k)
        return Enemy.Restore(v), tonumber(k)
    end)
    s.Enemies = UT.Map(s.Enemies, function(v, k)
        return UT.Map(v, function(e)
            return Enemy.Restore(e)
        end), tonumber(k)
    end)

    s.Timeline = UT.Map(s.Timeline, function(v, k)
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

    local timeline = template.Timeline

    local maps = Map.Get()
    if #maps == 0 then
        L.Error("Starting scenario failed.", "No maps found.")
        return
    end

    if template.Map ~= nil then
        map = UT.Find(maps, function(m)
            return m.Name == template.Map
        end) or map
    end

    if map == nil then
        map = maps[math.random(#maps)]
    end

    if type(timeline) == "function" then
        timeline = timeline(template, map)
    end

    scenario.Name = template.Name
    scenario.Map = map
    scenario.Timeline = timeline
    scenario.Positions = template.Positions or {}

    scenario.LootRates = template.Loot or C.LootRates

    local enemyCount = 0
    for round, definitions in pairs(scenario.Timeline) do
        L.Dump("Adding enemies for round.", round, definitions)
        for _, definition in pairs(definitions) do
            local e
            if UT.Contains(C.EnemyTier, definition) then
                e = Enemy.Random(function(e)
                    return e.Tier == definition and Ext.Template.GetTemplate(e.TemplateId) ~= nil
                end)
            else
                e = Enemy.Find(definition)
            end

            if e == nil then
                L.Error("Starting scenario failed.", "Enemy configuration is wrong.")
                return
            end
            enemyCount = enemyCount + 1
            scenario:AddEnemy(round, e)
        end
    end

    if map.Timeline and UT.Size(map.Timeline) > 0 then
        -- pad positions from the map timeline
        if UT.Size(scenario.Positions) < UT.Size(map.Timeline) then
            UT.Merge(scenario.Positions, map.Timeline)
        end

        -- append the map timeline until we have enough positions
        while UT.Size(scenario.Positions) < enemyCount do
            UT.Combine(scenario.Positions, map.Timeline)
        end
    end

    -- get spawn positions for every enemy
    while UT.Size(scenario.Positions) < enemyCount do
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

    Event.Trigger("ScenarioEnded", Current())
    Player.Notify(__("Scenario ended."))
    Current().Map:Clear()

    Action.GiveReward()

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

Scenario.Teleport = Async.Throttle(3000, function()
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
    return S() and U.UUID.Equals(S().CombatHelper, uuid)
end

function Scenario.HasStarted()
    return getmetatable(S()) and S():HasStarted()
end

function Scenario.MarkSpawns(round)
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

    s.Map:VFXSpawns(spawns)
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

---@param specific Enemy|nil
-- we want to have all enemies on the map in combat
function Scenario.CombatSpawned(specific)
    local s = Current()

    local enemies = UT.Filter(s.SpawnedEnemies, function(e)
        return specific == nil or U.Equals(e, specific)
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

            if Osi.IsDead(enemy.GUID) == 1 then
                return true
            end

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

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Events                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

U.Osiris.On(
    "TeleportedFromCamp",
    1,
    "after",
    ifScenario(function(uuid)
        local isPlayer = UT.Find(GU.DB.GetPlayers(), function(character)
            return U.UUID.Equals(character, uuid)
        end)

        if not isPlayer then
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
        if map.Name == s.Map.Name then
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

U.Osiris.On(
    "TeleportedToCamp",
    1,
    "after",
    ifScenario(function(uuid)
        Scenario.CheckShouldStop()
    end)
)

U.Osiris.On(
    "EnteredCombat",
    2,
    "after",
    ifScenario(function(object, combatGuid)
        local s = Current()

        if not s:HasStarted() then
            return
        end

        if s.CombatId ~= combatGuid then
            s:DetectCombatId()
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

        if UT.Find(s.SpawnedEnemies, function(e)
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
U.Osiris.On(
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
    end)
)

-- TODO maybe move to entity events
U.Osiris.On(
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
                Action.EnemyKilled(e)

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

U.Osiris.On(
    "TurnStarted",
    1,
    "before",
    ifScenario(function(uuid)
        local s = Current()

        if U.UUID.Equals(uuid, s.CombatHelper) then
            L.Debug("Combat helper turn started.", uuid)

            -- fallback check
            if not s:IsRunning() then
                Scenario.End()

                return
            end

            s:DetectCombatId()
            Osi.PauseCombat(s.CombatId)

            Action.StartRound()
                :After(function()
                    if Current().Round == 1 then
                        for _, p in pairs(GE.GetParty()) do
                            Osi.LeaveCombat(p.Uuid.EntityUuid)
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
        end
    end)
)

U.Osiris.On(
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

        s:DetectCombatId()

        Scenario.CombatSpawned()

        Scenario.CheckShouldStop()
    end)
)
