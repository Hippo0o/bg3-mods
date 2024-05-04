local Utils = Require("Shared/Utils")

local M = {}

local Events = {}

function M.Attach()
    for name, func in pairs(Events) do
        for i = 1, 10, 1 do
            Ext.Osiris.RegisterListener(name, i, "after", function(...)
                local log = {}
                for i, v in ipairs({ ... }) do
                    log[i] = v
                end
                Utils.Log.Dump(name, log)
            end)
        end
    end
end

-- copied from Osi.Events.lua

---@param object GUIDSTRING
function Events.Activated(object) end

---@param instanceID integer
---@param player GUIDSTRING
---@param oldIndex integer
---@param newIndex integer
function Events.ActorSpeakerIndexChanged(instanceID, player, oldIndex, newIndex) end

---@param object GUIDSTRING
---@param inventoryHolder GUIDSTRING
---@param addType string
function Events.AddedTo(object, inventoryHolder, addType) end

function Events.AllLoadedFlagsInPresetReceivedEvent() end

---@param object GUIDSTRING
---@param eventName string
---@param wasFromLoad integer
function Events.AnimationEvent(object, eventName, wasFromLoad) end

---@param character CHARACTER
---@param appearEvent string
function Events.AppearTeleportFailed(character, appearEvent) end

---@param ratingOwner CHARACTER
---@param ratedEntity CHARACTER
---@param attemptedApprovalChange integer
---@param clampedApprovalChange integer
---@param newApproval integer
function Events.ApprovalRatingChangeAttempt(
    ratingOwner,
    ratedEntity,
    attemptedApprovalChange,
    clampedApprovalChange,
    newApproval
)
end

---@param ratingOwner CHARACTER
---@param ratedEntity CHARACTER
---@param newApproval integer
function Events.ApprovalRatingChanged(ratingOwner, ratedEntity, newApproval) end

---@param character CHARACTER
---@param item ITEM
function Events.ArmedTrapUsed(character, item) end

---@param character CHARACTER
---@param eArmorSet ARMOURSET
function Events.ArmorSetChanged(character, eArmorSet) end

---@param character CHARACTER
function Events.AttachedToPartyGroup(character) end

---@param defender GUIDSTRING
---@param attackerOwner GUIDSTRING
---@param attacker2 GUIDSTRING
---@param damageType string
---@param damageAmount integer
---@param damageCause string
---@param storyActionID integer
function Events.AttackedBy(defender, attackerOwner, attacker2, damageType, damageAmount, damageCause, storyActionID) end

---@param disarmableItem ITEM
---@param character CHARACTER
---@param itemUsedToDisarm ITEM
---@param bool integer
function Events.AttemptedDisarm(disarmableItem, character, itemUsedToDisarm, bool) end

---@param dialog DIALOGRESOURCE
---@param instanceID integer
function Events.AutomatedDialogEnded(dialog, instanceID) end

---@param dialog DIALOGRESOURCE
---@param instanceID integer
function Events.AutomatedDialogForceStopping(dialog, instanceID) end

---@param dialog DIALOGRESOURCE
---@param instanceID integer
function Events.AutomatedDialogRequestFailed(dialog, instanceID) end

---@param dialog DIALOGRESOURCE
---@param instanceID integer
function Events.AutomatedDialogStarted(dialog, instanceID) end

---@param character CHARACTER
---@param goal GUIDSTRING
function Events.BackgroundGoalFailed(character, goal) end

---@param character CHARACTER
---@param goal GUIDSTRING
function Events.BackgroundGoalRewarded(character, goal) end

---@param target CHARACTER
---@param oldFaction FACTION
---@param newFaction FACTION
function Events.BaseFactionChanged(target, oldFaction, newFaction) end

---@param spline SPLINE
---@param character CHARACTER
---@param event string
---@param index integer
---@param last integer
function Events.CameraReachedNode(spline, character, event, index, last) end

---@param lootingTarget GUIDSTRING
---@param canBeLooted integer
function Events.CanBeLootedCapabilityChanged(lootingTarget, canBeLooted) end

---@param caster GUIDSTRING
---@param spell string
---@param spellType string
---@param spellElement string
---@param storyActionID integer
function Events.CastSpell(caster, spell, spellType, spellElement, storyActionID) end

---@param caster GUIDSTRING
---@param spell string
---@param spellType string
---@param spellElement string
---@param storyActionID integer
function Events.CastSpellFailed(caster, spell, spellType, spellElement, storyActionID) end

---@param caster GUIDSTRING
---@param spell string
---@param spellType string
---@param spellElement string
---@param storyActionID integer
function Events.CastedSpell(caster, spell, spellType, spellElement, storyActionID) end

---@param character CHARACTER
function Events.ChangeAppearanceCancelled(character) end

---@param character CHARACTER
function Events.ChangeAppearanceCompleted(character) end

function Events.CharacterCreationFinished() end

function Events.CharacterCreationStarted() end

---@param character CHARACTER
---@param item ITEM
---@param slotName EQUIPMENTSLOTNAME
function Events.CharacterDisarmed(character, item, slotName) end

---@param character CHARACTER
function Events.CharacterJoinedParty(character) end

---@param character CHARACTER
function Events.CharacterLeftParty(character) end

---@param character CHARACTER
function Events.CharacterLoadedInPreset(character) end

---@param player CHARACTER
---@param lootedCharacter CHARACTER
function Events.CharacterLootedCharacter(player, lootedCharacter) end

---@param character CHARACTER
function Events.CharacterMadePlayer(character) end

