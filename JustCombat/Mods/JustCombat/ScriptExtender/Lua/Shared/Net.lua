---@type Constants
local Constants = Require("Shared/Constants")
---@type Utils
local Utils = Require("Shared/Utils")
---@type Libs
local Libs = Require("Shared/Libs")

---@class Net
local M = {}

---@class NetEvent: LibsObject
---@field Action string
---@field Payload table
---@field UserId string|nil
---@field ResponseAction string|nil
local NetEvent = Libs.Object({
    Action = nil,
    Payload = nil,
    UserId = nil,
    ResponseAction = nil,
})

function NetEvent:__tostring()
    return Ext.Json.Stringify(self)
end

local listeners = {}

---@class NetListener: LibsObject
---@field Action string
---@field Func fun(self: NetListener, event: NetEvent): void
---@field Once boolean
---@field Unregister fun(self: NetListener)
---@field New fun(action: string, callback: fun(self: NetListene, event: NetEvent): void, once: boolean): NetListener
local NetListener = Libs.Object({
    Id = nil,
    Action = nil,
    Func = nil,
    Once = false,
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

Ext.Events.NetEvent:Subscribe(function(msg)
    if Constants.NetChannel ~= msg.Channel then
        return
    end

    local event = Ext.Json.Parse(msg.Payload)

    -- TODO Validate event
    local m = NetEvent.Init({
        Action = event.Action,
        Payload = event.Payload,
        UserId = msg.UserID,
        ResponseAction = event.ResponseAction,
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
---@param userId string|nil
---@param responseAction string|nil
function M.Send(action, payload, userId, responseAction)
    local event = NetEvent.Init({
        Action = action,
        Payload = payload,
        UserId = userId,
        ResponseAction = responseAction or action,
    })

    if Ext.IsServer() then
        if event.UserId == nil then
            Ext.Net.BroadcastMessage(Constants.NetChannel, tostring(event))
        else
            Ext.Net.PostMessageToUser(event.UserId, Constants.NetChannel, tostring(event))
        end
        return
    end

    Ext.Net.PostMessageToServer(Constants.NetChannel, tostring(event))
end

---@param action string
---@param callback fun(self: NetListener, event: NetEvent): void
---@param once boolean|nil
---@return NetListener
function M.On(action, callback, once)
    return NetListener.New(action, callback, once)
end

---@param action string
---@param callback fun(self: NetListener, event: NetEvent): void
---@param params table
function M.Request(action, callback, params)
    local responseAction = action .. tostring(callback):gsub("function: ", "")
    local listener = M.On(responseAction, callback, true)

    M.Send(action, params, nil, responseAction)
end

---@param event NetEvent
---@param payload any
function M.Respond(event, payload)
    M.Send(event.ResponseAction, payload, event.UserId)
end

return M
