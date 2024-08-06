---@type Utils
local Utils = Require("Shared/Utils")

local M = {}

local events = {}

function M.Attach()
    for name, params in pairs(events) do
        params = Utils.String.Split(params, ",")
        if params[1] == "" then
            params = {}
        end
        Ext.Osiris.RegisterListener(name, #params, "after", function(...)
            local log = {}
            for i, v in ipairs(params) do
                v = Utils.String.Trim(v)
                log[v] = select(i, ...)
            end
            Utils.Log.Dump(name, log)
        end)
    end
end

-- copied from Osi.Events.lua

---@param object GUIDSTRING
events.Activated = "object"

---@param instanceID integer
---@param player GUIDSTRING
---@param oldIndex integer
---@param newIndex integer
events.ActorSpeakerIndexChanged = "instanceID, player, oldIndex, newIndex"

---@param object GUIDSTRING
---@param inventoryHolder GUIDSTRING
---@param addType string
events.AddedTo = "object, inventoryHolder, addType"

events.AllLoadedFlagsInPresetReceivedEvent = ""

---@param object GUIDSTRING
---@param eventName string
---@param wasFromLoad integer
events.AnimationEvent = "object, eventName, wasFromLoad"

---@param character CHARACTER
---@param appearEvent string
events.AppearTeleportFailed = "character, appearEvent"

---@param ratingOwner CHARACTER
---@param ratedEntity CHARACTER
---@param attemptedApprovalChange integer
---@param clampedApprovalChange integer
---@param newApproval integer
events.ApprovalRatingChangeAttempt =
    "ratingOwner, ratedEntity, attemptedApprovalChange, clampedApprovalChange, newApproval"

---@param ratingOwner CHARACTER
---@param ratedEntity CHARACTER
---@param newApproval integer
events.ApprovalRatingChanged = "ratingOwner, ratedEntity, newApproval"

---@param character CHARACTER
---@param item ITEM
events.ArmedTrapUsed = "character, item"

---@param character CHARACTER
---@param eArmorSet ARMOURSET
events.ArmorSetChanged = "character, eArmorSet"

---@param character CHARACTER
events.AttachedToPartyGroup = "character"

---@param defender GUIDSTRING
---@param attackerOwner GUIDSTRING
---@param attacker2 GUIDSTRING
---@param damageType string
---@param damageAmount integer
---@param damageCause string
---@param storyActionID integer
events.AttackedBy = "defender, attackerOwner, attacker2, damageType, damageAmount, damageCause, storyActionID"

---@param disarmableItem ITEM
---@param character CHARACTER
---@param itemUsedToDisarm ITEM
---@param bool integer
events.AttemptedDisarm = "disarmableItem, character, itemUsedToDisarm, bool"

---@param dialog DIALOGRESOURCE
---@param instanceID integer
events.AutomatedDialogEnded = "dialog, instanceID"

---@param dialog DIALOGRESOURCE
---@param instanceID integer
events.AutomatedDialogForceStopping = "dialog, instanceID"

---@param dialog DIALOGRESOURCE
---@param instanceID integer
events.AutomatedDialogRequestFailed = "dialog, instanceID"

---@param dialog DIALOGRESOURCE
---@param instanceID integer
events.AutomatedDialogStarted = "dialog, instanceID"

---@param character CHARACTER
---@param goal GUIDSTRING
events.BackgroundGoalFailed = "character, goal"

---@param character CHARACTER
---@param goal GUIDSTRING
events.BackgroundGoalRewarded = "character, goal"

---@param target CHARACTER
---@param oldFaction FACTION
---@param newFaction FACTION
events.BaseFactionChanged = "target, oldFaction, newFaction"

---@param spline SPLINE
---@param character CHARACTER
---@param event string
---@param index integer
---@param last integer
events.CameraReachedNode = "spline, character, event, index, last"

---@param lootingTarget GUIDSTRING
---@param canBeLooted integer
events.CanBeLootedCapabilityChanged = "lootingTarget, canBeLooted"

---@param caster GUIDSTRING
---@param spell string
---@param spellType string
---@param spellElement string
---@param storyActionID integer
events.CastSpell = "caster, spell, spellType, spellElement, storyActionID"

---@param caster GUIDSTRING
---@param spell string
---@param spellType string
---@param spellElement string
---@param storyActionID integer
events.CastSpellFailed = "caster, spell, spellType, spellElement, storyActionID"

---@param caster GUIDSTRING
---@param spell string
---@param spellType string
---@param spellElement string
---@param storyActionID integer
events.CastedSpell = "caster, spell, spellType, spellElement, storyActionID"

---@param character CHARACTER
events.ChangeAppearanceCancelled = "character"

---@param character CHARACTER
events.ChangeAppearanceCompleted = "character"

events.CharacterCreationFinished = ""

events.CharacterCreationStarted = ""

---@param character CHARACTER
---@param item ITEM
---@param slotName EQUIPMENTSLOTNAME
events.CharacterDisarmed = "character, item, slotName"

---@param character CHARACTER
events.CharacterJoinedParty = "character"

---@param character CHARACTER
events.CharacterLeftParty = "character"

---@param character CHARACTER
events.CharacterLoadedInPreset = "character"

---@param player CHARACTER
---@param lootedCharacter CHARACTER
events.CharacterLootedCharacter = "player, lootedCharacter"

