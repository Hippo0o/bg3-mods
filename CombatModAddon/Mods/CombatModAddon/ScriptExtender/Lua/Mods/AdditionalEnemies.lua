ModUUID = "49a94025-c3e4-461f-bc08-2de6a629666c"

function TestA()
    local enemies = {}
    for _, templateData in pairs(Ext.Template.GetAllRootTemplates()) do
        if not templateData.FileName:match("AdditionalEnemies") then
            goto continue
        end
        if templateData.TemplateType ~= "character" then
            goto continue
        end

        local data = {
            Name = templateData.Name,
            TemplateId = templateData.Id,
            CharacterVisualResourceID = templateData.CharacterVisualResourceID,
            Icon = templateData.Icon,
            Stats = templateData.Stats,
            Equipment = templateData.Equipment,
            Archetype = templateData.CombatComponent.Archetype,
            AiHint = templateData.CombatComponent.AiHint,
            IsBoss = templateData.CombatComponent.IsBoss,
            SpellSet = templateData.SpellSet,
            LevelOverride = templateData.LevelOverride,
        }
        table.insert(enemies, Enemy.Restore(data))

        ::continue::
    end

    Enemy.TestEnemies(enemies, true)
end
