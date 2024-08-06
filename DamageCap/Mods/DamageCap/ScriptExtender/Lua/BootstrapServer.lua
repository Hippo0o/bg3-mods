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
        PersistentVars.damageMap[character] = Osi.GetLevel(character) * 10
    end
end

local function updateFor(character)
    defaultVars()
    resetCap(character)

    if PersistentVars.displayedFor[character] ~= PersistentVars.damageMap[character] then
        Ext.Loca.UpdateTranslatedString(
            "hf1e0c115g6d6cg46efg8a89gcc641d501589",
            "Damage left: " .. PersistentVars.damageMap[character]
        )
        Osi.ApplyStatus(character, "DamageCap_Status", 0)
        PersistentVars.displayedFor[character] = PersistentVars.damageMap[character]
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
        if Osi.IsPlayer(attackerOwner) ~= 1 then
            return
        end

        resetCap(attackerOwner)

        if damageAmount > 0 then
            local leftFromCap = PersistentVars.damageMap[attackerOwner]
            local allowedDamage = math.min(leftFromCap, damageAmount)
            PersistentVars.damageMap[attackerOwner] = leftFromCap - allowedDamage
        end

        updateFor(attackerOwner)
    end
)