---@param character CHARACTER
events.CharacterMadePlayer = "character"

---@param character CHARACTER
events.CharacterMoveFailedUseJump = "character"

---@param character CHARACTER
---@param target GUIDSTRING
---@param moveID string
---@param failureReason string
events.CharacterMoveToAndTalkFailed = "character, target, moveID, failureReason"

---@param character CHARACTER
---@param target GUIDSTRING
---@param dialog DIALOGRESOURCE
---@param moveID string
events.CharacterMoveToAndTalkRequestDialog = "character, target, dialog, moveID"

---@param character CHARACTER
---@param moveID integer
events.CharacterMoveToCancelled = "character, moveID"

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
events.CharacterOnCrimeSensibleActionNotification =
    "character, crimeRegion, crimeID, priortiyName, primaryDialog, criminal1, criminal2, criminal3, criminal4, isPrimary"

---@param player CHARACTER
---@param npc CHARACTER
events.CharacterPickpocketFailed = "player, npc"

---@param player CHARACTER
---@param npc CHARACTER
---@param item ITEM
---@param itemTemplate GUIDSTRING
---@param amount integer
---@param goldValue integer
events.CharacterPickpocketSuccess = "player, npc, item, itemTemplate, amount, goldValue"

---@param character CHARACTER
---@param oldUserID integer
---@param newUserID integer
events.CharacterReservedUserIDChanged = "character, oldUserID, newUserID"

---@param character CHARACTER
---@param crimeRegion string
---@param unavailableForCrimeID integer
---@param busyCrimeID integer
events.CharacterSelectedAsBestUnavailableFallbackLead = "character, crimeRegion, unavailableForCrimeID, busyCrimeID"

---@param character CHARACTER
events.CharacterSelectedClimbOn = "character"

---@param character CHARACTER
---@param userID integer
events.CharacterSelectedForUser = "character, userID"

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
events.CharacterStoleItem = "character, item, itemRootTemplate, x, y, z, oldOwner, srcContainer, amount, goldValue"

---@param character CHARACTER
---@param tag TAG
---@param event string
events.CharacterTagEvent = "character, tag, event"

---@param item ITEM
events.Closed = "item"

---@param combatGuid GUIDSTRING
events.CombatEnded = "combatGuid"

---@param combatGuid GUIDSTRING
events.CombatPaused = "combatGuid"

---@param combatGuid GUIDSTRING
events.CombatResumed = "combatGuid"

---@param combatGuid GUIDSTRING
---@param round integer
events.CombatRoundStarted = "combatGuid, round"

---@param combatGuid GUIDSTRING
events.CombatStarted = "combatGuid"

---@param item1 ITEM
---@param item2 ITEM
---@param item3 ITEM
---@param item4 ITEM
---@param item5 ITEM
---@param character CHARACTER
---@param newItem ITEM
events.Combined = "item1, item2, item3, item4, item5, character, newItem"

---@param character CHARACTER
---@param userID integer
events.CompanionSelectedForUser = "character, userID"

events.CreditsEnded = ""

---@param character CHARACTER
---@param crime string
events.CrimeDisabled = "character, crime"

---@param character CHARACTER
---@param crime string
events.CrimeEnabled = "character, crime"

---@param victim CHARACTER
---@param crimeType string
---@param crimeID integer
---@param evidence GUIDSTRING
---@param criminal1 CHARACTER
---@param criminal2 CHARACTER
---@param criminal3 CHARACTER
---@param criminal4 CHARACTER
events.CrimeIsRegistered = "victim, crimeType, crimeID, evidence, criminal1, criminal2, criminal3, criminal4"

---@param crimeID integer
---@param actedOnImmediately integer
events.CrimeProcessingStarted = "crimeID, actedOnImmediately"

---@param defender CHARACTER
---@param attackOwner CHARACTER
---@param attacker CHARACTER
---@param storyActionID integer
events.CriticalHitBy = "defender, attackOwner, attacker, storyActionID"

---@param character CHARACTER
---@param bookName string
events.CustomBookUIClosed = "character, bookName"

---@param dlc DLC
---@param userID integer
---@param installed integer
events.DLCUpdated = "dlc, userID, installed"

---@param object GUIDSTRING
events.Deactivated = "object"

---@param character CHARACTER
events.DeathSaveStable = "character"

---@param item ITEM
---@param destroyer CHARACTER
---@param destroyerOwner CHARACTER
---@param storyActionID integer
events.DestroyedBy = "item, destroyer, destroyerOwner, storyActionID"

---@param item ITEM
---@param destroyer CHARACTER
---@param destroyerOwner CHARACTER
---@param storyActionID integer
events.DestroyingBy = "item, destroyer, destroyerOwner, storyActionID"

---@param character CHARACTER
events.DetachedFromPartyGroup = "character"

---@param dialog DIALOGRESOURCE
---@param instanceID integer
---@param actor GUIDSTRING
events.DialogActorJoinFailed = "dialog, instanceID, actor"

---@param dialog DIALOGRESOURCE
---@param instanceID integer
---@param actor GUIDSTRING
---@param speakerIndex integer
events.DialogActorJoined = "dialog, instanceID, actor, speakerIndex"

