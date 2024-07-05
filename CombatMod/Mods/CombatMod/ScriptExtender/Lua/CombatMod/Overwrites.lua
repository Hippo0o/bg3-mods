local maxValueDefault = Ext.Stats.GetStatsManager().ExtraData.AbilityMaxValue

GameState.OnLoad(function()
    -- mod default values
    if maxValueDefault < 60 then
        Ext.Stats.GetStatsManager().ExtraData.AbilityMaxValue = 60
    end

    -- Mindflayer form can't level up
    Ext.StaticData.Get("e6e0499b-c7b7-4f4a-b286-ecede5225ca1", "ShapeshiftRule").BlockLevelUp = false

    -- Emperor unlock should not be able to equip weapons
    Ext.Template.GetTemplate("6efb2704-a025-49e0-ba9f-2b4f62dd2195").DisableEquipping = true
end)
GameState.OnUnload(function()
    Ext.Stats.GetStatsManager().ExtraData.AbilityMaxValue = maxValueDefault
    Ext.StaticData.Get("e6e0499b-c7b7-4f4a-b286-ecede5225ca1", "ShapeshiftRule").BlockLevelUp = true
    Ext.Template.GetTemplate("6efb2704-a025-49e0-ba9f-2b4f62dd2195").DisableEquipping = false
end)
