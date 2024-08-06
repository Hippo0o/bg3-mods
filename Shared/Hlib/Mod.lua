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

if Ext.Mod.IsModLoaded(M.UUID) then
    local modInfo = Ext.Mod.GetMod(M.UUID)["Info"]

    M.TableKey = modInfo.Directory
    M.Prefix = modInfo.Name
    M.Version = { major = modInfo.ModVersion[1], minor = modInfo.ModVersion[2], revision = modInfo.ModVersion[3] }
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

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                       PersistentVars                                        --
--                                                                                             --
-------------------------------------------------------------------------------------------------

M.PersistentVarsTemplate = {}

function M.PreparePersistentVars()
    if not PersistentVars then
        PersistentVars = {}
    end

    -- Remove keys we no longer use in the Template
    for k, _ in pairs(PersistentVars) do
        if M.PersistentVarsTemplate[k] == nil then
            PersistentVars[k] = nil
        end
    end

    -- Add new keys to the PersistentVars recursively
    applyTemplate(PersistentVars, M.PersistentVarsTemplate)
end

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                           ModVars                                           --
--                                                                                             --
-------------------------------------------------------------------------------------------------

M.Vars = {}

---@param tableKey string
---@param sync boolean
---@param template table
function M.CreateModVar(tableKey, sync, template)
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
        local vars = Ext.Vars.GetModVariables(M.UUID)

        if Ext.IsClient() and sync then
            M.Vars = vars
            return
        end

        vars[tableKey] = vars[tableKey] or {}

        Ext.OnNextTick(function()
            if type(template) == "table" then
                M.Vars[tableKey] = M.Vars[tableKey] or {}
                applyTemplate(M.Vars[tableKey], template)
            else
                M.Vars[tableKey] = M.Vars[tableKey] or template
            end

            if sync then
                M.Vars[tableKey] = Require("Hlib/Libs").Proxy(M.Vars[tableKey], function(actual, key, value)
                    vars[tableKey] = actual

                    return value
                end)
            end
        end)
    end)
end

function M.SyncModVars()
    for k, v in pairs(M.Vars) do
        M.Vars[k] = v
    end
    Ext.Vars.SyncModVariables(M.UUID)
end

return M
