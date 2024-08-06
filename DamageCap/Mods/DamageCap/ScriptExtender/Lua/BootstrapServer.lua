function Debounce(delay, callback)
    local timer

    return function(...)
        local args = { ... }

        if timer then
            Ext.Timer.Cancel(timer)
        end

        timer = Ext.Timer.WaitFor(delay, function()
            callback(table.unpack(args))
        end)
    end
end

PersistentVars = {
    damageMap = {},
    displayedFor = {},
    appliedFor = {},
}

local function defaultVars()
    if not PersistentVars.damageMap then
        PersistentVars.damageMap = {}
    end
    if not PersistentVars.displayedFor then
        PersistentVars.displayedFor = {}
    end
    if not PersistentVars.appliedFor then
        PersistentVars.appliedFor = {}
    end
end

local function resetCap(character)
    defaultVars()

    if not PersistentVars.damageMap[character] then
        local highest = 0
        for _, val in ipairs(Ext.Entity.Get(character).Stats.AbilityModifiers) do
            if val > highest then
                highest = val
            end
        end
        local cap = (Osi.GetLevel(character) + highest) * 10

        PersistentVars.damageMap[character] = cap
    end
end

local displayDebounced = Debounce(100, function(character)
    if Osi.HasActiveStatus(character, "DamageCap_Status") == 1 then
        if PersistentVars.displayedFor[character] then
            Ext.Loca.UpdateTranslatedString(
                "hf1e0c115g6d6cg46efg8a89gcc641d501589",
                "Damage left: " .. PersistentVars.displayedFor[character]
            )
        end

        Osi.RemoveStatus(character, "DamageCap_Status")
    end

    local damageLeft = PersistentVars.damageMap[character]
    Ext.Timer.WaitFor(100, function()
        if not damageLeft then
            return
        end

        Ext.Loca.UpdateTranslatedString("hf1e0c115g6d6cg46efg8a89gcc641d501589", "Damage left: " .. damageLeft)
        Osi.ApplyStatus(character, "DamageCap_Status", 1)
    end)

    PersistentVars.displayedFor[character] = damageLeft
end)

local function updateFor(character)
    defaultVars()
    resetCap(character)

    if PersistentVars.displayedFor[character] ~= PersistentVars.damageMap[character] then
        displayDebounced(character)
    end

    if PersistentVars.damageMap[character] <= 0 then
        if Osi.HasActiveStatus(character, "DamageCap_Reached") ~= 1 or not PersistentVars.appliedFor[character] then
            Osi.ApplyStatus(character, "DamageCap_Reached", 1)
            PersistentVars.appliedFor[character] = true
        end
    else
        Osi.RemoveStatus(character, "DamageCap_Reached")
        PersistentVars.appliedFor[character] = false
    end
end

Ext.Osiris.RegisterListener("CombatRoundStarted", 2, "after", function(_, _)
    defaultVars()
    PersistentVars.damageMap = {}
    PersistentVars.displayedFor = {}
    PersistentVars.appliedFor = {}
end)

Ext.Osiris.RegisterListener("TurnStarted", 1, "after", function(character)
    if Osi.IsPlayer(character) ~= 1 then
        return
    end

    updateFor(character)
end)

Ext.Osiris.RegisterListener("GainedControl", 1, "after", function(character)
    if Osi.IsPlayer(character) ~= 1 or Osi.IsInCombat(character) ~= 1 then
        return
    end

    updateFor(character)
end)

Ext.Osiris.RegisterListener(
    "AttackedBy",
    7,
    "before",
    function(defender, attackerOwner, attacker2, damageType, damageAmount, damageCause, storyActionID)
        if Osi.IsPlayer(attackerOwner) ~= 1 or Osi.IsPlayer(defender) == 1 then
            return
        end

        resetCap(attackerOwner)

        if damageAmount > 0 then
            PersistentVars.damageMap[attackerOwner] = PersistentVars.damageMap[attackerOwner] - damageAmount
        end

        updateFor(attackerOwner)
    end
)
