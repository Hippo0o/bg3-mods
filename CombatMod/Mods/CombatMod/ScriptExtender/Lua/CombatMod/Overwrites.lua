local maxValueDefault = Ext.Stats.GetStatsManager().ExtraData.AbilityMaxValue

GameState.OnLoad(function()
    -- mod default values
    if maxValueDefault < 60 then
        Ext.Stats.GetStatsManager().ExtraData.AbilityMaxValue = 60
    end

    -- Mindflayer form can't level up
    Ext.StaticData.Get("e6e0499b-c7b7-4f4a-b286-ecede5225ca1", "ShapeshiftRule").BlockLevelUp = false
end)
GameState.OnUnload(function()
    Ext.Stats.GetStatsManager().ExtraData.AbilityMaxValue = maxValueDefault
    Ext.StaticData.Get("e6e0499b-c7b7-4f4a-b286-ecede5225ca1", "ShapeshiftRule").BlockLevelUp = true
end)
