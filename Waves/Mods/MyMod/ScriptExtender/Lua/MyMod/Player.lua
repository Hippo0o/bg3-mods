---@diagnostic disable: undefined-global

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                            Public                                           --
--                                                                                             --
-------------------------------------------------------------------------------------------------

---@return string GUID of the host character
function Player.Host()
    return Osi.GetHostCharacter()
end

---@return number x, number y, number z
function Player.Pos()
    return Osi.GetPosition(Player.Host())
end

---@return string GUID
function Player.InCombat()
    return UT.Find(UE.GetPlayers(), function(guid)
        return Osi.IsInCombat(guid) == 1
    end)
end

local buffering = false
function Player.Notify(message, instant)
    L.Info("Notify:", message)

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
        end, true)
    end)
end
