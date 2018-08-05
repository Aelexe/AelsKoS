AelsKoSGUI = AelsKoS:NewModule("GUI");

local mainWindow
local scrollFrame
local scrollBar
local contentFrame
local scrollItems = {
  count = 0
}

local killData
local activeSortMode = ""
local sortFlag = true

function AelsKoSGUI:toggle()
  if mainWindow == nil or not mainWindow:IsShown() then
    self:show()
  else
    self:hide()
  end
end

function AelsKoSGUI:show()
  if mainWindow == nil then
    self:createGUI()
  end

  self:loadKillData()

  mainWindow:Show()
end

function AelsKoSGUI:hide()
  mainWindow:Hide()
end

function AelsKoSGUI:loadKillData()
  killData = {count = 0}

  for k, v in pairs(AelsKoS.db.global.stats) do
    local score = v.kills - v.deaths
    table.insert(killData, {name = k, kills = v.kills, deaths = v.deaths, score = score})
    killData.count = killData.count + 1
  end

  self:setScrollItems(killData)
end

function AelsKoSGUI:sortBy(sortMode)
  if sortMode == activeSortMode then
    sortFlag = not sortFlag
  else
    sortFlag = true
  end

  if sortMode == "name" then
    if(sortFlag) then
      table.sort(killData, function(a, b)
        return a.name < b.name
      end)
    else
      table.sort(killData, function(a, b)
        return a.name > b.name
      end)
    end
  elseif sortMode == "kills" or sortMode == "deaths" or sortMode == "score" then
    if(sortFlag) then
      table.sort(killData, function(a, b)
        return a[sortMode] > b[sortMode]
      end)
    else
      table.sort(killData, function(a, b)
        return a[sortMode] < b[sortMode]
      end)
    end
  end

  activeSortMode = sortMode
  self:setScrollItems(killData)
end

function AelsKoSGUI:createGUI()
  self:createMainWindow()
  self:createScrollFrame()
  self:createScrollContent()
end

function AelsKoSGUI:setScrollItems(items)
  for k, v in ipairs(items) do
    local item
    if(k > scrollItems.count) then
      item = self:createScrollItem()
    else
      item = scrollItems[k]
    end
    item:setText(v.name, v.kills, v.deaths, v.score)
    if v.score > 0 then
      item.text4:SetTextColor(0, 1, 0)
    elseif v.score < 0 then
      item.text4:SetTextColor(0.9, 0, 0)
    else
      item.text4:SetTextColor(1, 0.82, 0)
    end
  end

  contentFrame:SetHeight(16 * items.count)
end

function AelsKoSGUI:createMainWindow()
  mainWindow = CreateFrame("Frame", "AelsKoSMainWindow", UIParent)
  mainWindow:SetFrameStrata("DIALOG")
  mainWindow:SetToplevel(true)
  mainWindow:EnableMouse(true)
  mainWindow:SetMovable(true)
  mainWindow:SetClampedToScreen(true)
  mainWindow:SetWidth(384)
  mainWindow:SetHeight(512)

  mainWindow:SetPoint("TOP", 0, -50)
  mainWindow:Hide()
  mainWindow:SetScript('OnShow', function() PlaySound(SOUNDKIT.IG_MAINMENU_OPTION) end)
  mainWindow:SetScript('OnHide', function() PlaySound(SOUNDKIT.GS_TITLE_OPTION_EXIT) end)

  mainWindow:RegisterForDrag('LeftButton')
  mainWindow:SetScript('OnDragStart', function(f) f:StartMoving() end)
  mainWindow:SetScript('OnDragStop', function(f) f:StopMovingOrSizing() end)

  local closeButton = CreateFrame("Button", "AelsKoSCloseButton", mainWindow, "UIPanelCloseButton");
	closeButton:SetPoint("TOPRIGHT", mainWindow, -30, -8);

  local backgroundIconTexture = mainWindow:CreateTexture("AelsKoSIcon", "BACKGROUND");
	backgroundIconTexture:SetTexture("Interface\\FriendsFrame\\FriendsFrameScrollIcon");
	backgroundIconTexture:SetWidth(60);
	backgroundIconTexture:SetHeight(60);
	backgroundIconTexture:SetPoint("TOPLEFT", 7, -6);

  local backgroundTopLeft = mainWindow:CreateTexture("AelsKoSBGTL", "ARTWORK");
	backgroundTopLeft:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-TopLeft");
	backgroundTopLeft:SetWidth(256);
	backgroundTopLeft:SetHeight(256);
	backgroundTopLeft:SetPoint("TOPLEFT");

	local backgroundTopRight = mainWindow:CreateTexture("AelsKoSBGTR", "ARTWORK");
	backgroundTopRight:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-TopRight");
	backgroundTopRight:SetWidth(128);
	backgroundTopRight:SetHeight(256);
	backgroundTopRight:SetPoint("TOPRIGHT");

	local backgroundBottomLeft = mainWindow:CreateTexture("AelsKoSBGBL", "ARTWORK");
	backgroundBottomLeft:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-BottomLeft");
	backgroundBottomLeft:SetWidth(256);
	backgroundBottomLeft:SetHeight(256);
	backgroundBottomLeft:SetPoint("BOTTOMLEFT");

	local backgroundBottomRight = mainWindow:CreateTexture("AelsKoSBGBR", "ARTWORK");
	backgroundBottomRight:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-BottomRight");
	backgroundBottomRight:SetWidth(128);
	backgroundBottomRight:SetHeight(256);
	backgroundBottomRight:SetPoint("BOTTOMRIGHT");

  local title = mainWindow:CreateFontString("ARTWORK")
  title:SetFontObject("GameFontNormal")
  title:SetPoint("TOP", mainWindow, "TOP", 0, -18)
  title:SetText("AelsKoS")