---@param character CHARACTER
function Events.CharacterMoveFailedUseJump(character) end

---@param character CHARACTER
---@param target GUIDSTRING
---@param moveID string
---@param failureReason string
function Events.CharacterMoveToAndTalkFailed(character, target, moveID, failureReason) end

---@param character CHARACTER
---@param target GUIDSTRING
---@param dialog DIALOGRESOURCE
---@param moveID string
function Events.CharacterMoveToAndTalkRequestDialog(character, target, dialog, moveID) end

---@param character CHARACTER
---@param moveID integer
function Events.CharacterMoveToCancelled(character, moveID) end

---@param character CHARACTER
---@param crimeRegion string
---@param crimeID integer
---@param priortiyName string
---@param primaryDialog DIALOGRESOURCE
---@param criminal1 CHARACTER
---@param criminal2 CHARACTER
---@param criminal3 CHARACTER
---@param criminal4 CHARACTER
---@param isPrimary integer
function Events.CharacterOnCrimeSensibleActionNotification(
    character,
    crimeRegion,
    crimeID,
    priortiyName,
    primaryDialog,
    criminal1,
    criminal2,
    criminal3,
    criminal4,
    isPrimary
)
end

---@param player CHARACTER
---@param npc CHARACTER
function Events.CharacterPickpocketFailed(player, npc) end

---@param player CHARACTER
---@param npc CHARACTER
---@param item ITEM
---@param itemTemplate GUIDSTRING
---@param amount integer
---@param goldValue integer
function Events.CharacterPickpocketSuccess(player, npc, item, itemTemplate, amount, goldValue) end

---@param character CHARACTER
---@param oldUserID integer
---@param newUserID integer
function Events.CharacterReservedUserIDChanged(character, oldUserID, newUserID) end

---@param character CHARACTER
---@param crimeRegion string
---@param unavailableForCrimeID integer
---@param busyCrimeID integer
function Events.CharacterSelectedAsBestUnavailableFallbackLead(
    character,
    crimeRegion,
    unavailableForCrimeID,
    busyCrimeID
)
end

---@param character CHARACTER
function Events.CharacterSelectedClimbOn(character) end

---@param character CHARACTER
---@param userID integer
function Events.CharacterSelectedForUser(character, userID) end

---@param character CHARACTER
---@param item ITEM
---@param itemRootTemplate GUIDSTRING
---@param x number
---@param y number
---@param z number
---@param oldOwner CHARACTER
---@param srcContainer ITEM
---@param amount integer
---@param goldValue integer
function Events.CharacterStoleItem(
    character,
    item,
    itemRootTemplate,
    x,
    y,
    z,
    oldOwner,
    srcContainer,
    amount,
    goldValue
)
end

---@param character CHARACTER
---@param tag TAG
---@param event string
function Events.CharacterTagEvent(character, tag, event) end

---@param item ITEM
function Events.Closed(item) end

---@param combatGuid GUIDSTRING
function Events.CombatEnded(combatGuid) end

---@param combatGuid GUIDSTRING
function Events.CombatPaused(combatGuid) end

---@param combatGuid GUIDSTRING
function Events.CombatResumed(combatGuid) end

---@param combatGuid GUIDSTRING
---@param round integer
function Events.CombatRoundStarted(combatGuid, round) end

---@param combatGuid GUIDSTRING
function Events.CombatStarted(combatGuid) end

---@param item1 ITEM
---@param item2 ITEM
---@param item3 ITEM
---@param item4 ITEM
---@param item5 ITEM
---@param character CHARACTER
---@param newItem ITEM
function Events.Combined(item1, item2, item3, item4, item5, character, newItem) end

---@param character CHARACTER
---@param userID integer
function Events.CompanionSelectedForUser(character, userID) end

function Events.CreditsEnded() end

---@param character CHARACTER
---@param crime string
function Events.CrimeDisabled(character, crime) end

---@param character CHARACTER
---@param crime string
function Events.CrimeEnabled(character, crime) end

---@param victim CHARACTER
---@param crimeType string
---@param crimeID integer
---@param evidence GUIDSTRING
---@param criminal1 CHARACTER
---@param criminal2 CHARACTER
---@param criminal3 CHARACTER
---@param criminal4 CHARACTER
function Events.CrimeIsRegistered(victim, crimeType, crimeID, evidence, criminal1, criminal2, criminal3, criminal4) end

---@param crimeID integer
---@param actedOnImmediately integer
function Events.CrimeProcessingStarted(crimeID, actedOnImmediately) end

---@param defender CHARACTER
---@param attackOwner CHARACTER
---@param attacker CHARACTER
---@param storyActionID integer
function Events.CriticalHitBy(defender, attackOwner, attacker, storyActionID) end

---@param character CHARACTER
---@param bookName string
function Events.CustomBookUIClosed(character, bookName) end

---@param dlc DLC
---@param userID integer
---@param installed integer
function Events.DLCUpdated(dlc, userID, installed) end

---@param object GUIDSTRING
function Events.Deactivated(object) end

---@param character CHARACTER
function Events.DeathSaveStable(character) end

---@param item ITEM
---@param destroyer CHARACTER
---@param destroyerOwner CHARACTER
---@param storyActionID integer
function Events.DestroyedBy(item, destroyer, destroyerOwner, storyActionID) end

---@param item ITEM
---@param destroyer CHARACTER
---@param destroyerOwner CHARACTER
---@param storyActionID integer
function Events.DestroyingBy(item, destroyer, destroyerOwner, storyActionID) end

---@param character CHARACTER
function Events.DetachedFromPartyGroup(character) end

