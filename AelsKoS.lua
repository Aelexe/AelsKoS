--[[----------------------------------------------------------------------
	Copyright (c) 2016-2018, Aelexe
	All rights reserved.
------------------------------------------------------------------------]]

AelsKoS = LibStub("AceAddon-3.0"):NewAddon("Kill Count", "AceConsole-3.0", "AceEvent-3.0")

--[[----------------------------------------------------------------------
  ACE Functions
------------------------------------------------------------------------]]

function AelsKoS:OnInitialize()
  local defaults = {
    global = {
      -- version = 1, Needs to be set outside of defaults.
      log = {
        --[[{
          name: Aelexe,
          realm: Frostmourne,
          type: "k" or "d",
          time: 0,
          zone: 630,
          spellId: 196819, Used to remove any kills caused by friendly fire that shouldn't count.
        },]]
        count = 0
      },
      stats = {
        --[["Aelexe-Frostmourne" = {
          kills = 1,
          deaths = 0,
        },]]
      },
      playerdb = {
        players = {
          --[["Player-3725-0A9929AE" = {
            name = "Aelexe",
            classId = "ROGUE",
            raceId = "Worgen"
          }]]
        },
        count = 0
      },
      settings = {
        debug = false
      }
    }
  }

  self.db = LibStub("AceDB-3.0"):New("AelsKoSDB", defaults)

  -- Setting version outside of defaults, because defaults don't stick unless changed.
  if(self.db.global.version == nil) then
    self.db.global.version = 1
  end

  -- Create shortcuts to the DB.
  self.settings = self.db.global.settings

end

--[[----------------------------------------------------------------------
  Main Functions
------------------------------------------------------------------------]]

---
-- Adds a kill against a player.
function AelsKoS:addKill(guid, time, zone, spellId)
  self:_addKillDeath("kill", guid, time, zone, spellId)
end

---
-- Adds a death against a player.
function AelsKoS:addDeath(guid, time, zone, spellId)
  self:_addKillDeath("death", guid, time, zone, spellId)
end

function AelsKoS:_addKillDeath(type, guid, time, zone, spellId)
  local className, classId, raceName, raceId, gender, name, realm = GetPlayerInfoByGUID(guid)
  if realm == "" then
    realm = GetRealmName()
  end

  self:_debugKillDeath(type, name, realm, spellId)

  self:_addPlayer(guid, name, realm, classId, raceId)

  local stat = self:getStatEntry(name, realm);
  if type == "kill" then
    stat.kills = stat.kills + 1;
    self:createKillRecord(name, realm, time, zone, spellId)
  else
    stat.deaths = stat.deaths + 1;
    self:createDeathRecord(name, realm, time, zone, spellId)
  end
end

function AelsKoS:getRecord(index)
  return self.db.global.log[index]
end

function AelsKoS:createKillRecord(name, realm, time, zone, spellId)
  self:createRecord(name, realm, "k", time, zone, spellId)
end

function AelsKoS:createDeathRecord(name, realm, time, zone, spellId)
  self:createRecord(name, realm, "d", time, zone, spellId)
end

function AelsKoS:createRecord(name, realm, type, time, zone, spellId)
  local log = self.db.global.log;
  log[log.count + 1] = {
    name = name,
    realm = realm,
    type = type,
    time = time,
    zone = zone,
    spellId = spellId
  }
  log.count = log.count + 1
end

function AelsKoS:_addPlayer(guid, name, realm, classId, raceId)
  local players = self.db.global.playerdb.players
  if players[guid] == nil then
    players[guid] = {
      name = name,
      realm = realm,
      classId = classId,
      raceId = raceId
    }
  end
end

---
-- Creates a stat entry for the provided name-realm if it doesn't already exist, and then returns it.
function AelsKoS:getStatEntry(name, realm)
  local concatName = AelsKoSPlayerName:joinName(name, realm);
  if(self.db.global.stats[concatName] == nil) then
    self.db.global.stats[concatName] = {kills = 0, deaths = 0};
  end
  return self.db.global.stats[concatName];
end

---
-- Returns the kills and deaths against a player.
function AelsKoS:getKD(name, realm)
  local concatName = AelsKoSPlayerName:joinName(name, realm);
  local stat = AelsKoS.db.global.stats[concatName];
  if(stat == nil) then
    return 0, 0;
  else
    return stat.kills, stat.deaths;
  end
end

--[[----------------------------------------------------------------------
  Tooltip Functions
------------------------------------------------------------------------]]

---
-- Hook function for OnTooltipSetUnit, which is called whenever the player mouses over anything in game.
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
    local kills, deaths = AelsKoS:getKD(name, realm);
    -- If either are not 0, display the tooltip.
    if(kills ~= 0 or deaths ~= 0) then
      self:AddLine("K/D: |cff00F001" .. kills .. "|cffffffff / |cffFF0000" .. deaths);
      self:Show();
    end
  end
end

GameTooltip:HookScript("OnTooltipSetUnit", hook_OnTooltipSetUnit);

--[[----------------------------------------------------------------------
  Slash Command Functions
------------------------------------------------------------------------]]

AelsKoS:RegisterChatCommand("aelskos", "slashCommand")

function AelsKoS:slashCommand(input)
  if input == "debug" then
    self:_toggleDebug()
  end
end

--[[----------------------------------------------------------------------
  Debug Functions
------------------------------------------------------------------------]]

function AelsKoS:_toggleDebug()
  self.settings.debug = not self.settings.debug
  local debugStatus
  if self.settings.debug then
    debugStatus = "enabled"
  else
    debugStatus = "disabled"
  end
  self:Print(string.format("Debug mode %s.", debugStatus))
end

function AelsKoS:debug(message)
  if self.settings.debug then
    self:Print(message)
  end
end

function AelsKoS:_debugKillDeath(type, name, realm, spellId)
  if not self.settings.debug then
    return
  end
  local spellName
  if spellId == 0 then
    spellName = "Auto Attack"
  else
    spellName = GetSpellInfo(spellId)
  end
  self:debug(string.format("Adding %s for %s-%s(%s)", type, name, realm, spellName))
end