---@param dialog DIALOGRESOURCE
---@param instanceID integer
---@param actor GUIDSTRING
---@param instanceEnded integer
events.DialogActorLeft = "dialog, instanceID, actor, instanceEnded"

---@param target CHARACTER
---@param player CHARACTER
events.DialogAttackRequested = "target, player"

---@param dialog DIALOGRESOURCE
---@param instanceID integer
events.DialogEnded = "dialog, instanceID"

---@param dialog DIALOGRESOURCE
---@param instanceID integer
events.DialogForceStopping = "dialog, instanceID"

---@param dialog DIALOGRESOURCE
---@param instanceID integer
events.DialogRequestFailed = "dialog, instanceID"

---@param character CHARACTER
---@param success integer
---@param dialog DIALOGRESOURCE
---@param isDetectThoughts integer
---@param criticality CRITICALITYTYPE
events.DialogRollResult = "character, success, dialog, isDetectThoughts, criticality"

---@param target GUIDSTRING
---@param player GUIDSTRING
events.DialogStartRequested = "target, player"

---@param dialog DIALOGRESOURCE
---@param instanceID integer
events.DialogStarted = "dialog, instanceID"

---@param character CHARACTER
---@param isEnabled integer
events.DialogueCapabilityChanged = "character, isEnabled"

---@param character CHARACTER
events.Died = "character"

---@param difficultyLevel integer
events.DifficultyChanged = "difficultyLevel"

---@param character CHARACTER
---@param moveID integer
events.DisappearOutOfSightToCancelled = "character, moveID"

---@param itemTemplate ITEMROOT
---@param item2 ITEM
---@param character CHARACTER
events.DoorTemplateClosing = "itemTemplate, item2, character"

---@param character CHARACTER
---@param isDowned integer
events.DownedChanged = "character, isDowned"

---@param object GUIDSTRING
---@param mover CHARACTER
events.DroppedBy = "object, mover"

---@param object1 GUIDSTRING
---@param object2 GUIDSTRING
---@param event string
events.DualEntityEvent = "object1, object2, event"

---@param character CHARACTER
events.Dying = "character"

---@param character CHARACTER
events.EndTheDayRequested = "character"

---@param opponentLeft GUIDSTRING
---@param opponentRight GUIDSTRING
events.EnterCombatFailed = "opponentLeft, opponentRight"

---@param object GUIDSTRING
---@param cause GUIDSTRING
---@param chasm GUIDSTRING
---@param fallbackPosX number
---@param fallbackPosY number
---@param fallbackPosZ number
events.EnteredChasm = "object, cause, chasm, fallbackPosX, fallbackPosY, fallbackPosZ"

---@param object GUIDSTRING
---@param combatGuid GUIDSTRING
events.EnteredCombat = "object, combatGuid"

---@param object GUIDSTRING
events.EnteredForceTurnBased = "object"

---@param object GUIDSTRING
---@param objectRootTemplate ROOT
---@param level string
events.EnteredLevel = "object, objectRootTemplate, level"

---@param object GUIDSTRING
---@param zoneId GUIDSTRING
events.EnteredSharedForceTurnBased = "object, zoneId"

---@param character CHARACTER
---@param trigger TRIGGER
events.EnteredTrigger = "character, trigger"

---@param object GUIDSTRING
---@param event string
events.EntityEvent = "object, event"

---@param item ITEM
---@param character CHARACTER
events.EquipFailed = "item, character"

---@param item ITEM
---@param character CHARACTER
events.Equipped = "item, character"

---@param oldLeader GUIDSTRING
---@param newLeader GUIDSTRING
---@param group string
events.EscortGroupLeaderChanged = "oldLeader, newLeader, group"

---@param character CHARACTER
---@param originalItem ITEM
---@param level string
---@param newItem ITEM
events.FailedToLoadItemInPreset = "character, originalItem, level, newItem"

---@param entity GUIDSTRING
---@param cause GUIDSTRING
events.Falling = "entity, cause"

---@param entity GUIDSTRING
---@param cause GUIDSTRING
events.Fell = "entity, cause"

---@param flag FLAG
---@param speaker GUIDSTRING
---@param dialogInstance integer
events.FlagCleared = "flag, speaker, dialogInstance"

---@param object GUIDSTRING
---@param flag FLAG
events.FlagLoadedInPresetEvent = "object, flag"

---@param flag FLAG
---@param speaker GUIDSTRING
---@param dialogInstance integer
events.FlagSet = "flag, speaker, dialogInstance"

---@param participant GUIDSTRING
---@param combatGuid GUIDSTRING
events.FleeFromCombat = "participant, combatGuid"

---@param character CHARACTER
events.FollowerCantUseItem = "character"

---@param companion CHARACTER
events.ForceDismissCompanion = "companion"

---@param source GUIDSTRING
---@param target GUIDSTRING
---@param storyActionID integer
events.ForceMoveEnded = "source, target, storyActionID"

---@param source GUIDSTRING
---@param target GUIDSTRING
---@param storyActionID integer
events.ForceMoveStarted = "source, target, storyActionID"

---@param target CHARACTER
events.GainedControl = "target"

---@param item ITEM
---@param character CHARACTER
events.GameBookInterfaceClosed = "item, character"

---@param gameMode string
---@param isEditorMode integer
---@param isStoryReload integer
events.GameModeStarted = "gameMode, isEditorMode, isStoryReload"

