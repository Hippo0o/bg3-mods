---@class Mod
local M = {}

M.ModUUID = ""
M.ModPrefix = ""
M.ModTableKey = ""
M.ModVersion = { major = 0, minor = 0, revision = 0 }
M.Debug = true

M.PersistentVarsTemplate = {}

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

    -- Add new keys to the PersistentVars
    for k, v in pairs(M.PersistentVarsTemplate) do
        if PersistentVars[k] == nil then
            PersistentVars[k] = v
        end
    end
end

return M
