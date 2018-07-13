--[[----------------------------------------------------------------------
	Copyright (c) 2016-2018, Aelexe
	All rights reserved.
------------------------------------------------------------------------]]

KillCount = LibStub("AceAddon-3.0"):NewAddon("Kill Count", "AceConsole-3.0","AceEvent-3.0")

--[[----------------------------------------------------------------------
  ACE Functions
------------------------------------------------------------------------]]

function KillCount:OnInitialize()
  local defaults = {
    global = {
      version = 1,
      records = {
        --[[{
          name: Aelexe,
          realm: Frostmourne,
          type: "k" or "d"
          time: 0,
          zone: Highmountain
        }]]
        count = 0
      },
      scores = {
      }
    }
  }

  self.db = LibStub("AceDB-3.0"):New("KillCountDB", defaults)
end

--[[----------------------------------------------------------------------
  Main Functions
------------------------------------------------------------------------]]

---
-- Creates a score entry for the provided name-realm if it doesn't already exist, and then returns it.
function KillCount:getScoreEntry(name, realm)
  local concatName = KillCountPlayerName:joinName(name, realm);
  if(self.db.global.scores[concatName] == nil) then
    self.db.global.scores[concatName] = {kills = 0, deaths = 0};
  end
  return self.db.global.scores[concatName];
end

---
-- Adds a kill against a player.
function KillCount:addKill(name, realm)
  local score = self:getScoreEntry(name, realm);
  score.kills = score.kills + 1;
  local records = self.db.global.records;
  records[records.count + 1] = {
    name = name,
    realm = realm,
    type = "k",
    time = time(),
    zone = GetRealZoneText()
  }
  records.count = records.count + 1
end

---
-- Adds a death against a player.
function KillCount:addDeath(name, realm)
  local score = self:getScoreEntry(name, realm);
  score.deaths = score.deaths + 1;
  local records = self.db.global.records;
  records[records.count + 1] = {
    name = name,
    realm = realm,
    type = "d",
    time = time(),
    zone = GetRealZoneText()
  }
  records.count = records.count + 1
end

---
-- Returns the kills and deaths against a player.
function KillCount:getKD(name, realm)
  local concatName = KillCountPlayerName:joinName(name, realm);
  local score = KillCount.db.global.scores[concatName];
  if(score == nil) then
    return 0, 0;
  else
    return score.kills, score.deaths;
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
    local kills, deaths = KillCount:getKD(name, realm);
    -- If either are not 0, display the tooltip.
    if(kills ~= 0 or deaths ~= 0) then
      self:AddLine("K/D: |cff00F001" .. kills .. "|cffffffff / |cffFF0000" .. deaths);
      self:Show();
    end
  end
end

GameTooltip:HookScript("OnTooltipSetUnit", hook_OnTooltipSetUnit);