---@param dialog DIALOGRESOURCE
---@param instanceID integer
---@param actor GUIDSTRING
function Events.DialogActorJoinFailed(dialog, instanceID, actor) end

---@param dialog DIALOGRESOURCE
---@param instanceID integer
---@param actor GUIDSTRING
---@param speakerIndex integer
function Events.DialogActorJoined(dialog, instanceID, actor, speakerIndex) end

---@param dialog DIALOGRESOURCE
---@param instanceID integer
---@param actor GUIDSTRING
---@param instanceEnded integer
function Events.DialogActorLeft(dialog, instanceID, actor, instanceEnded) end

---@param target CHARACTER
---@param player CHARACTER
function Events.DialogAttackRequested(target, player) end

---@param dialog DIALOGRESOURCE
---@param instanceID integer
function Events.DialogEnded(dialog, instanceID) end

---@param dialog DIALOGRESOURCE
---@param instanceID integer
function Events.DialogForceStopping(dialog, instanceID) end

---@param dialog DIALOGRESOURCE
---@param instanceID integer
function Events.DialogRequestFailed(dialog, instanceID) end

---@param character CHARACTER
---@param success integer
---@param dialog DIALOGRESOURCE
---@param isDetectThoughts integer
---@param criticality CRITICALITYTYPE
function Events.DialogRollResult(character, success, dialog, isDetectThoughts, criticality) end

---@param target GUIDSTRING
---@param player GUIDSTRING
function Events.DialogStartRequested(target, player) end

---@param dialog DIALOGRESOURCE
---@param instanceID integer
function Events.DialogStarted(dialog, instanceID) end

---@param character CHARACTER
---@param isEnabled integer
function Events.DialogueCapabilityChanged(character, isEnabled) end

---@param character CHARACTER
function Events.Died(character) end

---@param difficultyLevel integer
function Events.DifficultyChanged(difficultyLevel) end

---@param character CHARACTER
---@param moveID integer
function Events.DisappearOutOfSightToCancelled(character, moveID) end

---@param itemTemplate ITEMROOT
---@param item2 ITEM
---@param character CHARACTER
function Events.DoorTemplateClosing(itemTemplate, item2, character) end

---@param character CHARACTER
---@param isDowned integer
function Events.DownedChanged(character, isDowned) end

---@param object GUIDSTRING
---@param mover CHARACTER
function Events.DroppedBy(object, mover) end

---@param object1 GUIDSTRING
---@param object2 GUIDSTRING
---@param event string
function Events.DualEntityEvent(object1, object2, event) end

---@param character CHARACTER
function Events.Dying(character) end

---@param character CHARACTER
function Events.EndTheDayRequested(character) end

---@param opponentLeft GUIDSTRING
---@param opponentRight GUIDSTRING
function Events.EnterCombatFailed(opponentLeft, opponentRight) end

---@param object GUIDSTRING
---@param cause GUIDSTRING
---@param chasm GUIDSTRING
---@param fallbackPosX number
---@param fallbackPosY number
---@param fallbackPosZ number
function Events.EnteredChasm(object, cause, chasm, fallbackPosX, fallbackPosY, fallbackPosZ) end

---@param object GUIDSTRING
---@param combatGuid GUIDSTRING
function Events.EnteredCombat(object, combatGuid) end

---@param object GUIDSTRING
function Events.EnteredForceTurnBased(object) end

---@param object GUIDSTRING
---@param objectRootTemplate ROOT
---@param level string
function Events.EnteredLevel(object, objectRootTemplate, level) end

---@param object GUIDSTRING
---@param zoneId GUIDSTRING
function Events.EnteredSharedForceTurnBased(object, zoneId) end

---@param character CHARACTER
---@param trigger TRIGGER
function Events.EnteredTrigger(character, trigger) end

---@param object GUIDSTRING
---@param event string
function Events.EntityEvent(object, event) end

---@param item ITEM
---@param character CHARACTER
function Events.EquipFailed(item, character) end

---@param item ITEM
---@param character CHARACTER
function Events.Equipped(item, character) end

---@param oldLeader GUIDSTRING
---@param newLeader GUIDSTRING
---@param group string
function Events.EscortGroupLeaderChanged(oldLeader, newLeader, group) end

---@param character CHARACTER
---@param originalItem ITEM
---@param level string
---@param newItem ITEM
function Events.FailedToLoadItemInPreset(character, originalItem, level, newItem) end

---@param entity GUIDSTRING
---@param cause GUIDSTRING
function Events.Falling(entity, cause) end

---@param entity GUIDSTRING
---@param cause GUIDSTRING
function Events.Fell(entity, cause) end

---@param flag FLAG
---@param speaker GUIDSTRING
---@param dialogInstance integer
function Events.FlagCleared(flag, speaker, dialogInstance) end

---@param object GUIDSTRING
---@param flag FLAG
function Events.FlagLoadedInPresetEvent(object, flag) end

---@param flag FLAG
---@param speaker GUIDSTRING
---@param dialogInstance integer
function Events.FlagSet(flag, speaker, dialogInstance) end

---@param participant GUIDSTRING
---@param combatGuid GUIDSTRING
function Events.FleeFromCombat(participant, combatGuid) end

---@param character CHARACTER
function Events.FollowerCantUseItem(character) end

---@param companion CHARACTER
function Events.ForceDismissCompanion(companion) end

---@param source GUIDSTRING
---@param target GUIDSTRING
---@param storyActionID integer
function Events.ForceMoveEnded(source, target, storyActionID) end