---@param key string
---@param value string
events.GameOption = "key, value"

---@param inventoryHolder GUIDSTRING
---@param changeAmount integer
events.GoldChanged = "inventoryHolder, changeAmount"

---@param target CHARACTER
events.GotUp = "target"

---@param character CHARACTER
---@param trader CHARACTER
---@param characterValue integer
---@param traderValue integer
events.HappyWithDeal = "character, trader, characterValue, traderValue"

---@param player CHARACTER
events.HenchmanAborted = "player"

---@param player CHARACTER
---@param hireling CHARACTER
events.HenchmanSelected = "player, hireling"

---@param proxy GUIDSTRING
---@param target GUIDSTRING
---@param attackerOwner GUIDSTRING
---@param attacker2 GUIDSTRING
---@param storyActionID integer
events.HitProxy = "proxy, target, attackerOwner, attacker2, storyActionID"

---@param entity GUIDSTRING
---@param percentage number
events.HitpointsChanged = "entity, percentage"

---@param instanceID integer
---@param oldDialog DIALOGRESOURCE
---@param newDialog DIALOGRESOURCE
---@param oldDialogStopping integer
events.InstanceDialogChanged = "instanceID, oldDialog, newDialog, oldDialogStopping"

---@param character CHARACTER
---@param isEnabled integer
events.InteractionCapabilityChanged = "character, isEnabled"

---@param character CHARACTER
---@param item ITEM
events.InteractionFallback = "character, item"

---@param item ITEM
---@param isBoundToInventory integer
events.InventoryBoundChanged = "item, isBoundToInventory"

---@param character CHARACTER
---@param sharingEnabled integer
events.InventorySharingChanged = "character, sharingEnabled"

---@param item ITEM
---@param trigger TRIGGER
---@param mover GUIDSTRING
events.ItemEnteredTrigger = "item, trigger, mover"

---@param item ITEM
---@param trigger TRIGGER
---@param mover GUIDSTRING
events.ItemLeftTrigger = "item, trigger, mover"

---@param target ITEM
---@param oldX number
---@param oldY number
---@param oldZ number
---@param newX number
---@param newY number
---@param newZ number
events.ItemTeleported = "target, oldX, oldY, oldZ, newX, newY, newZ"

---@param defender CHARACTER
---@param attackOwner GUIDSTRING
---@param attacker GUIDSTRING
---@param storyActionID integer
events.KilledBy = "defender, attackOwner, attacker, storyActionID"

---@param character CHARACTER
---@param spell string
events.LearnedSpell = "character, spell"

---@param object GUIDSTRING
---@param combatGuid GUIDSTRING
events.LeftCombat = "object, combatGuid"

---@param object GUIDSTRING
events.LeftForceTurnBased = "object"

---@param object GUIDSTRING
---@param level string
events.LeftLevel = "object, level"

---@param character CHARACTER
---@param trigger TRIGGER
events.LeftTrigger = "character, trigger"

---@param levelName string
---@param isEditorMode integer
events.LevelGameplayStarted = "levelName, isEditorMode"

---@param newLevel string
events.LevelLoaded = "newLevel"

---@param levelTemplate LEVELTEMPLATE
events.LevelTemplateLoaded = "levelTemplate"

---@param level string
events.LevelUnloading = "level"

---@param character CHARACTER
events.LeveledUp = "character"

events.LongRestCancelled = ""

events.LongRestFinished = ""

events.LongRestStartFailed = ""

events.LongRestStarted = ""

---@param character CHARACTER
---@param targetCharacter CHARACTER
events.LostSightOf = "character, targetCharacter"

---@param character CHARACTER
---@param event string
events.MainPerformerStarted = "character, event"

---@param character CHARACTER
---@param message string
---@param resultChoice string
events.MessageBoxChoiceClosed = "character, message, resultChoice"

---@param character CHARACTER
---@param message string
events.MessageBoxClosed = "character, message"

---@param character CHARACTER
---@param message string
---@param result integer
events.MessageBoxYesNoClosed = "character, message, result"

---@param defender CHARACTER
---@param attackOwner CHARACTER
---@param attacker CHARACTER
---@param storyActionID integer
events.MissedBy = "defender, attackOwner, attacker, storyActionID"

---@param name string
---@param major integer
---@param minor integer
---@param revision integer
---@param build integer
events.ModuleLoadedinSavegame = "name, major, minor, revision, build"

---@param character CHARACTER
---@param isEnabled integer
events.MoveCapabilityChanged = "character, isEnabled"

---@param item ITEM
events.Moved = "item"

---@param movedEntity GUIDSTRING
---@param character CHARACTER
events.MovedBy = "movedEntity, character"

---@param movedObject GUIDSTRING
---@param fromObject GUIDSTRING
---@param toObject GUIDSTRING
---@param isTrade integer
events.MovedFromTo = "movedObject, fromObject, toObject, isTrade"

---@param movieName string
events.MovieFinished = "movieName"

---@param movieName string
events.MoviePlaylistFinished = "movieName"

---@param dialog DIALOGRESOURCE
---@param instanceID integer
events.NestedDialogPlayed = "dialog, instanceID"