end

function AelsKoSGUI:createScrollFrame()
  scrollFrame = CreateFrame("ScrollFrame", "AelsKoSInnerFrame", mainWindow)
  scrollFrame:EnableMouse(true)
  scrollFrame:SetPoint("TOPLEFT", 19, -95)
  scrollFrame:SetPoint("BOTTOMRIGHT", -43, 81)
  scrollFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
  scrollFrame:SetBackdropBorderColor(0.4, 0.4, 0.4)
  scrollFrame:EnableMouseWheel(true)
  scrollFrame:SetScript("OnMouseWheel", ScrollFrame_OnMouseWheel)

  scrollBar = CreateFrame("Slider", "TestScroll", scrollFrame, "UIPanelScrollBarTemplate")

	scrollBar:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", -6, -20)
  scrollBar:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", -6, 20)
	scrollBar:SetMinMaxValues(0, 1000)
	scrollBar:SetValueStep(16)
	scrollBar:SetValue(0)
	scrollBar:SetWidth(16)
  scrollBar:SetHeight(50)
  scrollBar:SetScript("OnValueChanged", ScrollBar_OnScrollValueChanged)
  scrollBar.scrollStep = 16

  local scrollbg = scrollBar:CreateTexture(nil, "BACKGROUND")
	scrollbg:SetAllPoints(scrollBar)
	scrollbg:SetColorTexture(0, 0, 0, 0.4)

  local testTab = CreateFrame("Button", "TestTab", scrollFrame, "WhoFrameColumnHeaderTemplate")
  testTab:SetPoint("BOTTOMLEFT", scrollFrame, "TOPLEFT")
  WhoFrameColumn_SetWidth(testTab, 162)
  testTab:SetText("Name")
  testTab:EnableMouse(true)
  testTab:SetScript("OnClick", function() AelsKoSGUI:sortBy("name") end)

  local testTab2 = CreateFrame("Button", "TestTab2", scrollFrame, "WhoFrameColumnHeaderTemplate")
  testTab2:SetPoint("TOPLEFT", testTab, "TOPRIGHT")
  WhoFrameColumn_SetWidth(testTab2, 46)
  testTab2:SetText("Kills")
  testTab2:EnableMouse(true)
  testTab2:SetScript("OnClick", function() AelsKoSGUI:sortBy("kills") end)

  local testTab3 = CreateFrame("Button", "TestTab3", scrollFrame, "WhoFrameColumnHeaderTemplate")
  testTab3:SetPoint("TOPLEFT", testTab2, "TOPRIGHT")
  WhoFrameColumn_SetWidth(testTab3, 46)
  testTab3:SetText("Deaths")
  testTab3:EnableMouse(true)
  testTab3:SetScript("OnClick", function() AelsKoSGUI:sortBy("deaths") end)

  local testTab4 = CreateFrame("Button", "TestTab4", scrollFrame, "WhoFrameColumnHeaderTemplate")
  testTab4:SetPoint("TOPLEFT", testTab3, "TOPRIGHT")
  WhoFrameColumn_SetWidth(testTab4, 46)
  testTab4:SetText("Score")
  testTab4:EnableMouse(true)
  testTab4:SetScript("OnClick", function() AelsKoSGUI:sortBy("score") end)
