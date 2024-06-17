local healthMap = {}
local damageMap = {}
local damageMax = {}
local cap = 10

local current = nil

local function modifyHealth(entity, health)
    -- funky stuff
    if entity.Health.Hp == 0 then
        return
    end

    if health.Hp then
        entity.Health.Hp = health.Hp
    end
    if health.MaxHp then
        entity.Health.MaxHp = health.MaxHp
    end

    if health.TemporaryHp then
        entity.Health.TemporaryHp = health.TemporaryHp
    end
    if health.MaxTemporaryHp then
        entity.Health.MaxTemporaryHp = health.MaxTemporaryHp
    end

    entity:Replicate("Health")
end

Ext.Entity.Subscribe("Health", function(entity)
    if not entity.IsCharacter or entity.PartyMember then
        return
    end

    local uuid = entity.Uuid.EntityUuid

    local health = healthMap[uuid]
    if health == nil then
        return
    end

    modifyHealth(entity, health)
end)

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

        local health = Ext.Json.Parse(Ext.DumpExport(entity.Health))
        healthMap[entity.Uuid.EntityUuid] = health
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

local function update()
    if not current then
        refresh(false)

        return
    end

    if not damageMap[current] then
        resetCap(current)
    end

    Osi.QuestMessageHide("DamageCap")
    Ext.Timer.WaitFor(1000, function()
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

    refresh(damageMap[current] == 0)
end

Ext.Osiris.RegisterListener("CombatRoundStarted", 2, "after", function(_, _)
    healthMap = {}
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

local timer
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

        local entity = Ext.Entity.Get(defender)

        local health = healthMap[entity.Uuid.EntityUuid]
        if health == nil then
            return
        end

        if not damageMap[attackerOwner] then
            resetCap(attackerOwner)
        end

        local leftFromCap = damageMap[attackerOwner]
        local allowedDamage = math.min(leftFromCap, damageAmount)
        local max = health.Hp + health.TemporaryHp

        damageMap[attackerOwner] = leftFromCap - math.min(allowedDamage, max)

        if health.TemporaryHp > 0 then
            if allowedDamage > health.TemporaryHp then
                health.TemporaryHp = 0
                allowedDamage = allowedDamage - health.TemporaryHp
            else
                health.TemporaryHp = math.max(0, health.TemporaryHp - allowedDamage)
                allowedDamage = 0
            end
        end

        if allowedDamage > 0 then
            health.Hp = math.max(0, health.Hp - allowedDamage)
        end

        _D({ damageMap[attackerOwner], allowedDamage, health.Hp, health.TemporaryHp })

        modifyHealth(entity, health)

        if timer then
            Ext.Timer.Cancel(timer)
        end
        timer = Ext.Timer.WaitFor(100, function()
            update()
            timer = nil
        end)
    end
)
