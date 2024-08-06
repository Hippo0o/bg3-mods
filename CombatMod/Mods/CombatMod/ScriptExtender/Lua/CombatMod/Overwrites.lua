local maxValueDefault = Ext.Stats.GetStatsManager().ExtraData.AbilityMaxValue
local isDirty = false

local function modify()
    if isDirty then
        return
    end

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

GameState.OnUnloadSession(restore)

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

    Net.Send("RequestTemplateOverwrites") -- if the client is joined after the server
end

if Ext.IsServer() then
    local allOverwrites = {}

    Event.On("TemplateOverwrite", function(templateId, prop, value)
        allOverwrites[templateId] = allOverwrites[templateId] or {}
        allOverwrites[templateId][prop] = value
    end)

    Net.On("RequestTemplateOverwrites", function(event)
        for templateId, overwrites in pairs(allOverwrites) do
            for prop, value in pairs(overwrites) do
                Net.Respond("TemplateOverwrite", { templateId, prop, value })
            end
        end
    end)
end

GameState.OnUnloadSession(function()
    for templateId, overwrites in pairs(templateIdsOverwritten) do
        L.Debug("Restoring template:", templateId)

        local template = Ext.Template.GetTemplate(templateId)

        UT.Patch(template, overwrites)
        templateIdsOverwritten[templateId] = nil
    end
end)
