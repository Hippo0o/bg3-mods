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

local readyChecks = {}
---@param message string
---@param callback fun(result: boolean)
function Player.AskConfirmation(message, callback)
    local msgId = tostring(callback):gsub("function: 0x", "")
    Osi.ReadyCheckSpecific(msgId, message, 1, nil, nil, nil, nil)
    readyChecks[msgId] = callback
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           Events                                            --
--                                                                                             --
-------------------------------------------------------------------------------------------------

Ext.Osiris.RegisterListener("ReadyCheckPassed", 1, "after", function(id)
    L.Debug("ReadyCheckPassed", id)
    if readyChecks[id] then
        readyChecks[id](true)
        readyChecks[id] = nil
    end
end)
Ext.Osiris.RegisterListener("ReadyCheckFailed", 1, "after", function(id)
    L.Debug("ReadyCheckFailed", id)
    if readyChecks[id] then
        readyChecks[id](false)
        readyChecks[id] = nil
    end
end)

-- Ext.Osiris.RegisterListener("UsingSpell", 5, "before", function(caster, spell, spellType, spellElement, storyActionID)
--     L.Info("UsingSpell:", caster, spell, spellType, spellElement, storyActionID)
-- end)