---@param character CHARACTER
---@param oldLevel integer
---@param newLevel integer
events.ObjectAvailableLevelChanged = "character, oldLevel, newLevel"

---@param object GUIDSTRING
---@param timer string
events.ObjectTimerFinished = "object, timer"

---@param object GUIDSTRING
---@param toTemplate GUIDSTRING
events.ObjectTransformed = "object, toTemplate"

---@param object GUIDSTRING
---@param obscuredState string
events.ObscuredStateChanged = "object, obscuredState"

---@param crimeID integer
---@param investigator CHARACTER
---@param wasLead integer
---@param criminal1 CHARACTER
---@param criminal2 CHARACTER
---@param criminal3 CHARACTER
---@param criminal4 CHARACTER
events.OnCrimeConfrontationDone = "crimeID, investigator, wasLead, criminal1, criminal2, criminal3, criminal4"

---@param crimeID integer
---@param investigator CHARACTER
---@param fromState string
---@param toState string
events.OnCrimeInvestigatorSwitchedState = "crimeID, investigator, fromState, toState"

---@param oldCrimeID integer
---@param newCrimeID integer
events.OnCrimeMergedWith = "oldCrimeID, newCrimeID"

---@param crimeID integer
---@param victim CHARACTER
---@param criminal1 CHARACTER
---@param criminal2 CHARACTER
---@param criminal3 CHARACTER
---@param criminal4 CHARACTER
events.OnCrimeRemoved = "crimeID, victim, criminal1, criminal2, criminal3, criminal4"

---@param crimeID integer
---@param criminal CHARACTER
events.OnCrimeResetInterrogationForCriminal = "crimeID, criminal"

---@param crimeID integer
---@param victim CHARACTER
---@param criminal1 CHARACTER
---@param criminal2 CHARACTER
---@param criminal3 CHARACTER
---@param criminal4 CHARACTER
events.OnCrimeResolved = "crimeID, victim, criminal1, criminal2, criminal3, criminal4"

---@param crimeID integer
---@param criminal CHARACTER
events.OnCriminalMergedWithCrime = "crimeID, criminal"

---@param isEditorMode integer
events.OnShutdown = "isEditorMode"

---@param carriedObject GUIDSTRING
---@param carriedObjectTemplate ROOT
---@param carrier GUIDSTRING
---@param storyActionID integer
---@param pickupPosX number
---@param pickupPosY number
---@param pickupPosZ number
events.OnStartCarrying =
    "carriedObject, carriedObjectTemplate, carrier, storyActionID, pickupPosX, pickupPosY, pickupPosZ"

---@param target CHARACTER
events.OnStoryOverride = "target"

---@param thrownObject GUIDSTRING
---@param thrownObjectTemplate ROOT
---@param thrower GUIDSTRING
---@param storyActionID integer
---@param throwPosX number
---@param throwPosY number
---@param throwPosZ number
events.OnThrown = "thrownObject, thrownObjectTemplate, thrower, storyActionID, throwPosX, throwPosY, throwPosZ"

---@param item ITEM
events.Opened = "item"

---@param partyPreset string
---@param levelName string
events.PartyPresetLoaded = "partyPreset, levelName"

---@param character CHARACTER
---@param item ITEM
events.PickupFailed = "character, item"

---@param character CHARACTER
events.PingRequested = "character"

---@param object GUIDSTRING
events.PlatformDestroyed = "object"

---@param object GUIDSTRING
---@param eventId string
events.PlatformMovementCanceled = "object, eventId"

---@param object GUIDSTRING
---@param eventId string
events.PlatformMovementFinished = "object, eventId"

---@param item ITEM
---@param character CHARACTER
events.PreMovedBy = "item, character"

---@param character CHARACTER
---@param uIInstance string
---@param type integer
events.PuzzleUIClosed = "character, uIInstance, type"

---@param character CHARACTER
---@param uIInstance string
---@param type integer
---@param command string
---@param elementId integer
events.PuzzleUIUsed = "character, uIInstance, type, command, elementId"

---@param character CHARACTER
---@param questID string
events.QuestAccepted = "character, questID"

---@param questID string
events.QuestClosed = "questID"

---@param character CHARACTER
---@param topLevelQuestID string
---@param stateID string
events.QuestUpdateUnlocked = "character, topLevelQuestID, stateID"

---@param object GUIDSTRING
events.QueuePurged = "object"

---@param caster GUIDSTRING
---@param storyActionID integer
---@param spellID string
---@param rollResult integer
---@param randomCastDC integer
events.RandomCastProcessed = "caster, storyActionID, spellID, rollResult, randomCastDC"

---@param object GUIDSTRING
events.ReactionInterruptActionNeeded = "object"

---@param character CHARACTER
---@param reactionInterruptName string
events.ReactionInterruptAdded = "character, reactionInterruptName"

---@param object GUIDSTRING
---@param reactionInterruptPrototypeId string
---@param isAutoTriggered integer
events.ReactionInterruptUsed = "object, reactionInterruptPrototypeId, isAutoTriggered"

---@param id string
events.ReadyCheckFailed = "id"

---@param id string
events.ReadyCheckPassed = "id"

---@param sourceFaction FACTION
---@param targetFaction FACTION
---@param newRelation integer
---@param permanent integer
events.RelationChanged = "sourceFaction, targetFaction, newRelation, permanent"

