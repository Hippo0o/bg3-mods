local isDirty = false

local function modify()
    if isDirty then
        return
    end

    L.Debug("Overwrites modify")

    -- Mindflayer form can't level up
    Ext.StaticData.Get("e6e0499b-c7b7-4f4a-b286-ecede5225ca1", "ShapeshiftRule").BlockLevelUp = false
    -- Ext.StaticData.Get("e6e0499b-c7b7-4f4a-b286-ecede5225ca1", "ShapeshiftRule").ApplyVisual = false
    -- Ext.StaticData.Get("e6e0499b-c7b7-4f4a-b286-ecede5225ca1", "ShapeshiftRule").ChangeIcon = false

    isDirty = true
end
local function restore()
    if not isDirty then
        return
    end

    L.Debug("Overwrites restore")

    Ext.StaticData.Get("e6e0499b-c7b7-4f4a-b286-ecede5225ca1", "ShapeshiftRule").BlockLevelUp = true

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
    L.Dump(templateId, templateIdsOverwritten[templateId][prop])

    if Ext.IsServer() then
        Net.Send("TemplateOverwrite", { templateId, prop, value })
    end
end)

if Ext.IsClient() then
    Net.On("TemplateOverwrite", function(event)
        Event.Trigger("TemplateOverwrite", table.unpack(event.Payload))
    end)

    GameState.OnLoad(function()
        Net.Send("RequestTemplateOverwrites") -- if the client joined after the server
    end)
end

if Ext.IsServer() then
    local allOverwrites = {}

    Event.On("TemplateOverwrite", function(templateId, prop, value)
        allOverwrites[templateId] = allOverwrites[templateId] or {}
        allOverwrites[templateId][prop] = value
    end)

    Net.On("RequestTemplateOverwrites", function(event)
        event.ResponseAction = "TemplateOverwrite"

        for templateId, overwrites in pairs(allOverwrites) do
            for prop, value in pairs(overwrites) do
                Net.Respond(event, { templateId, prop, value })
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