---@param source GUIDSTRING
---@param target GUIDSTRING
---@param storyActionID integer
function Events.ForceMoveStarted(source, target, storyActionID) end

---@param target CHARACTER
function Events.GainedControl(target) end

---@param item ITEM
---@param character CHARACTER
function Events.GameBookInterfaceClosed(item, character) end

---@param gameMode string
---@param isEditorMode integer
---@param isStoryReload integer
function Events.GameModeStarted(gameMode, isEditorMode, isStoryReload) end

---@param key string
---@param value string
function Events.GameOption(key, value) end

---@param inventoryHolder GUIDSTRING
---@param changeAmount integer
function Events.GoldChanged(inventoryHolder, changeAmount) end

---@param target CHARACTER
function Events.GotUp(target) end

---@param character CHARACTER
---@param trader CHARACTER
---@param characterValue integer
---@param traderValue integer
function Events.HappyWithDeal(character, trader, characterValue, traderValue) end

---@param player CHARACTER
function Events.HenchmanAborted(player) end

---@param player CHARACTER
---@param hireling CHARACTER
function Events.HenchmanSelected(player, hireling) end

---@param proxy GUIDSTRING
---@param target GUIDSTRING
---@param attackerOwner GUIDSTRING
---@param attacker2 GUIDSTRING
---@param storyActionID integer
function Events.HitProxy(proxy, target, attackerOwner, attacker2, storyActionID) end

---@param entity GUIDSTRING
---@param percentage number
function Events.HitpointsChanged(entity, percentage) end

---@param instanceID integer
---@param oldDialog DIALOGRESOURCE
---@param newDialog DIALOGRESOURCE
---@param oldDialogStopping integer
function Events.InstanceDialogChanged(instanceID, oldDialog, newDialog, oldDialogStopping) end

---@param character CHARACTER
---@param isEnabled integer
function Events.InteractionCapabilityChanged(character, isEnabled) end

---@param character CHARACTER
---@param item ITEM
function Events.InteractionFallback(character, item) end

---@param item ITEM
---@param isBoundToInventory integer
function Events.InventoryBoundChanged(item, isBoundToInventory) end

---@param character CHARACTER
---@param sharingEnabled integer
function Events.InventorySharingChanged(character, sharingEnabled) end

---@param item ITEM
---@param trigger TRIGGER
---@param mover GUIDSTRING
function Events.ItemEnteredTrigger(item, trigger, mover) end

---@param item ITEM
---@param trigger TRIGGER
---@param mover GUIDSTRING
function Events.ItemLeftTrigger(item, trigger, mover) end

---@param target ITEM
---@param oldX number
---@param oldY number
---@param oldZ number
---@param newX number
---@param newY number
---@param newZ number
function Events.ItemTeleported(target, oldX, oldY, oldZ, newX, newY, newZ) end

---@param defender CHARACTER
---@param attackOwner GUIDSTRING
---@param attacker GUIDSTRING
---@param storyActionID integer
function Events.KilledBy(defender, attackOwner, attacker, storyActionID) end

---@param character CHARACTER
---@param spell string
function Events.LearnedSpell(character, spell) end

---@param object GUIDSTRING
---@param combatGuid GUIDSTRING
function Events.LeftCombat(object, combatGuid) end

---@param object GUIDSTRING
function Events.LeftForceTurnBased(object) end

---@param object GUIDSTRING
---@param level string
function Events.LeftLevel(object, level) end

---@param character CHARACTER
---@param trigger TRIGGER
function Events.LeftTrigger(character, trigger) end

---@param levelName string
---@param isEditorMode integer
function Events.LevelGameplayStarted(levelName, isEditorMode) end

---@param newLevel string
function Events.LevelLoaded(newLevel) end

---@param levelTemplate LEVELTEMPLATE
function Events.LevelTemplateLoaded(levelTemplate) end

---@param level string
function Events.LevelUnloading(level) end

---@param character CHARACTER
function Events.LeveledUp(character) end

function Events.LongRestCancelled() end

function Events.LongRestFinished() end

function Events.LongRestStartFailed() end

function Events.LongRestStarted() end

---@param character CHARACTER
---@param targetCharacter CHARACTER
function Events.LostSightOf(character, targetCharacter) end

---@param character CHARACTER
---@param event string
function Events.MainPerformerStarted(character, event) end

---@param character CHARACTER
---@param message string
---@param resultChoice string
function Events.MessageBoxChoiceClosed(character, message, resultChoice) end

---@param character CHARACTER
---@param message string
function Events.MessageBoxClosed(character, message) end

---@param character CHARACTER
---@param message string
---@param result integer
function Events.MessageBoxYesNoClosed(character, message, result) end

---@param defender CHARACTER
---@param attackOwner CHARACTER
---@param attacker CHARACTER
---@param storyActionID integer
function Events.MissedBy(defender, attackOwner, attacker, storyActionID) end

---@param name string
---@param major integer
---@param minor integer
---@param revision integer
---@param build integer
function Events.ModuleLoadedinSavegame(name, major, minor, revision, build) end

---@param character CHARACTER
---@param isEnabled integer
function Events.MoveCapabilityChanged(character, isEnabled) end

---@param item ITEM
function Events.Moved(item) end

---@param movedEntity GUIDSTRING
---@param character CHARACTER
function Events.MovedBy(movedEntity, character) end

---@param movedObject GUIDSTRING
---@param fromObject GUIDSTRING
---@param toObject GUIDSTRING
---@param isTrade integer
function Events.MovedFromTo(movedObject, fromObject, toObject, isTrade) end

---@param movieName string
function Events.MovieFinished(movieName) end