end

function AelsKoSGUI:createScrollContent()
  contentFrame = CreateFrame("Frame", "Hywqe", scrollFrame)
  scrollFrame:SetScrollChild(contentFrame)
  contentFrame:SetPoint("TOPLEFT", 0, 0)
  contentFrame:SetPoint("TOPRIGHT", 0, 0)
  contentFrame:SetHeight(400)
end

function AelsKoSGUI:createScrollItem()
  local itemIndex = scrollItems.count + 1
  scrollItems.count = itemIndex

  local listButton = CreateFrame("Button", "ScrollItem" .. itemIndex, contentFrame);
  listButton:SetWidth(298);
  listButton:SetHeight(16);
  listButton:RegisterForClicks("LeftButtonUp", "RightButtonUp");
  listButton:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight");
  listButton:GetHighlightTexture():SetBlendMode("ADD");

  if itemIndex == 1 then
    listButton:SetPoint("TOPLEFT", 0, 0);
  else
    listButton:SetPoint("TOPLEFT", scrollItems[itemIndex - 1].button, "BOTTOMLEFT");
  end

  local listButtonText = listButton:CreateFontString("ScrollItemButton" .. itemIndex .. "Text1", "BORDER");
  listButtonText:SetWidth(142);
  listButtonText:SetHeight(14);
  listButtonText:SetJustifyH("LEFT");
  listButtonText:SetJustifyV("MIDDLE");
  listButtonText:SetFontObject("GameFontNormalSmall");
  listButtonText:SetPoint("TOPLEFT", listButton, "TOPLEFT", 10, 0);
  listButtonText:SetText("Aelexe-Frostmourne")

  local listButtonText2 = listButton:CreateFontString("ScrollItemButton" .. itemIndex .. "Text2", "BORDER");
  listButtonText2:SetWidth(36);
  listButtonText2:SetHeight(14);
  listButtonText2:SetJustifyH("RIGHT");
  listButtonText2:SetJustifyV("MIDDLE");
  listButtonText2:SetFontObject("GameFontNormalSmall");
  listButtonText2:SetPoint("TOPLEFT", listButtonText, "TOPRIGHT", 15, 0);
  listButtonText2:SetText("3")
  listButtonText2:SetTextColor(0, 1, 0)

  local listButtonText3 = listButton:CreateFontString("ScrollItemButton" .. itemIndex .. "Text3", "BORDER");
  listButtonText3:SetWidth(36);
  listButtonText3:SetHeight(14);
  listButtonText3:SetJustifyH("RIGHT");
  listButtonText3:SetJustifyV("MIDDLE");
  listButtonText3:SetFontObject("GameFontNormalSmall");
  listButtonText3:SetPoint("TOPLEFT", listButtonText2, "TOPRIGHT", 10, 0);
  listButtonText3:SetText("1")
  listButtonText3:SetTextColor(0.9, 0, 0)

  local listButtonText4 = listButton:CreateFontString("ScrollItemButton" .. itemIndex .. "Text4", "BORDER");
  listButtonText4:SetWidth(36);
  listButtonText4:SetHeight(14);
  listButtonText4:SetJustifyH("RIGHT");
  listButtonText4:SetJustifyV("MIDDLE");
  listButtonText4:SetFontObject("GameFontNormalSmall");
  listButtonText4:SetPoint("TOPLEFT", listButtonText3, "TOPRIGHT", 10, 0);
  listButtonText4:SetText("2")
  listButtonText4:SetTextColor(0, 1, 0)

  scrollItems[itemIndex] = {
    button = listButton,
    text1 = listButtonText,
    text2 = listButtonText2,
    text3 = listButtonText3,
    text4 = listButtonText4,
    setText = function(self, content1, content2, content3, content4)
      self.text1:SetText(content1)
      self.text2:SetText(content2)
      self.text3:SetText(content3)
      self.text4:SetText(content4)
    end
  }

  return scrollItems[itemIndex]
end

function ScrollBar_OnScrollValueChanged(frame, value)
  local difference = contentFrame:GetHeight() - scrollFrame:GetHeight()
  local scrollAmount = difference * (value / 1000)
  contentFrame:SetPoint("TOPLEFT", 0, scrollAmount)
  contentFrame:SetPoint("TOPRIGHT", 0, scrollAmount)
end

function ScrollFrame_OnMouseWheel(frame, value)
  scrollBar:SetValue(scrollBar:GetValue() + (scrollBar.scrollStep * -value))
end
