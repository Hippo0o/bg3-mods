local damageMap = {}
local damageMax = {}
local cap = 10

local current = nil

local function applyBlock(entity, block)
    entity.Health.field_20 = block and 1 or 0
    entity:Replicate("Health")
end

local function refresh(block)
    local function iter(entity)
        if entity.PartyMember then
            return
        end

        if not entity.IsCharacter then
            return
        end

        if not entity.Health then
            return
        end

        if not entity.Uuid then
            return
        end

        if not entity.CombatParticipant then
            return
        end
        if not entity.CombatParticipant.CombatHandle then
            return
        end

        applyBlock(entity, block)
    end

    for _, entity in ipairs(Ext.Entity.GetAllEntitiesWithComponent("IsInTurnBasedMode")) do
        iter(entity)
    end
end

local function resetCap(character)
    damageMap[character] = Osi.GetLevel(character) * cap
    damageMax[character] = Osi.GetLevel(character) * cap
    -- Osi.ShowNotification(character, tostring(damageMap[attackerOwner]))
end

local timer
local function update()
    if not current then
        refresh(false)

        return
    end

    if not damageMap[current] then
        resetCap(current)
    end

    refresh(damageMap[current] == 0)

    if timer then
        Ext.Timer.Cancel(timer)
    end
    timer = Ext.Timer.WaitFor(100, function()
        Osi.QuestMessageHide("DamageCap")
        Ext.Timer.WaitFor(300, function()
            local status = { "Damage Cap: \n" }
            for character, _ in pairs(damageMax) do
                if damageMap[character] then
                    table.insert(
                        status,
                        string.format(
                            "%s: %d/%d \n",
                            Osi.ResolveTranslatedString(Osi.GetDisplayName(character)),
                            tonumber(damageMap[character]) or 0,
                            tonumber(damageMax[character]) or 0
                        )
                    )
                end
            end
            Osi.QuestMessageShow("DamageCap", table.concat(status))
        end)

        timer = nil
    end)

end

Ext.Osiris.RegisterListener("CombatRoundStarted", 2, "after", function(_, _)
    damageMap = {}

    update()
end)

Ext.Osiris.RegisterListener("TurnStarted", 1, "after", function(character)
    _D({ "TurnStarted", character })
    if Osi.IsPlayer(character) == 1 then
        current = character
    else
        current = nil
    end

    update()
end)

Ext.Osiris.RegisterListener("GainedControl", 1, "after", function(character)
    Osi.QuestMessageHide("DamageCap")

    _D({ "GainedControl", character })
    if Osi.IsPlayer(character) ~= 1 then
        return
    end

    current = character

    update()
end)

Ext.Osiris.RegisterListener("EnteredCombat", 2, "after", function(character, _)
    if Osi.IsPlayer(character) ~= 1 then
        return
    end

    update()
end)

Ext.Osiris.RegisterListener("StartAttack", 4, "before", function(defender, attackOwner, attacker, storyActionID)
    if Osi.IsPlayer(attackOwner) ~= 1 then
        return
    end

    current = attackOwner
end)

Ext.Osiris.RegisterListener(
    "AttackedBy",
    7,
    "before",
    function(defender, attackerOwner, attacker2, damageType, damageAmount, damageCause, storyActionID)
        _D({ defender, attackerOwner, attacker2, damageType, damageAmount, damageCause, storyActionID })

        if Osi.IsPlayer(attackerOwner) ~= 1 then
            return
        end

        if damageAmount == 0 then
            return
        end

        if not damageMap[attackerOwner] then
            resetCap(attackerOwner)
        end

        local leftFromCap = damageMap[attackerOwner]
        local allowedDamage = math.min(leftFromCap, damageAmount)
        damageMap[attackerOwner] = leftFromCap - allowedDamage

        update()
    end
)
