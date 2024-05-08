---@diagnostic disable: undefined-global

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                            Public                                           --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@param userId number
---@return string GUID of the host character
function Player.Host(userId)
    userId = userId or (S and S.UserId or nil)

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

    WaitFor(function()
        return not buffering or instant
    end, function()
        Osi.ShowNotification(Player.Host(), message)
        if instant then
            return
        end
        buffering = true
        Defer(1000, function()
            buffering = false
        end)
    end)
end

local teleporting = nil
function Player.TeleportToAct(act)
    if teleporting then
        return false
    end

    if teleporting == false then
        teleporting = nil
        return true
    end

    Osi.PROC_DEBUG_TeleportToAct(act)
    teleporting = true

    local didUnload = false
    local handler = GameState.OnUnloading(function()
        didUnload = true
    end, true)

    Defer(3000, function()
        handler:Unregister()

        if didUnload then
            GameState.OnLoading(function()
                teleporting = false
            end, false)
        else
            teleporting = false
        end
    end)

    return false
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
    local msgId = tostring(callback):gsub("function: ", "jc_")
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