---@param object GUIDSTRING
---@param inventoryHolder GUIDSTRING
events.RemovedFrom = "object, inventoryHolder"

---@param entity GUIDSTRING
---@param onEntity GUIDSTRING
events.ReposeAdded = "entity, onEntity"

---@param entity GUIDSTRING
---@param onEntity GUIDSTRING
events.ReposeRemoved = "entity, onEntity"

---@param character CHARACTER
---@param item1 ITEM
---@param item2 ITEM
---@param item3 ITEM
---@param item4 ITEM
---@param item5 ITEM
---@param requestID integer
events.RequestCanCombine = "character, item1, item2, item3, item4, item5, requestID"

---@param character CHARACTER
---@param item ITEM
---@param requestID integer
events.RequestCanDisarmTrap = "character, item, requestID"

---@param character CHARACTER
---@param item ITEM
---@param requestID integer
events.RequestCanLockpick = "character, item, requestID"

---@param looter CHARACTER
---@param target CHARACTER
events.RequestCanLoot = "looter, target"

---@param character CHARACTER
---@param item ITEM
---@param requestID integer
events.RequestCanMove = "character, item, requestID"

---@param character CHARACTER
---@param object GUIDSTRING
---@param requestID integer
events.RequestCanPickup = "character, object, requestID"

---@param character CHARACTER
---@param item ITEM
---@param requestID integer
events.RequestCanUse = "character, item, requestID"

events.RequestEndTheDayFail = ""

events.RequestEndTheDaySuccess = ""

---@param character CHARACTER
events.RequestGatherAtCampFail = "character"

---@param character CHARACTER
events.RequestGatherAtCampSuccess = "character"

---@param player CHARACTER
---@param npc CHARACTER
events.RequestPickpocket = "player, npc"

---@param character CHARACTER
---@param trader CHARACTER
---@param tradeMode TRADEMODE
---@param itemsTagFilter string
events.RequestTrade = "character, trader, tradeMode, itemsTagFilter"

---@param character CHARACTER
events.RespecCancelled = "character"

---@param character CHARACTER
events.RespecCompleted = "character"

---@param character CHARACTER
events.Resurrected = "character"

---@param eventName string
---@param roller CHARACTER
---@param rollSubject GUIDSTRING
---@param resultType integer
---@param isActiveRoll integer
---@param criticality CRITICALITYTYPE
events.RollResult = "eventName, roller, rollSubject, resultType, isActiveRoll, criticality"

---@param modifier RULESETMODIFIER
---@param old integer
---@param new integer
events.RulesetModifierChangedBool = "modifier, old, new"

---@param modifier RULESETMODIFIER
---@param old number
---@param new number
events.RulesetModifierChangedFloat = "modifier, old, new"

---@param modifier RULESETMODIFIER
---@param old integer
---@param new integer
events.RulesetModifierChangedInt = "modifier, old, new"

---@param modifier RULESETMODIFIER
---@param old string
---@param new string
events.RulesetModifierChangedString = "modifier, old, new"

---@param userID integer
---@param state integer
events.SafeRomanceOptionChanged = "userID, state"

events.SavegameLoadStarted = ""

events.SavegameLoaded = ""

---@param character CHARACTER
---@param targetCharacter CHARACTER
---@param targetWasSneaking integer
events.Saw = "character, targetCharacter, targetWasSneaking"

---@param item ITEM
---@param x number
---@param y number
---@param z number
events.ScatteredAt = "item, x, y, z"

---@param userID integer
---@param fadeID string
events.ScreenFadeCleared = "userID, fadeID"

---@param userID integer
---@param fadeID string
events.ScreenFadeDone = "userID, fadeID"

---@param character CHARACTER
---@param race string
---@param gender string
---@param shapeshiftStatus string
events.ShapeshiftChanged = "character, race, gender, shapeshiftStatus"

---@param entity GUIDSTRING
---@param percentage number
events.ShapeshiftedHitpointsChanged = "entity, percentage"

---@param object GUIDSTRING
events.ShareInitiative = "object"

---@param character CHARACTER
---@param capable integer
events.ShortRestCapable = "character, capable"

---@param character CHARACTER
events.ShortRestProcessing = "character"

---@param character CHARACTER
events.ShortRested = "character"

---@param item ITEM
---@param stackedWithItem ITEM
events.StackedWith = "item, stackedWithItem"

---@param defender GUIDSTRING
---@param attackOwner CHARACTER
---@param attacker GUIDSTRING
---@param storyActionID integer
events.StartAttack = "defender, attackOwner, attacker, storyActionID"

---@param x number
---@param y number
---@param z number
---@param attackOwner CHARACTER
---@param attacker GUIDSTRING
---@param storyActionID integer
events.StartAttackPosition = "x, y, z, attackOwner, attacker, storyActionID"

---@param character CHARACTER
---@param item ITEM
events.StartedDisarmingTrap = "character, item"

---@param character CHARACTER
events.StartedFleeing = "character"

---@param character CHARACTER
---@param item ITEM
events.StartedLockpicking = "character, item"

---@param caster GUIDSTRING
---@param spell string
---@param isMostPowerful integer
---@param hasMultipleLevels integer
events.StartedPreviewingSpell = "caster, spell, isMostPowerful, hasMultipleLevels"

