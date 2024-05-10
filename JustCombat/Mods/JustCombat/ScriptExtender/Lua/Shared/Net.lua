---@type Constants
local Constants = Require("Shared/Constants")

---@type Utils
local Utils = Require("Shared/Utils")

---@type Event
local Event = Require("Shared/Event")

---@type Libs
local Libs = Require("Shared/Libs")

---@class Net
local M = {}

---@class NetEvent : LibsObject
---@field Action string
---@field Payload any
---@field PeerId number|nil
---@field ResponseAction string|nil
---@field UserId fun(self: NetEvent): number
local NetEvent = Libs.Object({
    Action = nil,
    Payload = nil,
    PeerId = nil,
    ResponseAction = nil,
    UserId = function(self)
        return (self.PeerId & 0xffff0000) | 0x0001
    end,
})

function NetEvent:__tostring()
    return Ext.Json.Stringify(Utils.Table.Filter(self, function(v)
        return type(v) ~= "function"
    end, true))
end

Ext.Events.NetMessage:Subscribe(function(msg)
    if Constants.NetChannel ~= msg.Channel then
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

    if Ext.IsServer() then
        if event.PeerId == nil then
            Ext.Net.BroadcastMessage(Constants.NetChannel, tostring(event))
        else
            Ext.Net.PostMessageToUser(event.PeerId, Constants.NetChannel, tostring(event))
        end
        return
    end

    Ext.Net.PostMessageToServer(Constants.NetChannel, tostring(event))
end

---@param action string
---@param callback fun(event: NetEvent)
---@param once boolean|nil
---@return EventListener
function M.On(action, callback, once)
    return Event.On(M.EventName(action), callback, once)
end

---@param action string
---@param callback fun(responseEvent: NetEvent)
---@param payload any
function M.Request(action, callback, payload)
    local responseAction = action .. Utils.RandomId("_Response_")
    local listener = M.On(responseAction, callback, true)

    M.Send(action, payload, responseAction)
end

---@param event NetEvent
---@param payload any
function M.Respond(event, payload)
    M.Send(event.ResponseAction, payload, nil, event.PeerId)
end

return M
