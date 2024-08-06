-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                            Public                                           --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@param userId number
---@return string GUID of the host character
function Player.Host(userId)
    if userId then
        local player = UT.Find(UE.GetPlayers(), function(guid)
            if Ext.Entity.Get(guid).ServerCharacter.UserID == userId then
                return guid
            end
        end)

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

---@return string|nil GUID
function Player.InCombat()
    return UT.Find(UE.GetPlayers(), function(guid)
        return Osi.IsInCombat(guid) == 1
    end)
end

local buffering = false
function Player.Notify(message, instant, ...)
    L.Info("Notify:", message, ...)
    Net.Send("PlayerNotify", { message, ... })

    -- new
    WaitFor(function()
        return not buffering or instant
    end).After(function()
        Osi.ShowNotification(Player.Host(), message)
        if instant then
            return
        end

        buffering = true
        return Defer(1000)
    end).After(function()
        buffering = false
    end)
end

local teleporting = nil
---@param act string
---@return number 0: Started, 1: Teleporting, 2: Teleported
function Player.TeleportToAct(act)
    if teleporting then
        return 1
    end

    if teleporting == false then
        teleporting = nil
        return 2
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

    return 0
end

function Player.TeleportToRegion(region)
    for act, reg in pairs(C.Regions) do
        if reg == region then
            return Player.TeleportToAct(act)
        end
    end
end

local readyChecks = {}
---@param message string
---@param callback fun(result: boolean)
function Player.AskConfirmation(message, callback)
    local msgId = U.RandomId("AskConfirmation_")
    Osi.ReadyCheckSpecific(msgId, message, 1, Player.Host(), "", "", "")
    readyChecks[msgId] = callback
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
