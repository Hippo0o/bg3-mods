---@class Mod
local M = {}

M.ModUUID = ModuleUUID
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
