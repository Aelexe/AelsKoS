KillCountPlayerName = KillCount:NewModule("PlayerName")

---
-- Splits a player name into the name and realm components.
-- If the player is on the same realm as the player their realm is added instead.
function KillCountPlayerName:splitName(name)
  local playerName, playerRealm = string.split("-", name);
  if(playerRealm == nil) then
    playerRealm = GetRealmName();
  end
  return playerName, playerRealm;
end

function KillCountPlayerName:joinName(name, realm)
  return name .. "-" .. realm;
end
