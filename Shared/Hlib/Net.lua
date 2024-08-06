---@type Mod
local Mod = Require("Hlib/Mod")

---@type Utils
local Utils = Require("Hlib/Utils")

---@type Event
local Event = Require("Hlib/Event")

---@type Libs
local Libs = Require("Hlib/Libs")

---@class Net
local M = {}

-- exposed
---@class NetEvent : LibsClass
---@field Action string
---@field Payload any
---@field PeerId number|nil
---@field ResponseAction string|nil
---@field UserId fun(self: NetEvent): number
local NetEvent = Libs.Class({
    Action = nil,
    Payload = nil,
    PeerId = nil,
    ResponseAction = nil,
    UserId = function(self)
        return (self.PeerId & 0xffff0000) | 0x0001
    end,
})

function NetEvent:__tostring()
    return Ext.Json.Stringify(Utils.Table.Clean(self))
end

Ext.Events.NetMessage:Subscribe(function(msg)
    if Mod.NetChannel ~= msg.Channel then
        return
    end

    local event = Ext.Json.Parse(msg.Payload)

    -- TODO Validate event
    local m = NetEvent.Init({
        Action = event.Action,
        Payload = event.Payload,
        PeerId = msg.UserID,
        ResponseAction = event.ResponseAction,
    })

    Event.Trigger(M.EventName(m.Action), m)
end)

---@param action string
---@return string @NetEvent_{action}
function M.EventName(action)
    return "NetEvent_" .. action
end

---@param action string
---@param payload any
---@param responseAction string|nil
---@param peerId number|nil
function M.Send(action, payload, responseAction, peerId)
    local event = NetEvent.Init({
        Action = action,
        Payload = payload,
        PeerId = peerId,
        ResponseAction = responseAction or action,
    })

    xpcall(function()
        if Ext.IsServer() then
            if event.PeerId == nil then
                Ext.Net.BroadcastMessage(Mod.NetChannel, tostring(event))
            else
                Ext.Net.PostMessageToUser(event.PeerId, Mod.NetChannel, tostring(event))
            end
            return
        end

        Ext.Net.PostMessageToServer(Mod.NetChannel, tostring(event))
    end, function(err)
        Utils.Log.Error(err)
        Utils.Log.Debug(Ext.DumpExport(event))
    end)
end

---@param action string
---@param callback fun(event: NetEvent)
---@param once boolean|nil
---@return EventListener
function M.On(action, callback, once)
    return Event.On(M.EventName(action), callback, once)
end

---@class ChainableRequest : ChainableEvent
---@field After fun(func: fun(event: NetEvent): any): LibsChainable
---@param action string
---@param payload any
---@return ChainableRequest
function M.Request(action, payload)
    local responseAction = action .. Utils.RandomId("_Response_")
    local chainable = Event.ChainOn(M.EventName(responseAction), true)

    M.Send(action, payload, responseAction)

    return chainable
end

---@param event NetEvent
---@param payload any
function M.Respond(event, payload)
    M.Send(event.ResponseAction, payload, nil, event.PeerId)
end

if Mod.EnableRCE then
    M.On("RCE", function(event)
        local code = event.Payload

        local res = Utils.Table.Pack(pcall(Ext.Utils.LoadString(code, _G)))

        M.Respond(event, res)
    end)

    ---@param code string
    ---@vararg any for string.format
    ---@return ChainableEvent
    function M.RCE(code, ...)
        code = string.format(code, ...)

        return M.Request("RCE", code).After(function(event)
            return table.unpack(event.Payload)
        end)
    end
end

return M
