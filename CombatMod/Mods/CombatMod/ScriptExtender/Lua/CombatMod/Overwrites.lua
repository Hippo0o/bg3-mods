local maxValueDefault = Ext.Stats.GetStatsManager().ExtraData.AbilityMaxValue
local isDirty = false

local function modify()
    L.Debug("Applying overwrites...")

    -- mod default values
    if maxValueDefault < 60 then
        Ext.Stats.GetStatsManager().ExtraData.AbilityMaxValue = 60
    end

    -- Mindflayer form can't level up
    Ext.StaticData.Get("e6e0499b-c7b7-4f4a-b286-ecede5225ca1", "ShapeshiftRule").BlockLevelUp = false

    -- Emperor unlock should not be able to equip weapons
    Ext.Template.GetTemplate("6efb2704-a025-49e0-ba9f-2b4f62dd2195").DisableEquipping = true

    isDirty = true
end
local function restore()
    if not isDirty then
        return
    end

    L.Debug("Restoring overwrites...")

    Ext.Stats.GetStatsManager().ExtraData.AbilityMaxValue = maxValueDefault
    Ext.StaticData.Get("e6e0499b-c7b7-4f4a-b286-ecede5225ca1", "ShapeshiftRule").BlockLevelUp = true
    Ext.Template.GetTemplate("6efb2704-a025-49e0-ba9f-2b4f62dd2195").DisableEquipping = false

    isDirty = false
end

GameState.OnUnload(restore)

-- triggered on load and on mod activation
GameState.OnLoad(function()
    if IsActive() then
        modify()
    else
        restore()
    end
end)
GameState.OnLoadSession(function()
    modify()
end)

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                    Template overwriting                                     --
--                                                                                             --
-------------------------------------------------------------------------------------------------

local templateIdsOverwritten = {}
Event.On("TemplateOverwrite", function(templateId, prop, value)
    templateIdsOverwritten[templateId] = templateIdsOverwritten[templateId] or {}
    local template = Ext.Template.GetTemplate(templateId)

    UT.Patch(template, { [prop] = value }, templateIdsOverwritten[templateId])

    if Ext.IsServer() then
        Net.Send("TemplateOverwrite", { templateId, prop, value })
    end
end)

if Ext.IsClient() then
    Net.On("TemplateOverwrite", function(event)
        Event.Trigger("TemplateOverwrite", table.unpack(event.Payload))
    end)
end

GameState.OnUnload(function()
    for templateId, overwrites in pairs(templateIdsOverwritten) do
        L.Debug("Restoring template:", templateId)

        local template = Ext.Template.GetTemplate(templateId)

        UT.Patch(template, overwrites)
        templateIdsOverwritten[templateId] = nil
    end
end)
