---@type Constants
local Constants = Require("Shared/Constants")
---@type Utils
local Utils = Require("Shared/Utils")
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
        return Utils.PeerToUserId(self.PeerId)
    end,
})

function NetEvent:__tostring()
    return Ext.Json.Stringify(Utils.Table.Filter(self, function(v)
        return type(v) ~= "function"
    end, true))
end

local listeners = {}

---@class NetListener : LibsObject
---@field Action string
---@field Once boolean
---@field Func fun(event: NetEvent): void
---@field Exec fun(self: NetListener, event: NetEvent)
---@field Unregister fun(self: NetListener)
---@field New fun(action: string, callback: fun(event: NetEvent): void, once: boolean): NetListener
local NetListener = Libs.Object({
    Id = nil,
    Action = nil,
    Once = false,
    Func = function() end,
    Exec = function(self, event)
        xpcall(function()
            self.Func(event)
        end, function(err)
            Utils.Log.Error(err)
        end)

        if self.Once then
            self:Unregister()
        end
    end,
    Unregister = function(self)
        for i, l in pairs(listeners) do
            if l.Id == self.Id then
                table.remove(listeners, i)
            end
        end
    end,
})

function NetListener.New(action, callback, once)
    local o = NetListener.Init({
        Action = action,
        Func = callback,
        Once = once and true or false,
    })

    o.Id = tostring(o)

    table.insert(listeners, o)

    return o
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

    for _, listener in ipairs(listeners) do
        if listener.Action == m.Action then
            listener:Exec(m)
        end
    end
end)

---@param action string
---@param payload any
---@param peerId number|nil
---@param responseAction string|nil
function M.Send(action, payload, peerId, responseAction)
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
---@param callback fun(event: NetEvent): void
---@param once boolean|nil
---@return NetListener
function M.On(action, callback, once)
    return NetListener.New(action, callback, once)
end

---@param action string
---@param callback fun(responseEvent: NetEvent): void
---@param payload any
function M.Request(action, callback, payload)
    local responseAction = action .. tostring(callback):gsub("function: ", "")
    local listener = M.On(responseAction, callback, true)

    M.Send(action, payload, nil, responseAction)
end

---@param event NetEvent
---@param payload any
function M.Respond(event, payload)
    M.Send(event.ResponseAction, payload, event.PeerId)
end

return M