---@param object GUIDSTRING
---@param status string
---@param causee GUIDSTRING
---@param storyActionID integer
events.StatusApplied = "object, status, causee, storyActionID"

---@param object GUIDSTRING
---@param status string
---@param causee GUIDSTRING
---@param storyActionID integer
events.StatusAttempt = "object, status, causee, storyActionID"

---@param object GUIDSTRING
---@param status string
---@param causee GUIDSTRING
---@param storyActionID integer
events.StatusAttemptFailed = "object, status, causee, storyActionID"

---@param object GUIDSTRING
---@param status string
---@param causee GUIDSTRING
---@param applyStoryActionID integer
events.StatusRemoved = "object, status, causee, applyStoryActionID"

---@param target GUIDSTRING
---@param tag TAG
---@param sourceOwner GUIDSTRING
---@param source2 GUIDSTRING
---@param storyActionID integer
events.StatusTagCleared = "target, tag, sourceOwner, source2, storyActionID"

---@param target GUIDSTRING
---@param tag TAG
---@param sourceOwner GUIDSTRING
---@param source2 GUIDSTRING
---@param storyActionID integer
events.StatusTagSet = "target, tag, sourceOwner, source2, storyActionID"

---@param character CHARACTER
---@param item1 ITEM
---@param item2 ITEM
---@param item3 ITEM
---@param item4 ITEM
---@param item5 ITEM
events.StoppedCombining = "character, item1, item2, item3, item4, item5"

---@param character CHARACTER
---@param item ITEM
events.StoppedDisarmingTrap = "character, item"

---@param character CHARACTER
---@param item ITEM
events.StoppedLockpicking = "character, item"

---@param character CHARACTER
events.StoppedSneaking = "character"

---@param character CHARACTER
---@param subQuestID string
---@param stateID string
events.SubQuestUpdateUnlocked = "character, subQuestID, stateID"

---@param templateId GUIDSTRING
---@param amount integer
events.SupplyTemplateSpent = "templateId, amount"

---@param object GUIDSTRING
---@param group string
events.SwarmAIGroupJoined = "object, group"

---@param object GUIDSTRING
---@param group string
events.SwarmAIGroupLeft = "object, group"

---@param object GUIDSTRING
---@param oldCombatGuid GUIDSTRING
---@param newCombatGuid GUIDSTRING
events.SwitchedCombat = "object, oldCombatGuid, newCombatGuid"

---@param character CHARACTER
---@param power string
events.TadpolePowerAssigned = "character, power"

---@param target GUIDSTRING
---@param tag TAG
events.TagCleared = "target, tag"

---@param tag TAG
---@param event string
events.TagEvent = "tag, event"

---@param target GUIDSTRING
---@param tag TAG
events.TagSet = "target, tag"

---@param character CHARACTER
---@param trigger TRIGGER
events.TeleportToFleeWaypoint = "character, trigger"

---@param character CHARACTER
events.TeleportToFromCamp = "character"

---@param character CHARACTER
---@param trigger TRIGGER
events.TeleportToWaypoint = "character, trigger"

---@param target CHARACTER
---@param cause CHARACTER
---@param oldX number
---@param oldY number
---@param oldZ number
---@param newX number
---@param newY number
---@param newZ number
---@param spell string
events.Teleported = "target, cause, oldX, oldY, oldZ, newX, newY, newZ, spell"

---@param character CHARACTER
events.TeleportedFromCamp = "character"

---@param character CHARACTER
events.TeleportedToCamp = "character"

---@param objectTemplate ROOT
---@param object2 GUIDSTRING
---@param inventoryHolder GUIDSTRING
---@param addType string
events.TemplateAddedTo = "objectTemplate, object2, inventoryHolder, addType"

---@param itemTemplate ITEMROOT
---@param item2 ITEM
---@param destroyer CHARACTER
---@param destroyerOwner CHARACTER
---@param storyActionID integer
events.TemplateDestroyedBy = "itemTemplate, item2, destroyer, destroyerOwner, storyActionID"

---@param itemTemplate ITEMROOT
---@param item2 ITEM
---@param trigger TRIGGER
---@param owner CHARACTER
---@param mover GUIDSTRING
events.TemplateEnteredTrigger = "itemTemplate, item2, trigger, owner, mover"

---@param itemTemplate ITEMROOT
---@param character CHARACTER
events.TemplateEquipped = "itemTemplate, character"

---@param characterTemplate CHARACTERROOT
---@param defender CHARACTER
---@param attackOwner GUIDSTRING
---@param attacker GUIDSTRING
---@param storyActionID integer
events.TemplateKilledBy = "characterTemplate, defender, attackOwner, attacker, storyActionID"

---@param itemTemplate ITEMROOT
---@param item2 ITEM
---@param trigger TRIGGER
---@param owner CHARACTER
---@param mover GUIDSTRING
events.TemplateLeftTrigger = "itemTemplate, item2, trigger, owner, mover"

---@param itemTemplate ITEMROOT
---@param item2 ITEM
---@param character CHARACTER
events.TemplateOpening = "itemTemplate, item2, character"

---@param objectTemplate ROOT
---@param object2 GUIDSTRING
---@param inventoryHolder GUIDSTRING
events.TemplateRemovedFrom = "objectTemplate, object2, inventoryHolder"

