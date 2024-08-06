local damageMap = {}
local damageMax = {}
local entityMap = {}
local cap = 10

local function getUuid(str)
    local x = "%x"
    local t = { x:rep(8), x:rep(4), x:rep(4), x:rep(4), x:rep(12) }
    local pattern = table.concat(t, "%-")

    return str:match(pattern)
end

local function applyBlock(entity, block)
    if not entity then
        return
    end

    entity.Health.field_20 = block and 1 or 0
    entity:Replicate("Health")
end

local function refresh()
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

        local uuid = entity.Uuid.EntityUuid
        if not entityMap[uuid] or not entityMap[uuid]:IsAlive() then
            entityMap[uuid] = entity
        end
        applyBlock(entity, false)
    end

    for _, entity in ipairs(Ext.Entity.GetAllEntitiesWithComponent("IsInTurnBasedMode")) do
        iter(entity)
    end
end

local function resetCap(character)
    damageMap[character] = 10 -- Osi.GetLevel(character) * cap
    damageMax[character] = 10 -- Osi.GetLevel(character) * cap
    -- Osi.ShowNotification(character, tostring(damageMap[attackerOwner]))
end

local displayTimer
local function update(clear)
    if clear then
        entityMap = {}
    end

    refresh()

    if displayTimer then
        Ext.Timer.Cancel(displayTimer)
    end
    displayTimer = Ext.Timer.WaitFor(100, function()
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

        displayTimer = nil
    end)
end

local debounceTimer
local function debouncedUpdate()
    if displayTimer then
        Ext.Timer.Cancel(displayTimer)
    end
    displayTimer = Ext.Timer.WaitFor(1000, function()
        update()
        displayTimer = nil
    end)
end

Ext.Osiris.RegisterListener("CombatRoundStarted", 2, "after", function(_, _)
    damageMap = {}
    entityMap = {}

    update()
end)

Ext.Osiris.RegisterListener("TurnStarted", 1, "after", function(character)
    _D({ "TurnStarted", character })

    debouncedUpdate()
end)

Ext.Osiris.RegisterListener("GainedControl", 1, "after", function(character)
    Osi.QuestMessageHide("DamageCap")

    _D({ "GainedControl", character })
    if Osi.IsPlayer(character) ~= 1 then
        return
    end

    debouncedUpdate()
end)

Ext.Osiris.RegisterListener("EnteredCombat", 2, "after", function(character, _)
    debouncedUpdate()
end)

Ext.Osiris.RegisterListener("CastSpell", 5, "before", function(caster, spell, spellType, spellElement, storyActionID)
    if Osi.IsPlayer(caster) ~= 1 then
        debouncedUpdate()

        return
    end

    for _, e in pairs(entityMap) do
        applyBlock(e, damageMap[caster] == 0)
    end
end)

Ext.Osiris.RegisterListener("StartAttack", 4, "before", function(defender, attackOwner, attacker, storyActionID)
    if Osi.IsPlayer(attackOwner) ~= 1 then
        debouncedUpdate()
        return
    end

    applyBlock(entityMap[getUuid(defender)], damageMap[attackOwner] == 0)
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

        if not damageMap[attackerOwner] then
            resetCap(attackerOwner)
        end

        if damageAmount > 0 then
            local leftFromCap = damageMap[attackerOwner]
            local allowedDamage = math.min(leftFromCap, damageAmount)
            damageMap[attackerOwner] = leftFromCap - allowedDamage
        end

        for _, e in pairs(entityMap) do
            applyBlock(e, damageMap[attackerOwner] == 0)
        end

        debouncedUpdate()
    end
)
