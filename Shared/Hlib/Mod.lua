---@class Mod
local M = {}

M.ModUUID = ModuleUUID
M.ModPrefix = ""
M.ModTableKey = ""
M.ModVersion = { major = 0, minor = 0, revision = 0 }
M.Debug = true
M.EnableRCE = false
M.NetChannel = "Net_" .. M.ModUUID

M.PersistentVarsTemplate = {}

if Ext.Mod.IsModLoaded(M.ModUUID) then
    local ModInfo = Ext.Mod.GetMod(M.ModUUID)["Info"]

    M.ModTableKey = ModInfo.Name
    M.ModPrefix = ModInfo.Name
    M.ModVersion = { major = ModInfo.ModVersion[1], minor = ModInfo.ModVersion[2], revision = ModInfo.ModVersion[3] }
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

    applyTemplate(PersistentVars, M.PersistentVarsTemplate)
end

return M
