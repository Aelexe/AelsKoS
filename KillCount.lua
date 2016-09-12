local killCount = CreateFrame("Frame", modName, UIParent); -- Everything happens in the frame~.
local tooltip = GameTooltip; -- Shorter reference to GameTooltip, because I'm pedantic.
local KillCount_Record; -- Persisted variable containing everything.

-- Handy event pass through function. Any registered events are passed to the function of the same name.
killCount:SetScript("OnEvent",function(self,event,...) self[event](self,event,...); end);

----
-- Variable Load
----

---
-- Event handler for ADDON_LOADED. Listens for KillCount and then loads the KillCount_Data variable, 
-- or initialises it if it doesn't already exist.
function killCount:ADDON_LOADED(event, addonName)
  -- Listen for our addon.
  if(addonName == "KillCount") then
    -- If our variable doesn't exist, make it.
    if(KillCount_Data == nil) then
      KillCount_Data = {version = 0, record = {}}; -- Version to support data migration in the future.
    else
      -- Here's where data migration will inevitably occur.
    end
    KillCount_Record = KillCount_Data["record"];
  end
  -- Remove event and event handler.
  self:UnregisterEvent(event);
  self[event] = nil;
end

----
-- Util
----

---
-- Splits a player name into the name and realm components.
-- If the player is on the same realm as the player their realm is added instead.
local function splitName(name)
  local playerName, playerRealm = string.split("-", name);
  if(playerRealm == nil) then
    playerRealm = GetRealmName();
  end
  return playerName, playerRealm;
end

local function joinName(name, realm)
  return name .. "-" .. realm;
end

----
-- Data (AKA Murder Recording)
----

---
-- Creates a record for the provided name-realm if it doesn't already exist,
-- and then returns it.
local function createRecord(name, realm)
  local concatName = joinName(name, realm);
  if(KillCount_Record[concatName] == nil) then
    KillCount_Record[concatName] = {kills = 0, deaths = 0};
  end
  return KillCount_Record[concatName];
end

---
-- Adds a kill against the provided player and realm.
local function addKill(name, realm)
  local record = createRecord(name, realm);
  record["kills"] = record["kills"] + 1;
end

---
-- Adds a death against the provided player and realm.
local function addDeath(name, realm)
  local record = createRecord(name, realm);
  record["deaths"] = record["deaths"] + 1;
end

---
-- Returns the kills and deaths against the provided player and realm.
local function getKD(name, realm)
  local concatName = joinName(name, realm);
  local record = KillCount_Record[concatName];
  if(record == nil) then
    return 0, 0;
  else
    return record["kills"], record["deaths"];
  end
end

----
-- Combat Log (AKA Murder Stream)
-- Everything in this section is horrific. Blame WoW's combat log API and be thankful this isn't backwards compatible.
----

-- Masks used to determine what a source or destination object is.
local myPetMask = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_REACTION_FRIENDLY, COMBATLOG_OBJECT_CONTROL_PLAYER, COMBATLOG_OBJECT_TYPE_OBJECT, COMBATLOG_OBJECT_TYPE_GUARDIAN, COMBATLOG_OBJECT_TYPE_PET);
local enemyPlayerMask = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MASK, COMBATLOG_OBJECT_REACTION_MASK, COMBATLOG_OBJECT_CONTROL_PLAYER, COMBATLOG_OBJECT_TYPE_PLAYER); -- Actually matches any player I think.

---
-- Event handler for COMBAT_LOG_EVENT_UNFILTERED. Every combat event comes in here, unfiltered.
-- Some form of devil magic occurs within.
function killCount:COMBAT_LOG_EVENT_UNFILTERED(_, timeStamp, event, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags, _, _, swingOverkill, _, _, spellOverkill)
  -- Discard any irrelevant events.
  if(event ~= "PARTY_KILL" and event ~= "SWING_DAMAGE" and event ~= "RANGE_DAMAGE" and event ~= "SPELL_DAMAGE" and event ~= "SPELL_PERIODIC_DAMAGE") then
    return;
  end
  -- If a player within our party scored a kill (we only care about ourselves).
  if(event == "PARTY_KILL") then
    -- If it was us doing the killing (as our pet doesn't get kill events), and the enemy was a player.
    if(sourceGUID == UnitGUID("player") and CombatLog_Object_IsA(destFlags, enemyPlayerMask)) then
      local name, realm = splitName(destName);
      addKill(name, realm);
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
        local name, realm = splitName(destName);
        addKill(name, realm);
      end
    elseif (destGUID == UnitGUID("player")) then -- Otherwise, if it was us doing the dying.
      -- If a player killed us.
      if(CombatLog_Object_IsA(sourceFlags, enemyPlayerMask)) then
        local name, realm = splitName(sourceName);
        addDeath(name, realm);
      end
      -- Ideally I'd capture pet kills too but there's literally no way to do that.
    end
  end
end

----
-- Tooltip
----

---
-- Hook function for OnTooltipSetUnit, which is called whenever the user mouses over anything in game.
local function hook_OnTooltipSetUnit(self, ...)
  -- Get the name and unit of what is being moused over.
  local name, unit = self:GetUnit();
  -- And if it's a player.
  if(UnitIsPlayer(unit)) then
    -- Get its name and realm.
    local _, realm = UnitName(unit);
    if(realm == nil) then
      realm = GetRealmName();
    end
    -- Get the kills and deaths for that player.
    local kills, deaths = getKD(name, realm);
    -- If either are not 0, display the tooltip.
    if(kills ~= 0 or deaths ~= 0) then
      tooltip:AddLine("K/D: |cff00F001" .. kills .. "|cffffffff / |cffFF0000" .. deaths);
      tooltip:Show();
    end
  end
end

----
-- Events and Hooks
----

killCount:RegisterEvent("ADDON_LOADED");
killCount:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
tooltip:HookScript("OnTooltipSetUnit", hook_OnTooltipSetUnit);