---@param movieName string
function Events.MoviePlaylistFinished(movieName) end

---@param dialog DIALOGRESOURCE
---@param instanceID integer
function Events.NestedDialogPlayed(dialog, instanceID) end

---@param character CHARACTER
---@param oldLevel integer
---@param newLevel integer
function Events.ObjectAvailableLevelChanged(character, oldLevel, newLevel) end

---@param object GUIDSTRING
---@param timer string
function Events.ObjectTimerFinished(object, timer) end

---@param object GUIDSTRING
---@param toTemplate GUIDSTRING
function Events.ObjectTransformed(object, toTemplate) end

---@param object GUIDSTRING
---@param obscuredState string
function Events.ObscuredStateChanged(object, obscuredState) end

---@param crimeID integer
---@param investigator CHARACTER
---@param wasLead integer
---@param criminal1 CHARACTER
---@param criminal2 CHARACTER
---@param criminal3 CHARACTER
---@param criminal4 CHARACTER
function Events.OnCrimeConfrontationDone(crimeID, investigator, wasLead, criminal1, criminal2, criminal3, criminal4) end

---@param crimeID integer
---@param investigator CHARACTER
---@param fromState string
---@param toState string
function Events.OnCrimeInvestigatorSwitchedState(crimeID, investigator, fromState, toState) end

---@param oldCrimeID integer
---@param newCrimeID integer
function Events.OnCrimeMergedWith(oldCrimeID, newCrimeID) end

---@param crimeID integer
---@param victim CHARACTER
---@param criminal1 CHARACTER
---@param criminal2 CHARACTER
---@param criminal3 CHARACTER
---@param criminal4 CHARACTER
function Events.OnCrimeRemoved(crimeID, victim, criminal1, criminal2, criminal3, criminal4) end

---@param crimeID integer
---@param criminal CHARACTER
function Events.OnCrimeResetInterrogationForCriminal(crimeID, criminal) end

---@param crimeID integer
---@param victim CHARACTER
---@param criminal1 CHARACTER
---@param criminal2 CHARACTER
---@param criminal3 CHARACTER
---@param criminal4 CHARACTER
function Events.OnCrimeResolved(crimeID, victim, criminal1, criminal2, criminal3, criminal4) end

---@param crimeID integer
---@param criminal CHARACTER
function Events.OnCriminalMergedWithCrime(crimeID, criminal) end

---@param isEditorMode integer
function Events.OnShutdown(isEditorMode) end

---@param carriedObject GUIDSTRING
---@param carriedObjectTemplate ROOT
---@param carrier GUIDSTRING
---@param storyActionID integer
---@param pickupPosX number
---@param pickupPosY number
---@param pickupPosZ number
function Events.OnStartCarrying(
    carriedObject,
    carriedObjectTemplate,
    carrier,
    storyActionID,
    pickupPosX,
    pickupPosY,
    pickupPosZ
)
end

---@param target CHARACTER
function Events.OnStoryOverride(target) end

---@param thrownObject GUIDSTRING
---@param thrownObjectTemplate ROOT
---@param thrower GUIDSTRING
---@param storyActionID integer
---@param throwPosX number
---@param throwPosY number
---@param throwPosZ number
function Events.OnThrown(
    thrownObject,
    thrownObjectTemplate,
    thrower,
    storyActionID,
    throwPosX,
    throwPosY,
    throwPosZ
)
end

---@param item ITEM
function Events.Opened(item) end

---@param partyPreset string
---@param levelName string
function Events.PartyPresetLoaded(partyPreset, levelName) end

---@param character CHARACTER
---@param item ITEM
function Events.PickupFailed(character, item) end

---@param character CHARACTER
function Events.PingRequested(character) end

---@param object GUIDSTRING
function Events.PlatformDestroyed(object) end

---@param object GUIDSTRING
---@param eventId string
function Events.PlatformMovementCanceled(object, eventId) end

---@param object GUIDSTRING
---@param eventId string
function Events.PlatformMovementFinished(object, eventId) end

---@param item ITEM
---@param character CHARACTER
function Events.PreMovedBy(item, character) end

---@param character CHARACTER
---@param uIInstance string
---@param type integer
function Events.PuzzleUIClosed(character, uIInstance, type) end

---@param character CHARACTER
---@param uIInstance string
---@param type integer
---@param command string
---@param elementId integer
function Events.PuzzleUIUsed(character, uIInstance, type, command, elementId) end

---@param character CHARACTER
---@param questID string
function Events.QuestAccepted(character, questID) end

---@param questID string
function Events.QuestClosed(questID) end

---@param character CHARACTER
---@param topLevelQuestID string
---@param stateID string
function Events.QuestUpdateUnlocked(character, topLevelQuestID, stateID) end

---@param object GUIDSTRING
function Events.QueuePurged(object) end

---@param caster GUIDSTRING
---@param storyActionID integer
---@param spellID string
---@param rollResult integer
---@param randomCastDC integer
function Events.RandomCastProcessed(caster, storyActionID, spellID, rollResult, randomCastDC) end

---@param object GUIDSTRING
function Events.ReactionInterruptActionNeeded(object) end

---@param character CHARACTER
---@param reactionInterruptName string
function Events.ReactionInterruptAdded(character, reactionInterruptName) end

---@param object GUIDSTRING
---@param reactionInterruptPrototypeId string
---@param isAutoTriggered integer
function Events.ReactionInterruptUsed(object, reactionInterruptPrototypeId, isAutoTriggered) end

---@param id string
function Events.ReadyCheckFailed(id) end

