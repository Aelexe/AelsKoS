AelsKoSCombatParser = AelsKoS:NewModule("CombatParser", "AceEvent-3.0")

-- Tables used to record latest kills to prevent duplicate kill events from autoattacks coinciding with spells.
AelsKoSCombatParser.kills = {}
AelsKoSCombatParser.deaths = {}

-- Masks used to determine what a source or destination object is.
local meMask = bit.bor(COMBATLOG_OBJECT_TYPE_PLAYER, COMBATLOG_OBJECT_CONTROL_PLAYER, COMBATLOG_OBJECT_REACTION_FRIENDLY, COMBATLOG_OBJECT_AFFILIATION_MINE)
local myPetMask = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_REACTION_FRIENDLY, COMBATLOG_OBJECT_CONTROL_PLAYER, COMBATLOG_OBJECT_TYPE_OBJECT, COMBATLOG_OBJECT_TYPE_GUARDIAN, COMBATLOG_OBJECT_TYPE_PET)
local enemyPlayerMask = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MASK, COMBATLOG_OBJECT_REACTION_MASK, COMBATLOG_OBJECT_CONTROL_PLAYER, COMBATLOG_OBJECT_TYPE_PLAYER) -- Actually matches any player I think.

local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo

---
-- Event handler for COMBAT_LOG_EVENT_UNFILTERED. Every combat event comes in here, unfiltered.
-- Some form of devil magic occurs within.
function AelsKoSCombatParser:COMBAT_LOG_EVENT_UNFILTERED()
  local timeStamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()

  local isDamageEvent = string.find(event, "_DAMAGE")
  local isPlayerEvent = sourceGUID == UnitGUID("player") or destGUID == UnitGUID("player")

  -- Discard any irrelevant events.
  if not isDamageEvent --[[or not isPlayerEvent]] then
    return
  end

  -- Get extra parameters.
  local offset = 12
  local spellId
  local amount
  local overkill

  if(string.find(event, "SPELL_") or string.find(event, "RANGE_")) then
		spellId = select(offset, CombatLogGetCurrentEventInfo())
		offset = offset + 3
  else
    spellId = 0
	end

  amount, overkill = select(offset, CombatLogGetCurrentEventInfo())

  -- Discard if it isn't a kill, determined by overkill amount.
  if overkill == -1 then
    return
  end
  -- If it was our pet doing the killing.
  if(CombatLog_Object_IsA(sourceFlags, myPetMask) or CombatLog_Object_IsA(sourceFlags, meMask)) then
    -- And if it was a player killed.
    if(CombatLog_Object_IsA(destFlags, enemyPlayerMask) and self:notDuplicateKill(destGUID)) then
      AelsKoS:addKill(destGUID, time(), C_Map.GetBestMapForUnit("player"), spellId)
    end
  elseif (destGUID == UnitGUID("player")) then -- Otherwise, if it was us doing the dying.
    -- If a player killed us.
    if(CombatLog_Object_IsA(sourceFlags, enemyPlayerMask) and self:notDuplicateDeath(sourceGUID)) then
      AelsKoS:addDeath(sourceGUID, time(), C_Map.GetBestMapForUnit("player"), spellId)
    end
    -- Ideally I'd capture pet kills too but there's literally no way to do that.
  end
end

function AelsKoSCombatParser:notDuplicateKill(guid)
  if self.kills[guid] == nil or time() ~= self.kills[guid] then
    self.kills[guid] = time
    return true
  else
    return false
  end
end

function AelsKoSCombatParser:notDuplicateDeath(guid)
  if self.deaths[guid] == nil or time() ~= self.deaths[guid] then
    self.deaths[guid] = time
    return true
  else
    return false
  end
end

AelsKoSCombatParser:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
