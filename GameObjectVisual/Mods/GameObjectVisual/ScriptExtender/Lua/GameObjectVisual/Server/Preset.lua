Preset = {}

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                          Structures                                         --
--                                                                                             --
-------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------
--                                                                                             --
--                                            Public                                           --
--                                                                                             --
-------------------------------------------------------------------------------------------------

function Preset.GetForRace(subRace)
    return UT.Map(Ext.StaticData.GetAll("CharacterCreationPreset"), function(preset)
        local c = Ext.StaticData.Get(preset, "CharacterCreationPreset")

        if c.SubRaceUUID == subRace then
            return c
        end
    end)
end
