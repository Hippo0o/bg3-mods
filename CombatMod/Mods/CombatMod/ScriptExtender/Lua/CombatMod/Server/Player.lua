-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                            Public                                           --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@param userId number|nil
---@return string GUID of the host character
function Player.Host(userId)
    if userId then
        local player = Osi.GetCurrentCharacter(userId)

        if player then
            return player
        end
    end

    return Osi.GetHostCharacter()
end

---@return string region
function Player.Region()
    return Osi.GetRegion(Player.Host())
end

---@return number x, number y, number z
function Player.Pos()
    return Osi.GetPosition(Player.Host())
end

---@param character string|nil GUID
---@return string|nil GUID
function Player.InCombat(character)
    return UT.Find(GU.DB.GetPlayers(), function(guid)
        return (character == nil or U.UUID.Equals(guid, character)) and Osi.IsInCombat(guid) == 1
    end)
end

---@param character string|nil GUID
---@return string|nil GUID
function Player.InCamp(character)
    return UT.Find(GU.DB.GetPlayers(), function(guid)
        return (character == nil or U.UUID.Equals(guid, character)) and Ext.Entity.Get(guid).CampPresence ~= nil
    end)
end

---@param character string|nil GUID
---@return boolean
function Player.IsPlayer(character)
    return UT.Find(GU.DB.GetPlayers(), function(uuid)
        return U.UUID.Equals(character, uuid)
    end) ~= nil
end

function Player.PickupAll(character)
    for type, data in pairs(PersistentVars.LootFilter) do
        for rarity, pickup in pairs(data) do
            if pickup then
                Item.PickupAll(character or Player.Host(), rarity, type)
            end
        end
    end
end

function Player.PartySize()
    local party = UT.Filter(GU.DB.GetPlayers(), function(guid)
        return Osi.CanJoinCombat(guid) == 1
    end)

    return math.max(1, #party)
end

function Player.DisplayName(character)
    local p = Ext.Entity.Get(character or Player.Host())

    if p.CustomName then
        return p.CustomName.Name
    end

    return Localization.Get(p.DisplayName.NameKey.Handle.Handle)
end

local buffering = {}
function Player.Notify(message, instant, ...)
    L.Info("Notify:", message, ...)
    Net.Send("PlayerNotify", { message, ... })

    if Config.TurnOffNotifications then
        return
    end

    local id = U.RandomId("Notify_")

    if instant then
        table.insert(buffering, 1, id)
    else
        table.insert(buffering, id)
    end
    local function remove()
        for i, v in ipairs(buffering) do
            if v == id then
                table.remove(buffering, i)
                break
            end
        end
    end

    RetryUntil(function()
        return buffering[1] == id
    end, { retries = 30, interval = 300 }):After(function()
        Net.Send("Notification", { Duration = 3, Text = message })
        Defer(1000, remove)
    end):Catch(remove)
end

---@param act string
---@return ChainableRunner|nil
local teleporting = nil
function Player.TeleportToAct(act)
    if teleporting then
        return
    end

    Osi.PROC_DEBUG_TeleportToAct(act)
    teleporting = true

    local didUnload = false
    local function checkUnload()
        if didUnload then
            GameState.OnLoad(function()
                teleporting = false
            end, true)
        else
            teleporting = false
        end
    end

    local handler = GameState.OnUnload(function()
        didUnload = true
        checkUnload()
    end, true)

    Defer(3000, function()
        handler:Unregister()

        if not didUnload then
            checkUnload()
        end
    end)

    return WaitUntil(function()
        return not teleporting
    end)
end

function Player.TeleportToRegion(region)
    for act, reg in pairs(C.Regions) do
        if reg == region then
            return Player.TeleportToAct(act)
        end
    end
end

function Player.TeleportToCamp()
    local activeCamp = GU.DB.TryGet("DB_ActiveCamp", 1, nil, 1)[1]
    if activeCamp == nil then
        L.Error("No active camp found.")
        return
    end

    local campEntry = GU.DB.TryGet("DB_Camp", 4, { activeCamp }, 3)[1]
    local campEntryFallback = GU.DB.TryGet("DB_Camp", 4, { activeCamp }, 2)[1]
    if not campEntry then
        L.Error("No camp trigger found.")
        return
    end

    for _, entity in pairs(GE.GetParty()) do
        L.Debug("TeleportToCamp", entity.Uuid.EntityUuid, campEntry, campEntryFallback)
        if not entity.CampPresence then
            if campEntry then
                Osi.TeleportTo(entity.Uuid.EntityUuid, campEntry, "", 1, 1, 1, 1, 1)
                Osi.PROC_Camp_TeleportToCamp(entity.Uuid.EntityUuid, campEntry)
            end
            if campEntryFallback then
                Osi.TeleportTo(entity.Uuid.EntityUuid, campEntryFallback, "", 1, 1, 1, 1, 1)
                Osi.PROC_Camp_TeleportToCamp(entity.Uuid.EntityUuid, campEntryFallback)
            end

            if Osi.IsDead(entity.Uuid.EntityUuid) == 1 then
                Osi.SetHitpoints(entity.Uuid.EntityUuid, 20)
                Osi.EndTurn(entity.Uuid.EntityUuid)
            end
        end
    end
end

function Player.ReturnToCamp()
    if Player.Region() == "END_Main" then
        -- act 1 seems to load fastest
        return Player.TeleportToAct("act1"):After(function()
            Player.TeleportToCamp()
            return true
        end)
    end

    Player.TeleportToCamp()

    return Schedule()
end

local readyChecks = {}
---@class ChainableConfirmation : LibsChainable
---@field After fun(func: fun(result: boolean): any): LibsChainable
---@param message string
---@return ChainableConfirmation
function Player.AskConfirmation(message, ...)
    message = __(message, ...)
    local msgId = U.RandomId("AskConfirmation_")
    Osi.ReadyCheckSpecific(msgId, message, 1, Player.Host(), "", "", "")

    local chainable = Libs.Chainable(message)
    readyChecks[msgId] = function(...)
        chainable:Begin(...)
    end

    return chainable
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Events                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

U.Osiris.On("ReadyCheckPassed", 1, "after", function(id)
    L.Debug("ReadyCheckPassed", id)
    if readyChecks[id] then
        local func = readyChecks[id]
        readyChecks[id] = nil
        func(true)
    end
end)

U.Osiris.On("ReadyCheckFailed", 1, "after", function(id)
    L.Debug("ReadyCheckFailed", id)
    if readyChecks[id] then
        local func = readyChecks[id]
        readyChecks[id] = nil
        func(false)
    end
end)
