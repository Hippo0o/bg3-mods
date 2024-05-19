---@class Mod
local M = {}

M.UUID = ModuleUUID
M.Prefix = ""
M.TableKey = ""
M.Version = { major = 0, minor = 0, revision = 0 }
M.Debug = true
M.Dev = false
M.EnableRCE = false
M.NetChannel = "Net_" .. M.UUID

M.PersistentVarsTemplate = {}
M.Vars = {}

if Ext.Mod.IsModLoaded(M.UUID) then
    local ModInfo = Ext.Mod.GetMod(M.UUID)["Info"]

    M.TableKey = ModInfo.Directory
    M.Prefix = ModInfo.Name
    M.Version = { major = ModInfo.ModVersion[1], minor = ModInfo.ModVersion[2], revision = ModInfo.ModVersion[3] }
end

local function applyTemplate(vars, template)
    for k, v in pairs(template) do
        if type(v) == "table" then
            if vars[k] == nil then
                vars[k] = {}
            end

            applyTemplate(vars[k], v)
        else
            if vars[k] == nil then
                vars[k] = v
            end
        end
    end
end

function M.PreparePersistentVars()
    if not PersistentVars then
        PersistentVars = {}
    end

    -- Remove keys we no longer use in the Template
    for k, _ in ipairs(PersistentVars) do
        if M.PersistentVarsTemplate[k] == nil then
            PersistentVars[k] = nil
        end
    end

    -- Add new keys to the PersistentVars recursively
    applyTemplate(PersistentVars, M.PersistentVarsTemplate)
end

-- TODO sync broken
function M.PrepareModVars(tableKey, sync, template)
    Ext.Vars.RegisterModVariable(M.UUID, tableKey, {
        Persistent = true,
        SyncOnWrite = false,
        SyncOnTick = true,
        Server = Ext.IsServer() or sync,
        Client = Ext.IsClient() or sync,
        WriteableOnServer = Ext.IsServer() or sync,
        WriteableOnClient = Ext.IsClient() and not sync,
        SyncToClient = sync or false,
        SyncToServer = false,
    })

    Ext.Events.SessionLoaded:Subscribe(function()
        M.Vars = Ext.Vars.GetModVariables(M.UUID)
        if Ext.IsClient() and sync then
            return
        end
        Ext.OnNextTick(function()
            if type(template) == "table" then
                M.Vars[tableKey] = M.Vars[tableKey] or {}
                applyTemplate(M.Vars[tableKey], template)
            else
                M.Vars[tableKey] = M.Vars[tableKey] or template
            end
        end)
    end)
end

return M