---@param id string
function Events.ReadyCheckPassed(id) end

---@param sourceFaction FACTION
---@param targetFaction FACTION
---@param newRelation integer
---@param permanent integer
function Events.RelationChanged(sourceFaction, targetFaction, newRelation, permanent) end

---@param object GUIDSTRING
---@param inventoryHolder GUIDSTRING
function Events.RemovedFrom(object, inventoryHolder) end

---@param entity GUIDSTRING
---@param onEntity GUIDSTRING
function Events.ReposeAdded(entity, onEntity) end

---@param entity GUIDSTRING
---@param onEntity GUIDSTRING
function Events.ReposeRemoved(entity, onEntity) end

---@param character CHARACTER
---@param item1 ITEM
---@param item2 ITEM
---@param item3 ITEM
---@param item4 ITEM
---@param item5 ITEM
---@param requestID integer
function Events.RequestCanCombine(character, item1, item2, item3, item4, item5, requestID) end

---@param character CHARACTER
---@param item ITEM
---@param requestID integer
function Events.RequestCanDisarmTrap(character, item, requestID) end

---@param character CHARACTER
---@param item ITEM
---@param requestID integer
function Events.RequestCanLockpick(character, item, requestID) end

---@param looter CHARACTER
---@param target CHARACTER
function Events.RequestCanLoot(looter, target) end

---@param character CHARACTER
---@param item ITEM
---@param requestID integer
function Events.RequestCanMove(character, item, requestID) end

---@param character CHARACTER
---@param object GUIDSTRING
---@param requestID integer
function Events.RequestCanPickup(character, object, requestID) end

---@param character CHARACTER
---@param item ITEM
---@param requestID integer
function Events.RequestCanUse(character, item, requestID) end

function Events.RequestEndTheDayFail() end

function Events.RequestEndTheDaySuccess() end

---@param character CHARACTER
function Events.RequestGatherAtCampFail(character) end

---@param character CHARACTER
function Events.RequestGatherAtCampSuccess(character) end

---@param player CHARACTER
---@param npc CHARACTER
function Events.RequestPickpocket(player, npc) end

---@param character CHARACTER
---@param trader CHARACTER
---@param tradeMode TRADEMODE
---@param itemsTagFilter string
function Events.RequestTrade(character, trader, tradeMode, itemsTagFilter) end

---@param character CHARACTER
function Events.RespecCancelled(character) end

---@param character CHARACTER
function Events.RespecCompleted(character) end

---@param character CHARACTER
function Events.Resurrected(character) end

---@param eventName string
---@param roller CHARACTER
---@param rollSubject GUIDSTRING
---@param resultType integer
---@param isActiveRoll integer
---@param criticality CRITICALITYTYPE
function Events.RollResult(eventName, roller, rollSubject, resultType, isActiveRoll, criticality) end

---@param modifier RULESETMODIFIER
---@param old integer
---@param new integer
function Events.RulesetModifierChangedBool(modifier, old, new) end

---@param modifier RULESETMODIFIER
---@param old number
---@param new number
function Events.RulesetModifierChangedFloat(modifier, old, new) end

---@param modifier RULESETMODIFIER
---@param old integer
---@param new integer
function Events.RulesetModifierChangedInt(modifier, old, new) end

---@param modifier RULESETMODIFIER
---@param old string
---@param new string
function Events.RulesetModifierChangedString(modifier, old, new) end

---@param userID integer
---@param state integer
function Events.SafeRomanceOptionChanged(userID, state) end

function Events.SavegameLoadStarted() end

function Events.SavegameLoaded() end

---@param character CHARACTER
---@param targetCharacter CHARACTER
---@param targetWasSneaking integer
function Events.Saw(character, targetCharacter, targetWasSneaking) end

---@param item ITEM
---@param x number
---@param y number
---@param z number
function Events.ScatteredAt(item, x, y, z) end

---@param userID integer
---@param fadeID string
function Events.ScreenFadeCleared(userID, fadeID) end

---@param userID integer
---@param fadeID string
function Events.ScreenFadeDone(userID, fadeID) end

---@param character CHARACTER
---@param race string
---@param gender string
---@param shapeshiftStatus string
function Events.ShapeshiftChanged(character, race, gender, shapeshiftStatus) end

---@param entity GUIDSTRING
---@param percentage number
function Events.ShapeshiftedHitpointsChanged(entity, percentage) end

---@param object GUIDSTRING
function Events.ShareInitiative(object) end

---@param character CHARACTER
---@param capable integer
function Events.ShortRestCapable(character, capable) end

---@param character CHARACTER
function Events.ShortRestProcessing(character) end

---@param character CHARACTER
function Events.ShortRested(character) end

---@param item ITEM
---@param stackedWithItem ITEM
function Events.StackedWith(item, stackedWithItem) end

---@param defender GUIDSTRING
---@param attackOwner CHARACTER
---@param attacker GUIDSTRING
---@param storyActionID integer
function Events.StartAttack(defender, attackOwner, attacker, storyActionID) end

---@param x number
---@param y number
---@param z number
---@param attackOwner CHARACTER
---@param attacker GUIDSTRING
---@param storyActionID integer
function Events.StartAttackPosition(x, y, z, attackOwner, attacker, storyActionID) end

---@param character CHARACTER
---@param item ITEM
function Events.StartedDisarmingTrap(character, item) end

---@param character CHARACTER
function Events.StartedFleeing(character) end

---@param character CHARACTER
---@param item ITEM
function Events.StartedLockpicking(character, item) end

