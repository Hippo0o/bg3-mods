local unlocks = Require("EndlessBattle/Templates/Unlocks.lua")

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
---@field OnActivate fun(self: Unlock)
---@field Buy fun(self: Unlock)
local Object = Libs.Class({
    Id = nil,
    Name = nil,
    Icon = nil,
    Cost = 0,
    Amount = nil,
    Bought = 0,
    Character = false,
    BoughtBy = {},
    Unlocked = false,
    OnActivate = function() end,
})

function Object:Buy(character)
    self.Bought = self.Bought + 1
    self.BoughtBy[U.UUID.Extract(character)] = true
    self.OnActivate(self, character)
end

function Object:Buyable()
    return self.Unlocked and (self.Amount == nil or self.Bought < self.Amount)
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
    return unlocks
end

function Unlock.Get()
    return PersistentVars.Unlocks
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Events                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

GameState.OnLoad(function()
    local unlocks = PersistentVars.Unlocks or {}
    for _, unlock in ipairs(Unlock.GetTemplates()) do
        local found = UT.Find(unlocks, function(u)
            return u.Id == unlock.Id
        end)

        table.insert(unlocks, Unlock.Restore(found or unlock))
    end
    L.Dump("Unlocks", unlocks)
    PersistentVars.Unlocks = unlocks
end)

Event.On("ScenarioEnded", function(scenario)
    Unlock.CalculateReward(scenario)
end)

Net.On("BuyUnlock", function(event)
    local unlock = UT.Find(PersistentVars.Unlocks, function(u)
        return u.Id == event.Payload.Id
    end)

    L.Dump("Unlock", unlock, found)

    if unlock == nil then
        Net.Respond(event, { false, "Unlock not found." })
        return
    end

    if not unlock:Buyable() then
        Net.Respond(event, { false, "Unlock out of stock." })
        return
    end

    if unlock.Character and not event.Payload.Character then
        Net.Respond(event, { false, "Unlock needs a character." })
        return
    end

    if unlock.Cost > PersistentVars.Currency then
        Net.Respond(event, { false, "Not enough currency." })
        return
    end

    unlock:Buy(event.Payload.Character or Player.Host(event:UserId()))
    PersistentVars.Currency = PersistentVars.Currency - unlock.Cost

    Net.Respond(event, { true, PersistentVars.Currency })
    Net.Send("SyncState", PersistentVars)
end)
