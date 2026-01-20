MCH.minimap = MCH.minimap or {}

local minimap = MCH.minimap
local ldbIcon = nil
local ldbObject = nil
local ICON_PATH = "Interface\\Icons\\INV_Misc_ScrollRolled_01"

local function EnsureDB()
  if type(MacroCreatorHelperDB) ~= "table" then
    MacroCreatorHelperDB = {}
  end
  MacroCreatorHelperDB.minimap = MacroCreatorHelperDB.minimap or {}
  if MacroCreatorHelperDB.minimap.hide == nil then
    MacroCreatorHelperDB.minimap.hide = false
  end
  if MacroCreatorHelperDB.minimap.angle == nil then
    MacroCreatorHelperDB.minimap.angle = 225
  end
  if MacroCreatorHelperDB.minimap.minimapPos == nil then
    MacroCreatorHelperDB.minimap.minimapPos = MacroCreatorHelperDB.minimap.angle
  end
end

local function EnsureLDBMinimapIcon()
  if ldbIcon then
    return true
  end
  if not LibStub then
    return false
  end
  local LDB = LibStub("LibDataBroker-1.1", true)
  local LDBIcon = LibStub("LibDBIcon-1.0", true)
  if not LDB or not LDBIcon then
    return false
  end

  ldbIcon = LDBIcon
  ldbObject = LDB:NewDataObject("MacroCreatorHelper", {
    type = "launcher",
    text = "MacroCreatorHelper",
    icon = ICON_PATH,
    OnClick = function(_, button)
      if button == "LeftButton" and MCH and MCH.ui and MCH.ui.Toggle then
        MCH.ui.Toggle()
      end
    end,
    OnTooltipShow = function(tooltip)
      if not tooltip then
        return
      end
      tooltip:AddLine("MacroCreatorHelper")
      tooltip:AddLine("Click: open builder", 1, 1, 1)
      tooltip:AddLine("Drag: move icon", 1, 1, 1)
    end,
  })

  EnsureDB()
  if MacroCreatorHelperDB.minimap.minimapPos == nil then
    local angle = tonumber(MacroCreatorHelperDB.minimap.angle)
    if angle then
      MacroCreatorHelperDB.minimap.minimapPos = angle
    end
  end
  ldbIcon:Register("MacroCreatorHelper", ldbObject, MacroCreatorHelperDB.minimap)
  return true
end

local function UpdateMinimapButtonPosition()
  if not minimap.button or not Minimap or not MacroCreatorHelperDB or not MacroCreatorHelperDB.minimap then
    return
  end
  local angle = tonumber(MacroCreatorHelperDB.minimap.minimapPos)
    or tonumber(MacroCreatorHelperDB.minimap.angle)
    or 225
  local width = Minimap:GetWidth()
  local radius = ((width and width > 0) and (width / 2) or 70) + 6
  local angleRad = math.rad(angle)
  local x = math.cos(angleRad) * radius
  local y = math.sin(angleRad) * radius
  minimap.button:ClearAllPoints()
  minimap.button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function ApplyMinimapButtonLayout()
  if not minimap.button then
    return
  end
  local iconSize = 14
  local borderSize = iconSize + 20
  if minimap.button.icon then
    minimap.button.icon:ClearAllPoints()
    minimap.button.icon:SetPoint("CENTER", minimap.button, "CENTER", 0, 0)
    minimap.button.icon:SetSize(iconSize, iconSize)
  end
  if minimap.button.background then
    minimap.button.background:ClearAllPoints()
    minimap.button.background:SetPoint("CENTER", minimap.button.icon or minimap.button, "CENTER", 0, 0)
    minimap.button.background:SetSize(iconSize + 4, iconSize + 4)
  end
  if minimap.button.border then
    minimap.button.border:ClearAllPoints()
    minimap.button.border:SetPoint("CENTER", minimap.button.icon or minimap.button, "CENTER", 0, 0)
    minimap.button.border:SetSize(borderSize, borderSize)
  end
  local highlight = minimap.button:GetHighlightTexture()
  if highlight then
    highlight:ClearAllPoints()
    highlight:SetPoint("CENTER", minimap.button.icon or minimap.button, "CENTER", 0, 0)
    highlight:SetSize(borderSize, borderSize)
    highlight:SetBlendMode("ADD")
  end
end

local function SetMinimapButtonVisible(visible)
  if ldbIcon then
    if visible then
      ldbIcon:Show("MacroCreatorHelper")
    else
      ldbIcon:Hide("MacroCreatorHelper")
    end
    return
  end
  if not minimap.button then
    return
  end
  if visible then
    minimap.button:Show()
  else
    minimap.button:Hide()
  end
end

local function CreateMinimapButton()
  if minimap.button or ldbIcon then
    return minimap.button
  end

  EnsureDB()
  if EnsureLDBMinimapIcon() then
    SetMinimapButtonVisible(not MacroCreatorHelperDB.minimap.hide)
    return nil
  end

  local button = CreateFrame("Button", "MCH_MinimapButton", Minimap)
  minimap.button = button
  button:SetSize(32, 32)
  button:SetFrameStrata("MEDIUM")
  button:SetFrameLevel(8)
  button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  button:RegisterForClicks("LeftButtonUp")
  button:RegisterForDrag("LeftButton")

  local background = button:CreateTexture(nil, "BACKGROUND")
  background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  background:SetPoint("CENTER", button, "CENTER", 0, 0)
  background:SetSize(20, 20)
  button.background = background

  local icon = button:CreateTexture(nil, "ARTWORK")
  icon:SetTexture(ICON_PATH)
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  icon:SetPoint("CENTER", button, "CENTER", 0, 0)
  icon:SetSize(14, 14)
  button.icon = icon

  local border = button:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetPoint("TOPLEFT", button, "TOPLEFT", -6, 6)
  border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 6, -6)
  button.border = border

  local highlight = button:GetHighlightTexture()
  if highlight then
    highlight:SetBlendMode("ADD")
  end

  button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("MacroCreatorHelper")
    GameTooltip:AddLine("Click: open builder", 1, 1, 1)
    GameTooltip:AddLine("Drag: move icon", 1, 1, 1)
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  button:SetScript("OnClick", function(_, mouseButton)
    if mouseButton == "LeftButton" and MCH and MCH.ui and MCH.ui.Toggle then
      MCH.ui.Toggle()
    end
  end)

  button:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
      local cursorX, cursorY = GetCursorPosition()
      local scale = Minimap:GetEffectiveScale()
      cursorX = cursorX / scale
      cursorY = cursorY / scale
      local minimapX, minimapY = Minimap:GetCenter()
      local angle = math.deg(math.atan(cursorY - minimapY, cursorX - minimapX))
      if angle < 0 then
        angle = angle + 360
      end
      MacroCreatorHelperDB.minimap.angle = angle
      MacroCreatorHelperDB.minimap.minimapPos = angle
      UpdateMinimapButtonPosition()
    end)
  end)

  button:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
  end)

  ApplyMinimapButtonLayout()
  UpdateMinimapButtonPosition()
  SetMinimapButtonVisible(not MacroCreatorHelperDB.minimap.hide)
  return minimap.button
end

function minimap.Refresh()
  if ldbIcon and ldbIcon.Refresh and MacroCreatorHelperDB and MacroCreatorHelperDB.minimap then
    ldbIcon:Refresh("MacroCreatorHelper", MacroCreatorHelperDB.minimap)
  end
  UpdateMinimapButtonPosition()
end

function minimap.SetVisible(visible)
  SetMinimapButtonVisible(visible)
end

function minimap.Init()
  if not Minimap then
    return
  end
  CreateMinimapButton()
end