---@param caster GUIDSTRING
---@param spell string
---@param isMostPowerful integer
---@param hasMultipleLevels integer
function Events.StartedPreviewingSpell(caster, spell, isMostPowerful, hasMultipleLevels) end

---@param object GUIDSTRING
---@param status string
---@param causee GUIDSTRING
---@param storyActionID integer
function Events.StatusApplied(object, status, causee, storyActionID) end

---@param object GUIDSTRING
---@param status string
---@param causee GUIDSTRING
---@param storyActionID integer
function Events.StatusAttempt(object, status, causee, storyActionID) end

---@param object GUIDSTRING
---@param status string
---@param causee GUIDSTRING
---@param storyActionID integer
function Events.StatusAttemptFailed(object, status, causee, storyActionID) end

---@param object GUIDSTRING
---@param status string
---@param causee GUIDSTRING
---@param applyStoryActionID integer
function Events.StatusRemoved(object, status, causee, applyStoryActionID) end

---@param target GUIDSTRING
---@param tag TAG
---@param sourceOwner GUIDSTRING
---@param source2 GUIDSTRING
---@param storyActionID integer
function Events.StatusTagCleared(target, tag, sourceOwner, source2, storyActionID) end

---@param target GUIDSTRING
---@param tag TAG
---@param sourceOwner GUIDSTRING
---@param source2 GUIDSTRING
---@param storyActionID integer
function Events.StatusTagSet(target, tag, sourceOwner, source2, storyActionID) end

---@param character CHARACTER
---@param item1 ITEM
---@param item2 ITEM
---@param item3 ITEM
---@param item4 ITEM
---@param item5 ITEM
function Events.StoppedCombining(character, item1, item2, item3, item4, item5) end

---@param character CHARACTER
---@param item ITEM
function Events.StoppedDisarmingTrap(character, item) end

---@param character CHARACTER
---@param item ITEM
function Events.StoppedLockpicking(character, item) end

---@param character CHARACTER
function Events.StoppedSneaking(character) end

---@param character CHARACTER
---@param subQuestID string
---@param stateID string
function Events.SubQuestUpdateUnlocked(character, subQuestID, stateID) end

---@param templateId GUIDSTRING
---@param amount integer
function Events.SupplyTemplateSpent(templateId, amount) end

---@param object GUIDSTRING
---@param group string
function Events.SwarmAIGroupJoined(object, group) end

---@param object GUIDSTRING
---@param group string
function Events.SwarmAIGroupLeft(object, group) end

---@param object GUIDSTRING
---@param oldCombatGuid GUIDSTRING
---@param newCombatGuid GUIDSTRING
function Events.SwitchedCombat(object, oldCombatGuid, newCombatGuid) end

---@param character CHARACTER
---@param power string
function Events.TadpolePowerAssigned(character, power) end

---@param target GUIDSTRING
---@param tag TAG
function Events.TagCleared(target, tag) end

---@param tag TAG
---@param event string
function Events.TagEvent(tag, event) end

---@param target GUIDSTRING
---@param tag TAG
function Events.TagSet(target, tag) end

---@param character CHARACTER
---@param trigger TRIGGER
function Events.TeleportToFleeWaypoint(character, trigger) end

---@param character CHARACTER
function Events.TeleportToFromCamp(character) end

---@param character CHARACTER
---@param trigger TRIGGER
function Events.TeleportToWaypoint(character, trigger) end

---@param target CHARACTER
---@param cause CHARACTER
---@param oldX number
---@param oldY number
---@param oldZ number
---@param newX number
---@param newY number
---@param newZ number
---@param spell string
function Events.Teleported(target, cause, oldX, oldY, oldZ, newX, newY, newZ, spell) end

---@param character CHARACTER
function Events.TeleportedFromCamp(character) end

---@param character CHARACTER
function Events.TeleportedToCamp(character) end

---@param objectTemplate ROOT
---@param object2 GUIDSTRING
---@param inventoryHolder GUIDSTRING
---@param addType string
function Events.TemplateAddedTo(objectTemplate, object2, inventoryHolder, addType) end

---@param itemTemplate ITEMROOT
---@param item2 ITEM
---@param destroyer CHARACTER
---@param destroyerOwner CHARACTER
---@param storyActionID integer
function Events.TemplateDestroyedBy(itemTemplate, item2, destroyer, destroyerOwner, storyActionID) end

---@param itemTemplate ITEMROOT
---@param item2 ITEM
---@param trigger TRIGGER
---@param owner CHARACTER
---@param mover GUIDSTRING
function Events.TemplateEnteredTrigger(itemTemplate, item2, trigger, owner, mover) end

---@param itemTemplate ITEMROOT
---@param character CHARACTER
function Events.TemplateEquipped(itemTemplate, character) end

---@param characterTemplate CHARACTERROOT
---@param defender CHARACTER
---@param attackOwner GUIDSTRING
---@param attacker GUIDSTRING
---@param storyActionID integer
function Events.TemplateKilledBy(characterTemplate, defender, attackOwner, attacker, storyActionID) end

---@param itemTemplate ITEMROOT
---@param item2 ITEM
---@param trigger TRIGGER
---@param owner CHARACTER
---@param mover GUIDSTRING
function Events.TemplateLeftTrigger(itemTemplate, item2, trigger, owner, mover) end

---@param itemTemplate ITEMROOT
---@param item2 ITEM
---@param character CHARACTER
function Events.TemplateOpening(itemTemplate, item2, character) end

---@param objectTemplate ROOT
---@param object2 GUIDSTRING
---@param inventoryHolder GUIDSTRING
function Events.TemplateRemovedFrom(objectTemplate, object2, inventoryHolder) end

