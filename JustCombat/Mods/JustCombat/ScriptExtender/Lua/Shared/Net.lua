---@type Constants
local Constants = Require("Shared/Constants")
---@type Utils
local Utils = Require("Shared/Utils")
---@type Libs
local Libs = Require("Shared/Libs")

---@class Net
local M = {}

---@class NetMessage: LibsObject
---@field Action string
---@field Payload table
---@field UserID string|nil
local NetMessage = Libs.Object({
    Action = nil,
    Payload = nil,
    UserID = nil,
})
function NetMessage:__tostring()
    return Ext.Json.Stringify(self)
end

local listeners = {}

---@class NetListener: LibsObject
---@field Action string
---@field Func fun(self: NetListener, message: NetMessage): void
---@field Once boolean
---@field Respond fun(self: NetListener, payload: any, userID: string|nil)
---@field Send fun(self: NetListener, payload: any, userID: string|nil)
---@field Unregister fun(self: NetListener)
---@field New fun(action: string, callback: fun(message: NetMessage): void, once: boolean): NetListener
local NetListener = Libs.Object({
    Id = nil,
    Action = nil,
    Func = nil,
    Once = false,
    Respond = function(self, payload, userID)
        M.Send(self.Action, payload, userID)
    end,
    Send = function(self, payload, userID)
        self.Once = true
        M.Send(self.Action, payload, userID)
    end,
    Unregister = function(self)
        listeners[self.Id] = nil
    end,
})

function NetListener.New(action, callback, once)
    local o = NetListener.Init({
        Action = action,
        Func = callback,
        Once = once and true or false,
    })
    o.Id = tostring(o)

    listeners[o.Id] = o

    return o
end

Ext.Events.NetMessage:Subscribe(function(msg)
    if Constants.NetChannel ~= msg.Channel then
        return
    end

    local message = Ext.Json.Parse(msg.Payload)

    -- TODO Validate message
    local m = NetMessage.Init({
        Action = message.Action,
        Payload = message.Payload,
        UserID = msg.UserID,
    })

    for _, listener in pairs(listeners) do
        if listener.Action == m.Action then
            xpcall(function()
                listener:Func(m)
            end, function(err)
                Utils.Log.Error("NetListener error", err)
            end)

            if listener.Once then
                listener:Unregister()
            end
        end
    end
end)

---@param action string
---@param payload any
---@param userID string|nil
function M.Send(action, payload, userID)
    local message = NetMessage.Init({
        Action = action,
        Payload = payload,
        UserID = userID,
    })

    if Ext.IsServer() then
        if message.UserID == nil then
            Ext.Net.BroadcastMessage(Constants.NetChannel, tostring(message))
        else
            Ext.Net.PostMessageToUser(message.UserID, Constants.NetChannel, tostring(message))
        end
        return
    end

    Ext.Net.PostMessageToServer(Constants.NetChannel, tostring(message))
end

---@param action string
---@param callback fun(self: NetListener, message: NetMessage): void
---@param once boolean|nil
---@return NetListener
function M.On(action, callback, once)
    return NetListener.New(action, callback, once)
end

return M
