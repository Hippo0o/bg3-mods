local maxValueDefault = Ext.Stats.GetStatsManager().ExtraData.AbilityMaxValue

-- mod default values
if maxValueDefault < 60 then
    Ext.Stats.GetStatsManager().ExtraData.AbilityMaxValue = 60
end

GameState.OnUnloadSession(function()
    Ext.Stats.GetStatsManager().ExtraData.AbilityMaxValue = maxValueDefault
end)
