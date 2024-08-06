local unlocks = Require("CombatMod/Templates/Unlocks.lua")

local persistentUnlocks = IO.LoadJson("Save/Unlocks.json") or {}
local function persistUnlock(unlock)
    persistentUnlocks[unlock.Id] = unlock.Bought

    IO.SaveJson("Save/Unlocks.json", persistentUnlocks)
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                          Structures                                         --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@class Unlock : LibsClass
---@field Id string
---@field Name string
---@field Icon string
---@field Cost integer
---@field Amount integer|nil
---@field Bought integer
---@field BoughtBy table<string, bool> -- Character GUID
---@field Character boolean
---@field Unlocked boolean
---@field Requirement string|nil
---@field Persistent boolean
---@field OnBuy fun(self: Unlock)
---@field OnLoad fun(self: Unlock)
---@field Buy fun(self: Unlock)
local Object = Libs.Class({
    Id = nil,
    Name = nil,
    Icon = nil,
    Cost = 0,
    Amount = nil,
    Character = false,
    Bought = 0,
    BoughtBy = {},
    Unlocked = false,
    Requirement = nil,
    Persistent = false,
    OnBuy = function() end,
    OnLoad = function() end,
})

function Object:Buy(character)
    self.Bought = self.Bought + 1
    self.BoughtBy[U.UUID.Extract(character)] = true
    self.OnBuy(self, character)

    if self.Persistent then
        persistUnlock(self)
    end
end

function Object:Buyable()
    return self.Unlocked and (self.Amount == nil or self.Bought < self.Amount)
end

function Object:UpdateUnlocked()
    if self.Requirement == nil then
        self.Unlocked = true
        return
    end

    local function unlockByScore(requirement)
        if type(requirement) == "number" then
            return PersistentVars.RogueScore >= requirement
        end
    end
    local function unlockByBought(requirement)
        if type(requirement) == "string" then
            local u = UT.Find(Unlock.Get(), function(u)
                return u.Id == requirement
            end)
            return u and u.Bought > 0
        end
    end

    local requirement = self.Requirement
    if type(requirement) ~= "table" then
        requirement = { requirement }
    end

    local unlocked = true
    for _, r in pairs(requirement) do
        unlocked = unlocked and (unlockByScore(r) or unlockByBought(r))
    end

    self.Unlocked = unlocked and true or false
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                            Public                                           --
--                                                                                             --
-------------------------------------------------------------------------------------------------

function Unlock.Restore(unlock)
    return Object.Init(unlock)
end

function Unlock.CalculateReward(scenario)
    local endRound = scenario.Round - 1
    local diff = endRound - scenario:TotalRounds()

    local rewardMulti = math.max(5 - diff, 1)
    if PersistentVars.Unlocked.CurrencyMultiplier then
        rewardMulti = rewardMulti * 1.2
    end

    local reward = 0
    for _, e in pairs(scenario.KilledEnemies) do
        local _, value = UT.Find(C.EnemyTier, function(tier)
            return tier == e.Tier
        end)
        if value == nil then
            U.Error("Invalid tier for enemy", e.Tier, e.Name)
            value = 1
        end
        reward = reward + value
    end

    PersistentVars.Currency = (PersistentVars.Currency or 0) + math.ceil(reward * rewardMulti)
end

function Unlock.GetTemplates()
    return UT.Combine({}, unlocks, External.Templates.GetUnlocks())
end

function Unlock.Get()
    return PersistentVars.Unlocks
end

function Unlock.Sync()
    for _, unlockTemplate in pairs(Unlock.GetTemplates()) do
        local existing = UT.Find(PersistentVars.Unlocks, function(p)
            return p.Id == unlockTemplate.Id
        end)

        if not existing then
            table.insert(PersistentVars.Unlocks, unlockTemplate)
        else
            -- update keys from template that aren't stateful
            UT.Merge(existing, unlockTemplate)
        end
    end

    for i, u in pairs(PersistentVars.Unlocks) do
        if u.Persistent then
            if persistentUnlocks[u.Id] and persistentUnlocks[u.Id] > 0 then
                u.Bought = persistentUnlocks[u.Id]
            end
        end

        local existing = UT.Find(Unlock.GetTemplates(), function(p)
            return p.Id == u.Id
        end)

        if not existing then
            u.Amount = -1
            u.Requirement = ""
        end

        PersistentVars.Unlocks[i] = Unlock.Restore(u)

        if existing then
            -- TODO check makes sense to call this here
            PersistentVars.Unlocks[i]:OnLoad()
        end
    end

    Unlock.UpdateUnlocked()
end

function Unlock.UpdateUnlocked()
    for _, u in pairs(Unlock.Get()) do
        u:UpdateUnlocked()
    end
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Events                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

Event.On("ModActive", function()
    Unlock.Sync()

    GameState.OnLoad(Unlock.Sync)

    GameState.OnSave(function()
        for i, u in ipairs(PersistentVars.Unlocks) do
            PersistentVars.Unlocks[i] = UT.Clean(u)
        end
    end)
end, true)

Event.On("ScenarioEnded", function(scenario)
    Unlock.CalculateReward(scenario)
end)

Event.On("RogueScoreChanged", function()
    Unlock.UpdateUnlocked()
end)

Net.On("BuyUnlock", function(event)
    local unlock = UT.Find(Unlock.Get(), function(u)
        return u.Id == event.Payload.Id
    end)

    local function soundFail()
        Osi.PlaySoundResource(event:Character(), "294bbcfa-fd7b-d8bf-bba1-5b790f8518af")
    end
    local function soundSuccess()
        Osi.PlaySoundResource(event:Character(), "a6571b9a-0b79-6712-6326-a0e3134ed0ad")
    end

    if unlock == nil then
        Net.Respond(event, { false, "Unlock not found." })
        soundFail()
        return
    end

    if not unlock:Buyable() then
        Net.Respond(event, { false, "Unlock out of stock." })
        soundFail()
        return
    end

    if unlock.Character and not event.Payload.Character then
        Net.Respond(event, { false, "Unlock needs a character." })
        soundFail()
        return
    end

    if unlock.Cost > PersistentVars.Currency then
        Net.Respond(event, { false, "Not enough currency." })
        soundFail()

        return
    end

    unlock:Buy(event.Payload.Character or event:Character())
    PersistentVars.Currency = PersistentVars.Currency - unlock.Cost
    soundSuccess()

    Net.Respond(event, { true, PersistentVars.Currency })
    Unlock.UpdateUnlocked()

    Net.Send("SyncState", PersistentVars)
end)
