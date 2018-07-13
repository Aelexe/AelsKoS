KillCountCombatParser = KillCount:NewModule("CombatParser", "AceEvent-3.0")

-- Masks used to determine what a source or destination object is.
local myPetMask = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_REACTION_FRIENDLY, COMBATLOG_OBJECT_CONTROL_PLAYER, COMBATLOG_OBJECT_TYPE_OBJECT, COMBATLOG_OBJECT_TYPE_GUARDIAN, COMBATLOG_OBJECT_TYPE_PET);
local enemyPlayerMask = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MASK, COMBATLOG_OBJECT_REACTION_MASK, COMBATLOG_OBJECT_CONTROL_PLAYER, COMBATLOG_OBJECT_TYPE_PLAYER); -- Actually matches any player I think.

---
-- Event handler for COMBAT_LOG_EVENT_UNFILTERED. Every combat event comes in here, unfiltered.
-- Some form of devil magic occurs within.
function KillCountCombatParser:COMBAT_LOG_EVENT_UNFILTERED(_, timeStamp, event, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags, _, _, swingOverkill, _, _, spellOverkill)
  -- Discard any irrelevant events.
  if(event ~= "PARTY_KILL" and event ~= "SWING_DAMAGE" and event ~= "RANGE_DAMAGE" and event ~= "SPELL_DAMAGE" and event ~= "SPELL_PERIODIC_DAMAGE") then
    return;
  end
  -- If a player within our party scored a kill (we only care about ourselves).
  if(event == "PARTY_KILL") then
    -- If it was us doing the killing (as our pet doesn't get kill events), and the enemy was a player.
    if(sourceGUID == UnitGUID("player") and CombatLog_Object_IsA(destFlags, enemyPlayerMask)) then
      local name, realm = KillCountPlayerName:splitName(destName);
      KillCount:addKill(name, realm);
    end
  elseif(event == "SWING_DAMAGE" or event == "RANGE_DAMAGE" or event == "SPELL_DAMAGE" or event == "SPELL_PERIODIC_DAMAGE") then
    -- Discard if it isn't a kill, determined by overkill amount.
    if(event == "SWING_DAMAGE" and (swingOverkill == nil or tonumber(swingOverkill) == -1)) then
      return;
    elseif((event == "RANGE_DAMAGE" or event == "SPELL_DAMAGE" or event == "SPELL_PERIODIC_DAMAGE") and (spellOverkill == nil or tonumber(spellOverkill) == -1)) then
      return;
    end
    -- If it was our pet doing the killing.
    if(CombatLog_Object_IsA(sourceFlags, myPetMask)) then
      -- And if it was a player killed.
      if(CombatLog_Object_IsA(destFlags, enemyPlayerMask)) then
        local name, realm = KillCountPlayerName:splitName(destName);
        KillCount:addKill(name, realm);
      end
    elseif (destGUID == UnitGUID("player")) then -- Otherwise, if it was us doing the dying.
      -- If a player killed us.
      if(CombatLog_Object_IsA(sourceFlags, enemyPlayerMask)) then
        local name, realm = KillCountPlayerName:splitName(sourceName);
        KillCount:addDeath(name, realm);
      end
      -- Ideally I'd capture pet kills too but there's literally no way to do that.
    end
  end
end

KillCountCombatParser:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