---@param itemTemplate ITEMROOT
---@param character CHARACTER
function Events.TemplateUnequipped(itemTemplate, character) end

---@param character CHARACTER
---@param itemTemplate ITEMROOT
---@param item2 ITEM
---@param sucess integer
function Events.TemplateUseFinished(character, itemTemplate, item2, sucess) end

---@param character CHARACTER
---@param itemTemplate ITEMROOT
---@param item2 ITEM
function Events.TemplateUseStarted(character, itemTemplate, item2) end

---@param template1 ITEMROOT
---@param template2 ITEMROOT
---@param template3 ITEMROOT
---@param template4 ITEMROOT
---@param template5 ITEMROOT
---@param character CHARACTER
---@param newItem ITEM
function Events.TemplatesCombined(template1, template2, template3, template4, template5, character, newItem) end

---@param enemy CHARACTER
---@param sourceFaction FACTION
---@param targetFaction FACTION
function Events.TemporaryHostileRelationRemoved(enemy, sourceFaction, targetFaction) end

---@param character1 CHARACTER
---@param character2 CHARACTER
---@param success integer
function Events.TemporaryHostileRelationRequestHandled(character1, character2, success) end

---@param event string
function Events.TextEvent(event) end

---@param userID integer
---@param dialogInstanceId integer
---@param dialog2 DIALOGRESOURCE
function Events.TimelineScreenFadeStarted(userID, dialogInstanceId, dialog2) end

---@param timer string
function Events.TimerFinished(timer) end

---@param character CHARACTER
---@param trader CHARACTER
function Events.TradeEnds(character, trader) end

---@param trader CHARACTER
function Events.TradeGenerationEnded(trader) end

---@param trader CHARACTER
function Events.TradeGenerationStarted(trader) end

---@param object GUIDSTRING
function Events.TurnEnded(object) end

---@param object GUIDSTRING
function Events.TurnStarted(object) end

---@param character CHARACTER
---@param message string
function Events.TutorialBoxClosed(character, message) end

---@param userId integer
---@param entryId GUIDSTRING
function Events.TutorialClosed(userId, entryId) end

---@param entity CHARACTER
---@param event TUTORIALEVENT
function Events.TutorialEvent(entity, event) end

---@param item ITEM
---@param character CHARACTER
function Events.UnequipFailed(item, character) end

---@param item ITEM
---@param character CHARACTER
function Events.Unequipped(item, character) end

---@param item ITEM
---@param character CHARACTER
---@param key ITEM
function Events.Unlocked(item, character, key) end

---@param character CHARACTER
---@param recipe string
function Events.UnlockedRecipe(character, recipe) end

---@param character CHARACTER
---@param item ITEM
---@param sucess integer
function Events.UseFinished(character, item, sucess) end

---@param character CHARACTER
---@param item ITEM
function Events.UseStarted(character, item) end

---@param userID integer
---@param avatar CHARACTER
---@param daisy CHARACTER
function Events.UserAvatarCreated(userID, avatar, daisy) end

---@param userID integer
---@param chest ITEM
function Events.UserCampChestChanged(userID, chest) end

---@param character CHARACTER
---@param isFullRest integer
function Events.UserCharacterLongRested(character, isFullRest) end

---@param userID integer
---@param userName string
---@param userProfileID string
function Events.UserConnected(userID, userName, userProfileID) end

---@param userID integer
---@param userName string
---@param userProfileID string
function Events.UserDisconnected(userID, userName, userProfileID) end

---@param userID integer
---@param userEvent string
function Events.UserEvent(userID, userEvent) end

---@param sourceUserID integer
---@param targetUserID integer
---@param war integer
function Events.UserMakeWar(sourceUserID, targetUserID, war) end

---@param caster GUIDSTRING
---@param spell string
---@param spellType string
---@param spellElement string
---@param storyActionID integer
function Events.UsingSpell(caster, spell, spellType, spellElement, storyActionID) end

---@param caster GUIDSTRING
---@param x number
---@param y number
---@param z number
---@param spell string
---@param spellType string
---@param spellElement string
---@param storyActionID integer
function Events.UsingSpellAtPosition(caster, x, y, z, spell, spellType, spellElement, storyActionID) end

---@param caster GUIDSTRING
---@param spell string
---@param spellType string
---@param spellElement string
---@param trigger TRIGGER
---@param storyActionID integer
function Events.UsingSpellInTrigger(caster, spell, spellType, spellElement, trigger, storyActionID) end

---@param caster GUIDSTRING
---@param target GUIDSTRING
---@param spell string
---@param spellType string
---@param spellElement string
---@param storyActionID integer
function Events.UsingSpellOnTarget(caster, target, spell, spellType, spellElement, storyActionID) end

---@param caster GUIDSTRING
---@param target GUIDSTRING
---@param spell string
---@param spellType string
---@param spellElement string
---@param storyActionID integer
function Events.UsingSpellOnZoneWithTarget(caster, target, spell, spellType, spellElement, storyActionID) end

---@param bark VOICEBARKRESOURCE
---@param instanceID integer
function Events.VoiceBarkEnded(bark, instanceID) end

---@param bark VOICEBARKRESOURCE
function Events.VoiceBarkFailed(bark) end

---@param bark VOICEBARKRESOURCE
---@param instanceID integer
function Events.VoiceBarkStarted(bark, instanceID) end

---@param object GUIDSTRING
---@param isOnStageNow integer
function Events.WentOnStage(object, isOnStageNow) end

return M