---@param itemTemplate ITEMROOT
---@param character CHARACTER
events.TemplateUnequipped = "itemTemplate, character"

---@param character CHARACTER
---@param itemTemplate ITEMROOT
---@param item2 ITEM
---@param sucess integer
events.TemplateUseFinished = "character, itemTemplate, item2, sucess"

---@param character CHARACTER
---@param itemTemplate ITEMROOT
---@param item2 ITEM
events.TemplateUseStarted = "character, itemTemplate, item2"

---@param template1 ITEMROOT
---@param template2 ITEMROOT
---@param template3 ITEMROOT
---@param template4 ITEMROOT
---@param template5 ITEMROOT
---@param character CHARACTER
---@param newItem ITEM
events.TemplatesCombined = "template1, template2, template3, template4, template5, character, newItem"

---@param enemy CHARACTER
---@param sourceFaction FACTION
---@param targetFaction FACTION
events.TemporaryHostileRelationRemoved = "enemy, sourceFaction, targetFaction"

---@param character1 CHARACTER
---@param character2 CHARACTER
---@param success integer
events.TemporaryHostileRelationRequestHandled = "character1, character2, success"

---@param event string
events.TextEvent = "event"

---@param userID integer
---@param dialogInstanceId integer
---@param dialog2 DIALOGRESOURCE
events.TimelineScreenFadeStarted = "userID, dialogInstanceId, dialog2"

---@param timer string
events.TimerFinished = "timer"

---@param character CHARACTER
---@param trader CHARACTER
events.TradeEnds = "character, trader"

---@param trader CHARACTER
events.TradeGenerationEnded = "trader"

---@param trader CHARACTER
events.TradeGenerationStarted = "trader"

---@param object GUIDSTRING
events.TurnEnded = "object"

---@param object GUIDSTRING
events.TurnStarted = "object"

---@param character CHARACTER
---@param message string
events.TutorialBoxClosed = "character, message"

---@param userId integer
---@param entryId GUIDSTRING
events.TutorialClosed = "userId, entryId"

---@param entity CHARACTER
---@param event TUTORIALEVENT
events.TutorialEvent = "entity, event"

---@param item ITEM
---@param character CHARACTER
events.UnequipFailed = "item, character"

---@param item ITEM
---@param character CHARACTER
events.Unequipped = "item, character"

---@param item ITEM
---@param character CHARACTER
---@param key ITEM
events.Unlocked = "item, character, key"

---@param character CHARACTER
---@param recipe string
events.UnlockedRecipe = "character, recipe"

---@param character CHARACTER
---@param item ITEM
---@param sucess integer
events.UseFinished = "character, item, sucess"

---@param character CHARACTER
---@param item ITEM
events.UseStarted = "character, item"

---@param userID integer
---@param avatar CHARACTER
---@param daisy CHARACTER
events.UserAvatarCreated = "userID, avatar, daisy"

---@param userID integer
---@param chest ITEM
events.UserCampChestChanged = "userID, chest"

---@param character CHARACTER
---@param isFullRest integer
events.UserCharacterLongRested = "character, isFullRest"

---@param userID integer
---@param userName string
---@param userProfileID string
events.UserConnected = "userID, userName, userProfileID"

---@param userID integer
---@param userName string
---@param userProfileID string
events.UserDisconnected = "userID, userName, userProfileID"

---@param userID integer
---@param userEvent string
events.UserEvent = "userID, userEvent"

---@param sourceUserID integer
---@param targetUserID integer
---@param war integer
events.UserMakeWar = "sourceUserID, targetUserID, war"

---@param caster GUIDSTRING
---@param spell string
---@param spellType string
---@param spellElement string
---@param storyActionID integer
events.UsingSpell = "caster, spell, spellType, spellElement, storyActionID"

---@param caster GUIDSTRING
---@param x number
---@param y number
---@param z number
---@param spell string
---@param spellType string
---@param spellElement string
---@param storyActionID integer
events.UsingSpellAtPosition = "caster, x, y, z, spell, spellType, spellElement, storyActionID"

---@param caster GUIDSTRING
---@param spell string
---@param spellType string
---@param spellElement string
---@param trigger TRIGGER
---@param storyActionID integer
events.UsingSpellInTrigger = "caster, spell, spellType, spellElement, trigger, storyActionID"

---@param caster GUIDSTRING
---@param target GUIDSTRING
---@param spell string
---@param spellType string
---@param spellElement string
---@param storyActionID integer
events.UsingSpellOnTarget = "caster, target, spell, spellType, spellElement, storyActionID"

---@param caster GUIDSTRING
---@param target GUIDSTRING
---@param spell string
---@param spellType string
---@param spellElement string
---@param storyActionID integer
events.UsingSpellOnZoneWithTarget = "caster, target, spell, spellType, spellElement, storyActionID"

---@param bark VOICEBARKRESOURCE
---@param instanceID integer
events.VoiceBarkEnded = "bark, instanceID"

---@param bark VOICEBARKRESOURCE
events.VoiceBarkFailed = "bark"

---@param bark VOICEBARKRESOURCE
---@param instanceID integer
events.VoiceBarkStarted = "bark, instanceID"

---@param object GUIDSTRING
---@param isOnStageNow integer
events.WentOnStage = "object, isOnStageNow"

return M
