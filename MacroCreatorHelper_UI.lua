local util = MCH.util
local builder = MCH.builder
local macro = MCH.macro

MCH.ui = MCH.ui or {}
local ui = MCH.ui

local function SetStatus(text)
  if ui.status then
    ui.status:SetText(text or "")
  end
end

local UpdateShowTooltipLayout

local function ApplyShowTooltipFromBody(body)
  if not ui.showTooltipCheck then
    return
  end
  local show = false
  local value = ""
  if body and body ~= "" then
    local firstLine = body:match("^[^\r\n]+")
    if firstLine then
      local lower = firstLine:lower()
      if lower:match("^#showtooltip") then
        show = true
        local arg = firstLine:match("^#showtooltip%s+(.+)$")
        if arg then
          value = util.Trim(arg)
        end
      end
    end
  end
  ui.showTooltipCheck:SetChecked(show)
  if ui.showTooltipBox then
    ui.showTooltipBox:SetText(value)
  end
  UpdateShowTooltipLayout()
end

local function GetMacroEntries()
  local entries = {}
  if not GetNumMacros or not GetMacroInfo then
    return entries, 0
  end
  local maxGlobal = MAX_ACCOUNT_MACROS or 18
  local maxChar = MAX_CHARACTER_MACROS or 18
  local total = maxGlobal + maxChar
  for index = 1, total do
    local name = GetMacroInfo(index)
    if name and name ~= "" then
      entries[#entries + 1] = { name = name, index = index }
    end
  end
  return entries, maxGlobal
end

local function BuildMacroListItems(entries, maxGlobal)
  local items = {}
  items[#items + 1] = { label = "Select Macro", value = "" }
  for _, entry in ipairs(entries) do
    local prefix = entry.index > maxGlobal and "[Char] " or "[Global] "
    items[#items + 1] = {
      label = prefix .. entry.name,
      value = entry.index,
      name = entry.name,
    }
  end
  items[#items + 1] = { label = "Create New Macro...", value = "__new" }
  return items
end

local function GenerateNewMacroName()
  local entries = GetMacroEntries()
  local existing = {}
  for _, entry in ipairs(entries) do
    existing[entry.name] = true
  end
  local base = "New Macro"
  if not existing[base] then
    return base
  end
  local i = 1
  while existing[base .. " " .. i] do
    i = i + 1
  end
  return base .. " " .. i
end

local function LoadMacroByIndex(index)
  if not index or not GetMacroInfo then
    return
  end
  local name, icon, body = GetMacroInfo(index)
  if not name or name == "" then
    return
  end
  ui.nameBox:SetText(name)
  ui.bodyBox:SetText(body or "")
  local texture = icon or "Interface\\Icons\\INV_Misc_QuestionMark"
  ui.icon:SetTexture(texture)
  ui.iconTexture = texture
  local maxGlobal = ui.macroMaxGlobal or (MAX_ACCOUNT_MACROS or 18)
  if ui.charOnly then
    ui.charOnly:SetChecked(index > maxGlobal)
  end
  if ui.newMacroLabel then
    ui.newMacroLabel:SetText("")
  end
  ApplyShowTooltipFromBody(body or "")
  SetStatus("Loaded macro: " .. name)
end

local function HandleMacroSelection(value)
  if not value or value == "" then
    if ui.newMacroLabel then
      ui.newMacroLabel:SetText("")
    end
    return
  end
  if value == "__new" then
    local newName = GenerateNewMacroName()
    ui.nameBox:SetText(newName)
    ui.bodyBox:SetText("")
    local texture = "Interface\\Icons\\INV_Misc_QuestionMark"
    ui.icon:SetTexture(texture)
    ui.iconTexture = texture
    if ui.newMacroLabel then
      ui.newMacroLabel:SetText("New macro: " .. newName)
    end
    if ui.showTooltipCheck then
      ui.showTooltipCheck:SetChecked(false)
      if ui.showTooltipBox then
        ui.showTooltipBox:SetText("")
      end
      UpdateShowTooltipLayout()
    end
    if ui.macroListDrop then
      UIDropDownMenu_SetText(ui.macroListDrop, newName)
    end
    SetStatus("Ready to create: " .. newName)
    return
  end
  local index = tonumber(value)
  if index then
    LoadMacroByIndex(index)
  end
end

local function RefreshMacroListDropdown(selectedName)
  if not ui.macroListDrop then
    return
  end
  local entries, maxGlobal = GetMacroEntries()
  ui.macroMaxGlobal = maxGlobal
  ui.macroListItems = BuildMacroListItems(entries, maxGlobal)
  UIDropDownMenu_Initialize(ui.macroListDrop, function(_, level)
    for _, item in ipairs(ui.macroListItems) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = item.label
      info.value = item.value
      info.func = function()
        UIDropDownMenu_SetSelectedValue(ui.macroListDrop, item.value)
        UIDropDownMenu_SetText(ui.macroListDrop, item.label)
        HandleMacroSelection(item.value)
      end
      UIDropDownMenu_AddButton(info, level)
    end
  end)
  local selectedLabel = nil
  local selectedValue = nil
  if selectedName and selectedName ~= "" then
    for _, item in ipairs(ui.macroListItems) do
      if item.name == selectedName then
        selectedLabel = item.label
        selectedValue = item.value
        break
      end
    end
  end
  if selectedLabel then
    UIDropDownMenu_SetSelectedValue(ui.macroListDrop, selectedValue)
    UIDropDownMenu_SetText(ui.macroListDrop, selectedLabel)
  else
    UIDropDownMenu_SetSelectedValue(ui.macroListDrop, ui.macroListItems[1].value)
    UIDropDownMenu_SetText(ui.macroListDrop, ui.macroListItems[1].label)
  end
end

local function LayoutGroups()
  if not ui.left or not ui.leftGroups then
    return
  end
  local previous = nil
  for _, group in ipairs(ui.leftGroups) do
    if group:IsShown() then
      group:ClearAllPoints()
      if previous then
        group:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -12)
      else
        group:SetPoint("TOPLEFT", ui.left, "TOPLEFT", 0, 0)
      end
      previous = group
    end
  end
end

local function SetGroupVisible(group, visible)
  if not group then
    return
  end
  if group.SetShown then
    group:SetShown(visible)
  elseif visible then
    group:Show()
  else
    group:Hide()
  end
end

local function UpdateEquipGroupLayout()
  if not ui.equipGroup or not ui.equippedBox or not ui.equippedCheck or not ui.noequippedCheck then
    return
  end
  local showItem = ui.equippedCheck:GetChecked() or ui.noequippedCheck:GetChecked()
  if ui.equipItemLabel then
    ui.equipItemLabel:SetShown(showItem)
  end
  ui.equippedBox:SetShown(showItem)
  if ui.equipSlotLabel then
    ui.equipSlotLabel:SetShown(showItem)
  end
  if ui.equipSlotDrop then
    ui.equipSlotDrop:SetShown(showItem)
  end
  local expandedHeight = ui.equipSlotDrop and 88 or 56
  ui.equipGroup:SetHeight(showItem and expandedHeight or 32)
  if not showItem and ui.equipSlotDrop and ui.equipSlotItems then
    UIDropDownMenu_SetSelectedValue(ui.equipSlotDrop, ui.equipSlotItems[1].value)
    UIDropDownMenu_SetText(ui.equipSlotDrop, ui.equipSlotItems[1].label)
  end
  LayoutGroups()
end

UpdateShowTooltipLayout = function()
  if not ui.showTooltipGroup or not ui.showTooltipCheck then
    return
  end
  local show = ui.showTooltipCheck:GetChecked()
  if ui.showTooltipLabel then
    ui.showTooltipLabel:SetShown(show)
  end
  if ui.showTooltipBox then
    ui.showTooltipBox:SetShown(show)
  end
  if ui.showTooltipHint then
    ui.showTooltipHint:SetShown(show)
  end
  ui.showTooltipGroup:SetHeight(show and 62 or 24)
  LayoutGroups()
end

local function UpdateConditionalSections()
  local isSequence = ui.actionType == "castsequence"
  SetGroupVisible(ui.actionGroup, not isSequence)
  SetGroupVisible(ui.actionSlotGroup, ui.actionType == "equipslot")
  SetGroupVisible(ui.sequenceGroup, isSequence)
  SetGroupVisible(ui.resetGroup, isSequence)
  local showEquip = ui.actionType == "use" or ui.actionType == "equip" or ui.actionType == "equipslot"
  SetGroupVisible(ui.equipGroup, showEquip)
  if ui.actionType ~= "equipslot" and ui.actionSlotBox then
    ui.actionSlotBox:SetText("")
  end
  if not showEquip and ui.equippedCheck and ui.noequippedCheck and ui.equippedBox then
    ui.equippedCheck:SetChecked(false)
    ui.noequippedCheck:SetChecked(false)
    ui.equippedBox:SetText("")
  end
  UpdateEquipGroupLayout()
end

local function BuildShowTooltipLine()
  if not ui.showTooltipCheck or not ui.showTooltipCheck:GetChecked() then
    return nil
  end
  local value = ui.showTooltipBox and util.Trim(ui.showTooltipBox:GetText()) or ""
  if value ~= "" then
    return "#showtooltip " .. value
  end
  return "#showtooltip"
end

local function NormalizeBodyWithShowTooltip(body, showLine)
  local lines = {}
  for line in body:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end
  if showLine then
    if lines[1] and lines[1]:lower():match("^#showtooltip") then
      lines[1] = showLine
    else
      table.insert(lines, 1, showLine)
    end
  else
    if lines[1] and lines[1]:lower():match("^#showtooltip") then
      table.remove(lines, 1)
    end
  end
  return table.concat(lines, "\n")
end

local function AppendToBody(line)
  local body = ui.bodyBox:GetText()
  if body == "" then
    ui.bodyBox:SetText(line)
  else
    ui.bodyBox:SetText(body .. "\n" .. line)
  end
  local text = ui.bodyBox:GetText()
  ui.bodyBox:SetCursorPosition(text:len())
end

local function SetActionType(value)
  ui.actionType = value
  UpdateConditionalSections()
end

local function SetTargetUnit(value)
  ui.targetUnit = value
end

function ui.CollectState()
  local equippedMode = nil
  local equippedItem = ""
  if ui.equipGroup and ui.equipGroup:IsShown() and ui.equippedCheck and ui.noequippedCheck and ui.equippedBox then
    if ui.equippedCheck:GetChecked() then
      equippedMode = "equipped"
    elseif ui.noequippedCheck:GetChecked() then
      equippedMode = "noequipped"
    end
    equippedItem = ui.equippedBox:GetText()
  end
  return {
    actionType = ui.actionType,
    action = ui.actionBox:GetText(),
    actionSlot = ui.actionSlotBox and ui.actionSlotBox:GetText() or "",
    sequence = ui.sequenceBox:GetText(),
    targetUnit = ui.targetUnit,
    modShift = ui.modShift:GetChecked(),
    modCtrl = ui.modCtrl:GetChecked(),
    modAlt = ui.modAlt:GetChecked(),
    stanceMode = ui.stanceMode or "none",
    combatMode = ui.combatMode or "none",
    reactionMode = ui.reactionMode or "none",
    equippedMode = equippedMode,
    equippedItem = equippedItem,
    resetTarget = ui.resetTarget:GetChecked(),
    resetCombat = ui.resetCombat:GetChecked(),
    resetShift = ui.resetShift:GetChecked(),
    resetCtrl = ui.resetCtrl:GetChecked(),
    resetAlt = ui.resetAlt:GetChecked(),
    resetTime = ui.resetTime:GetText(),
  }
end

local function GetSpellBookNameIcon(slot, bookType)
  local name = nil
  local icon = nil
  if GetSpellBookItemName then
    name = GetSpellBookItemName(slot, bookType)
  elseif SpellBook_GetSpellBookItemName then
    name = SpellBook_GetSpellBookItemName(slot, bookType)
  end
  if GetSpellBookItemTexture then
    icon = GetSpellBookItemTexture(slot, bookType)
  end
  return name, icon
end

local function GetDropText()
  local infoType, id, subType = GetCursorInfo()
  if infoType == "spellbook" then
    local bookType = subType or (SpellBookFrame and SpellBookFrame.bookType) or BOOKTYPE_SPELL
    local name, icon = GetSpellBookNameIcon(id, bookType)
    if type(name) == "string" and name ~= "" then
      return name, icon
    end
  elseif infoType == "spell" then
    if SpellBookFrame and SpellBookFrame:IsShown() then
      local bookType = (SpellBookFrame and SpellBookFrame.bookType) or BOOKTYPE_SPELL
      local name, icon = GetSpellBookNameIcon(id, bookType)
      if type(name) == "string" and name ~= "" then
        return name, icon
      end
    end
    local name, _, icon = GetSpellInfo(id)
    return name, icon
  elseif infoType == "item" then
    local name, _, _, _, _, _, _, _, _, icon = GetItemInfo(id)
    if not name then
      name = "item:" .. id
    end
    return name, icon
  end
  return nil
end

local function AppendToSequence(text)
  local current = util.Trim(ui.sequenceBox:GetText())
  if current == "" then
    ui.sequenceBox:SetText(text)
  else
    ui.sequenceBox:SetText(current .. ", " .. text)
  end
end

local function HandleDrop(intoSequence)
  local text, icon = GetDropText()
  if not text then
    return
  end
  if intoSequence then
    AppendToSequence(text)
    if ui.actionType ~= "castsequence" then
      UIDropDownMenu_SetSelectedValue(ui.actionTypeDrop, "castsequence")
      UIDropDownMenu_SetText(ui.actionTypeDrop, "Castsequence")
      SetActionType("castsequence")
    end
  else
    ui.actionBox:SetText(text)
  end
  if icon then
    ui.icon:SetTexture(icon)
    ui.iconTexture = icon
  end
  ClearCursor()
end

local function GetSpellNameFromSpellbook(buttonFrame)
  local bookType = (SpellBookFrame and SpellBookFrame.bookType) or BOOKTYPE_SPELL
  local slot = buttonFrame and buttonFrame.spellBookSlot
  if not slot then
    local id = buttonFrame and buttonFrame:GetID()
    local page = SpellBookFrame and SpellBookFrame.page or 1
    if id and SPELLS_PER_PAGE then
      slot = SPELLS_PER_PAGE * (page - 1) + id
    end
  end
  if not slot then
    return nil
  end
  local name = nil
  if GetSpellBookItemName then
    name = GetSpellBookItemName(slot, bookType)
  elseif SpellBook_GetSpellBookItemName then
    name = SpellBook_GetSpellBookItemName(slot, bookType)
  end
  if type(name) == "string" and name ~= "" then
    return name
  end
  return nil
end

local function HandleSpellbookShiftClick(buttonFrame, mouseButton)
  if mouseButton and mouseButton ~= "LeftButton" then
    return
  end
  if not ui.frame or not ui.frame:IsShown() then
    return
  end
  if ui.actionType ~= "castsequence" then
    return
  end
  if not IsShiftKeyDown() then
    return
  end
  local name = GetSpellNameFromSpellbook(buttonFrame)
  if not name then
    return
  end
  local now = GetTime and GetTime() or 0
  if ui.lastShiftSpell == name and ui.lastShiftTime and now - ui.lastShiftTime < 0.1 then
    return
  end
  ui.lastShiftSpell = name
  ui.lastShiftTime = now
  AppendToSequence(name)
end

local function TryHookSpellbook()
  if ui.spellbookHooked then
    return
  end
  local hooked = false
  if type(SpellButton_OnModifiedClick) == "function" then
    hooksecurefunc("SpellButton_OnModifiedClick", HandleSpellbookShiftClick)
    hooked = true
  end
  if type(SpellButton_OnClick) == "function" then
    hooksecurefunc("SpellButton_OnClick", HandleSpellbookShiftClick)
    hooked = true
  end
  if hooked then
    ui.spellbookHooked = true
  end
end

local function SetupSpellbookHook()
  TryHookSpellbook()
  if ui.spellbookHooked or ui.spellbookHookFrame then
    return
  end
  local hookFrame = CreateFrame("Frame")
  ui.spellbookHookFrame = hookFrame
  hookFrame:RegisterEvent("PLAYER_LOGIN")
  hookFrame:RegisterEvent("ADDON_LOADED")
  hookFrame:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName ~= "Blizzard_SpellbookUI" then
      return
    end
    TryHookSpellbook()
    if ui.spellbookHooked then
      hookFrame:UnregisterAllEvents()
    end
  end)
end

local function HandleTooltipDrop()
  local text = GetDropText()
  if not text then
    return
  end
  if ui.showTooltipCheck and not ui.showTooltipCheck:GetChecked() then
    ui.showTooltipCheck:SetChecked(true)
    UpdateShowTooltipLayout()
  end
  if ui.showTooltipBox then
    ui.showTooltipBox:SetText(text)
  end
  ClearCursor()
end

function ui.Toggle()
  if not ui.frame then
    return
  end
  if ui.frame:IsShown() then
    ui.frame:Hide()
  else
    RefreshMacroListDropdown()
    ui.frame:Show()
  end
end

local function CreateMainFrame()
  if ui.frame then
    return
  end

  local frame = CreateFrame("Frame", "MCH_MainFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  ui.frame = frame
  frame:SetSize(760, 560)
  frame:SetPoint("CENTER")
  if frame.SetBackdrop then
    frame:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true,
      tileSize = 32,
      edgeSize = 32,
      insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.85)
  end
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:Hide()

  frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  frame.title:SetPoint("TOP", frame, "TOP", 0, -12)
  frame.title:SetText("MacroCreatorHelper")

  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)

  local left = CreateFrame("Frame", nil, frame)
  left:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -36)
  left:SetSize(340, 480)
  ui.left = left
  ui.leftGroups = {}

  local right = CreateFrame("Frame", nil, frame)
  right:SetPoint("TOPLEFT", frame, "TOPLEFT", 380, -36)
  right:SetSize(340, 480)

  local function CreateLeftGroup(height)
    local group = CreateFrame("Frame", nil, left)
    group:SetSize(320, height)
    ui.leftGroups[#ui.leftGroups + 1] = group
    return group
  end

  local function SlotLabel(globalKey, fallback)
    local value = _G and _G[globalKey]
    if type(value) == "string" and value ~= "" then
      return value
    end
    return fallback
  end

  local showTooltipGroup = CreateLeftGroup(24)
  ui.showTooltipGroup = showTooltipGroup
  ui.showTooltipCheck = CreateFrame("CheckButton", nil, showTooltipGroup, "UICheckButtonTemplate")
  ui.showTooltipCheck:SetPoint("TOPLEFT", showTooltipGroup, "TOPLEFT", 0, -2)
  util.SetCheckboxLabel(ui.showTooltipCheck, "Show Tooltip")

  ui.showTooltipLabel = showTooltipGroup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ui.showTooltipLabel:SetPoint("TOPLEFT", ui.showTooltipCheck, "BOTTOMLEFT", 2, -4)
  ui.showTooltipLabel:SetText("Tooltip Target")

  ui.showTooltipBox = util.CreateEditBox(showTooltipGroup, 190, 20)
  ui.showTooltipBox:SetPoint("LEFT", ui.showTooltipLabel, "RIGHT", 8, -1)

  ui.showTooltipHint = showTooltipGroup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ui.showTooltipHint:SetPoint("TOPLEFT", ui.showTooltipLabel, "BOTTOMLEFT", 0, -4)
  ui.showTooltipHint:SetText("Empty uses the action to execute.")

  ui.showTooltipCheck:SetScript("OnClick", function()
    UpdateShowTooltipLayout()
  end)

  local nameGroup = CreateLeftGroup(88)
  local nameLabel = nameGroup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  nameLabel:SetPoint("TOPLEFT", nameGroup, "TOPLEFT", 0, 0)
  nameLabel:SetText("Macro Name")

  ui.nameBox = util.CreateEditBox(nameGroup, 170, 20)
  ui.nameBox:SetPoint("TOPLEFT", nameGroup, "TOPLEFT", 110, -4)

  ui.charOnly = CreateFrame("CheckButton", nil, nameGroup, "UICheckButtonTemplate")
  ui.charOnly:SetPoint("LEFT", ui.nameBox, "RIGHT", 8, 0)
  util.SetCheckboxLabel(ui.charOnly, "Char")

  local macroListLabel = nameGroup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  macroListLabel:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -10)
  macroListLabel:SetText("Existing Macros")

  ui.macroListDrop = CreateFrame("Frame", nil, nameGroup, "UIDropDownMenuTemplate")
  UIDropDownMenu_SetWidth(ui.macroListDrop, 180)
  ui.macroListDrop:SetPoint("TOPLEFT", macroListLabel, "BOTTOMLEFT", -16, -2)

  ui.newMacroLabel = nameGroup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ui.newMacroLabel:SetPoint("TOPLEFT", ui.macroListDrop, "BOTTOMLEFT", 16, -2)
  ui.newMacroLabel:SetText("")

  local objectiveGroup = CreateLeftGroup(40)
  local actionTypeLabel = objectiveGroup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  actionTypeLabel:SetPoint("TOPLEFT", objectiveGroup, "TOPLEFT", 0, 0)
  actionTypeLabel:SetText("Action Type")

  local actionTypeItems = {
    { label = "Cast", value = "cast" },
    { label = "Use", value = "use" },
    { label = "Equip", value = "equip" },
    { label = "Equip Slot", value = "equipslot" },
    { label = "Castsequence", value = "castsequence" },
  }

  ui.actionType = "cast"
  ui.actionTypeDrop = util.CreateDropdown(objectiveGroup, 140, actionTypeItems, SetActionType)
  ui.actionTypeDrop:SetPoint("TOPLEFT", actionTypeLabel, "TOPRIGHT", 8, -6)

  ui.actionGroup = CreateLeftGroup(36)
  local actionLabel = ui.actionGroup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  actionLabel:SetPoint("TOPLEFT", ui.actionGroup, "TOPLEFT", 0, 0)
  actionLabel:SetText("Action")

  ui.actionBox = util.CreateEditBox(ui.actionGroup, 190, 20)
  ui.actionBox:SetPoint("TOPLEFT", ui.actionGroup, "TOPLEFT", 110, -4)

  ui.iconButton = CreateFrame("Button", nil, ui.actionGroup)
  ui.iconButton:SetSize(32, 32)
  ui.iconButton:SetPoint("LEFT", ui.actionBox, "RIGHT", 8, 0)
  ui.icon = ui.iconButton:CreateTexture(nil, "ARTWORK")
  ui.icon:SetAllPoints(ui.iconButton)
  ui.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
  ui.iconTexture = "Interface\\Icons\\INV_Misc_QuestionMark"

  ui.actionSlotGroup = CreateLeftGroup(40)
  local actionSlotLabel = ui.actionSlotGroup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  actionSlotLabel:SetPoint("TOPLEFT", ui.actionSlotGroup, "TOPLEFT", 0, 0)
  actionSlotLabel:SetText("Equip Slot")

  ui.actionSlotBox = util.CreateEditBox(ui.actionSlotGroup, 52, 20)
  ui.actionSlotBox:SetPoint("TOPLEFT", actionSlotLabel, "BOTTOMLEFT", -2, -2)

  local actionSlotItems = {
    { label = "Custom", value = "" },
    { label = SlotLabel("HEADSLOT", "Head"), value = "1" },
    { label = SlotLabel("NECKSLOT", "Neck"), value = "2" },
    { label = SlotLabel("SHOULDERSLOT", "Shoulder"), value = "3" },
    { label = SlotLabel("SHIRTSLOT", "Shirt"), value = "4" },
    { label = SlotLabel("CHESTSLOT", "Chest"), value = "5" },
    { label = SlotLabel("WAISTSLOT", "Waist"), value = "6" },
    { label = SlotLabel("LEGSSLOT", "Legs"), value = "7" },
    { label = SlotLabel("FEETSLOT", "Feet"), value = "8" },
    { label = SlotLabel("WRISTSLOT", "Wrist"), value = "9" },
    { label = SlotLabel("HANDSSLOT", "Hands"), value = "10" },
    { label = SlotLabel("FINGER0SLOT", "Finger 1"), value = "11" },
    { label = SlotLabel("FINGER1SLOT", "Finger 2"), value = "12" },
    { label = SlotLabel("TRINKET0SLOT", "Trinket 1"), value = "13" },
    { label = SlotLabel("TRINKET1SLOT", "Trinket 2"), value = "14" },
    { label = SlotLabel("BACKSLOT", "Back"), value = "15" },
    { label = SlotLabel("MAINHANDSLOT", "Main Hand"), value = "16" },
    { label = SlotLabel("SECONDARYHANDSLOT", "Off Hand"), value = "17" },
    { label = SlotLabel("RANGEDSLOT", "Ranged"), value = "18" },
    { label = SlotLabel("TABARDSLOT", "Tabard"), value = "19" },
  }

  ui.actionSlotItems = actionSlotItems
  ui.actionSlotDrop = util.CreateDropdown(ui.actionSlotGroup, 140, actionSlotItems, function(value)
    ui.actionSlotBox:SetText(value or "")
  end)
  ui.actionSlotDrop:SetPoint("LEFT", ui.actionSlotBox, "RIGHT", 8, 0)

  ui.sequenceGroup = CreateLeftGroup(120)

  local sequenceLabel = ui.sequenceGroup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  sequenceLabel:SetPoint("TOPLEFT", ui.sequenceGroup, "TOPLEFT", 0, 0)
  sequenceLabel:SetText("Sequence")

  ui.sequenceScroll, ui.sequenceBox = util.CreateScrollEditBox(ui.sequenceGroup, 210, 60)
  ui.sequenceScroll:SetPoint("TOPLEFT", ui.sequenceGroup, "TOPLEFT", 110, -4)

  ui.sequenceDropLabel = ui.sequenceGroup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ui.sequenceDropLabel:SetPoint("TOPLEFT", ui.sequenceGroup, "TOPLEFT", 0, -72)
  ui.sequenceDropLabel:SetText("Add Spell")

  ui.sequenceDropBox = util.CreateEditBox(ui.sequenceGroup, 210, 20)
  ui.sequenceDropBox:SetPoint("TOPLEFT", ui.sequenceGroup, "TOPLEFT", 110, -76)
  ui.sequenceDropBox:SetScript("OnEditFocusGained", function(self)
    self:ClearFocus()
  end)
  ui.sequenceDropBox:SetScript("OnTextChanged", function(self, userInput)
    if userInput and self:GetText() ~= "" then
      self:SetText("")
    end
  end)

  ui.sequenceDropHint = ui.sequenceDropBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  ui.sequenceDropHint:SetPoint("LEFT", ui.sequenceDropBox, "LEFT", 6, 0)
  ui.sequenceDropHint:SetText("Drag & drop spell")

  ui.resetGroup = CreateLeftGroup(70)

  local resetLabel = ui.resetGroup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  resetLabel:SetPoint("TOPLEFT", ui.resetGroup, "TOPLEFT", 0, 0)
  resetLabel:SetText("Reset")

  ui.resetTarget = CreateFrame("CheckButton", nil, ui.resetGroup, "UICheckButtonTemplate")
  ui.resetTarget:SetPoint("TOPLEFT", resetLabel, "BOTTOMLEFT", 0, -4)
  util.SetCheckboxLabel(ui.resetTarget, "Target")

  ui.resetCombat = CreateFrame("CheckButton", nil, ui.resetGroup, "UICheckButtonTemplate")
  ui.resetCombat:SetPoint("LEFT", ui.resetTarget, "RIGHT", 8, 0)
  util.SetCheckboxLabel(ui.resetCombat, "Combat")

  ui.resetShift = CreateFrame("CheckButton", nil, ui.resetGroup, "UICheckButtonTemplate")
  ui.resetShift:SetPoint("TOPLEFT", ui.resetTarget, "BOTTOMLEFT", 0, -2)
  util.SetCheckboxLabel(ui.resetShift, "Shift")

  ui.resetCtrl = CreateFrame("CheckButton", nil, ui.resetGroup, "UICheckButtonTemplate")
  ui.resetCtrl:SetPoint("LEFT", ui.resetShift, "RIGHT", 8, 0)
  util.SetCheckboxLabel(ui.resetCtrl, "Ctrl")

  ui.resetAlt = CreateFrame("CheckButton", nil, ui.resetGroup, "UICheckButtonTemplate")
  ui.resetAlt:SetPoint("LEFT", ui.resetCtrl, "RIGHT", 8, 0)
  util.SetCheckboxLabel(ui.resetAlt, "Alt")

  local resetTimeLabel = ui.resetGroup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  resetTimeLabel:SetPoint("TOPLEFT", ui.resetShift, "BOTTOMLEFT", 2, -6)
  resetTimeLabel:SetText("Seconds")

  ui.resetTime = util.CreateEditBox(ui.resetGroup, 50, 20)
  ui.resetTime:SetPoint("LEFT", resetTimeLabel, "RIGHT", 6, 0)

  local targetGroup = CreateLeftGroup(66)
  local targetLabel = targetGroup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  targetLabel:SetPoint("TOPLEFT", targetGroup, "TOPLEFT", 0, 0)
  targetLabel:SetText("Target")

  local targetItems = {
    { label = "None", value = "none" },
    { label = "target", value = "target" },
    { label = "focus", value = "focus" },
    { label = "mouseover", value = "mouseover" },
    { label = "player", value = "player" },
    { label = "pet", value = "pet" },
  }

  ui.targetUnit = "none"
  ui.targetDrop = util.CreateDropdown(targetGroup, 140, targetItems, SetTargetUnit)
  ui.targetDrop:SetPoint("TOPLEFT", targetLabel, "TOPRIGHT", 8, -6)

  local reactionItems = {
    { label = "None", value = "none" },
    { label = "Friendly", value = "help" },
    { label = "Hostile", value = "harm" },
  }

  local reactionLabel = targetGroup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  reactionLabel:SetPoint("TOPLEFT", ui.targetDrop, "BOTTOMLEFT", 16, -2)
  reactionLabel:SetText("Reaction")

  ui.reactionMode = "none"
  ui.reactionDrop = util.CreateDropdown(targetGroup, 120, reactionItems, function(value)
    ui.reactionMode = value
  end)
  ui.reactionDrop:SetPoint("TOPLEFT", reactionLabel, "BOTTOMLEFT", -16, -2)

  local condGroup = CreateLeftGroup(78)
  local condLabel = condGroup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  condLabel:SetPoint("TOPLEFT", condGroup, "TOPLEFT", 0, 0)
  condLabel:SetText("Modifiers")

  ui.modShift = CreateFrame("CheckButton", nil, condGroup, "UICheckButtonTemplate")
  ui.modShift:SetPoint("TOPLEFT", condLabel, "BOTTOMLEFT", 0, -2)
  util.SetCheckboxLabel(ui.modShift, "Shift")

  ui.modCtrl = CreateFrame("CheckButton", nil, condGroup, "UICheckButtonTemplate")
  ui.modCtrl:SetPoint("LEFT", ui.modShift, "RIGHT", 8, 0)
  util.SetCheckboxLabel(ui.modCtrl, "Ctrl")

  ui.modAlt = CreateFrame("CheckButton", nil, condGroup, "UICheckButtonTemplate")
  ui.modAlt:SetPoint("LEFT", ui.modCtrl, "RIGHT", 8, 0)
  util.SetCheckboxLabel(ui.modAlt, "Alt")

  local stanceItems = {
    { label = "None", value = "none" },
    { label = "Any Stance/Form", value = "stance" },
    { label = "Stance/Form 1", value = "stance:1" },
    { label = "Stance/Form 2", value = "stance:2" },
    { label = "Stance/Form 3", value = "stance:3" },
    { label = "Stance/Form 4", value = "stance:4" },
    { label = "Stance/Form 5", value = "stance:5" },
  }

  local combatItems = {
    { label = "None", value = "none" },
    { label = "In Combat", value = "combat" },
    { label = "Out of Combat", value = "nocombat" },
  }

  local stanceLabel = condGroup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  stanceLabel:SetPoint("TOPLEFT", ui.modShift, "BOTTOMLEFT", 0, -6)
  stanceLabel:SetText("Stance/Form")

  local combatLabel = condGroup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  combatLabel:SetPoint("TOPLEFT", stanceLabel, "TOPLEFT", 160, 0)
  combatLabel:SetText("Combat")

  ui.stanceMode = "none"
  ui.stanceDrop = util.CreateDropdown(condGroup, 110, stanceItems, function(value)
    ui.stanceMode = value
  end)
  ui.stanceDrop:SetPoint("TOPLEFT", stanceLabel, "BOTTOMLEFT", -16, -2)

  ui.combatMode = "none"
  ui.combatDrop = util.CreateDropdown(condGroup, 100, combatItems, function(value)
    ui.combatMode = value
  end)
  ui.combatDrop:SetPoint("TOPLEFT", combatLabel, "BOTTOMLEFT", -16, -2)

  ui.equipGroup = CreateLeftGroup(56)
  local equipLabel = ui.equipGroup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  equipLabel:SetPoint("TOPLEFT", ui.equipGroup, "TOPLEFT", 0, 0)
  equipLabel:SetText("Equipment")

  ui.equippedCheck = CreateFrame("CheckButton", nil, ui.equipGroup, "UICheckButtonTemplate")
  ui.equippedCheck:SetPoint("TOPLEFT", equipLabel, "BOTTOMLEFT", 0, -2)
  util.SetCheckboxLabel(ui.equippedCheck, "Equipped")

  ui.noequippedCheck = CreateFrame("CheckButton", nil, ui.equipGroup, "UICheckButtonTemplate")
  ui.noequippedCheck:SetPoint("LEFT", ui.equippedCheck, "RIGHT", 8, 0)
  util.SetCheckboxLabel(ui.noequippedCheck, "Not Equipped")

  local equipBoxWidth = 150
  local equipSlotWidth = 120

  ui.equipItemLabel = ui.equipGroup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ui.equipItemLabel:SetPoint("TOPLEFT", ui.equippedCheck, "BOTTOMLEFT", 2, -6)
  ui.equipItemLabel:SetText("Item/Type")

  ui.equipSlotLabel = ui.equipGroup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ui.equipSlotLabel:SetPoint("TOPLEFT", ui.equipItemLabel, "TOPLEFT", equipBoxWidth + 24, 0)
  ui.equipSlotLabel:SetText("Slot List")

  ui.equippedBox = util.CreateEditBox(ui.equipGroup, equipBoxWidth, 20)
  ui.equippedBox:SetPoint("TOPLEFT", ui.equipItemLabel, "BOTTOMLEFT", -2, -2)

  local equipSlotItems = {
    { label = "Custom", value = "" },
    { label = "Shield", value = "shield" },
    { label = SlotLabel("HEADSLOT", "Head"), value = SlotLabel("HEADSLOT", "Head") },
    { label = SlotLabel("NECKSLOT", "Neck"), value = SlotLabel("NECKSLOT", "Neck") },
    { label = SlotLabel("SHOULDERSLOT", "Shoulder"), value = SlotLabel("SHOULDERSLOT", "Shoulder") },
    { label = SlotLabel("BACKSLOT", "Back"), value = SlotLabel("BACKSLOT", "Back") },
    { label = SlotLabel("CHESTSLOT", "Chest"), value = SlotLabel("CHESTSLOT", "Chest") },
    { label = SlotLabel("WRISTSLOT", "Wrist"), value = SlotLabel("WRISTSLOT", "Wrist") },
    { label = SlotLabel("HANDSSLOT", "Hands"), value = SlotLabel("HANDSSLOT", "Hands") },
    { label = SlotLabel("WAISTSLOT", "Waist"), value = SlotLabel("WAISTSLOT", "Waist") },
    { label = SlotLabel("LEGSSLOT", "Legs"), value = SlotLabel("LEGSSLOT", "Legs") },
    { label = SlotLabel("FEETSLOT", "Feet"), value = SlotLabel("FEETSLOT", "Feet") },
    { label = SlotLabel("FINGER0SLOT", "Finger 1"), value = SlotLabel("FINGER0SLOT", "Finger 1") },
    { label = SlotLabel("FINGER1SLOT", "Finger 2"), value = SlotLabel("FINGER1SLOT", "Finger 2") },
    { label = SlotLabel("TRINKET0SLOT", "Trinket 1"), value = SlotLabel("TRINKET0SLOT", "Trinket 1") },
    { label = SlotLabel("TRINKET1SLOT", "Trinket 2"), value = SlotLabel("TRINKET1SLOT", "Trinket 2") },
    { label = SlotLabel("MAINHANDSLOT", "Main Hand"), value = SlotLabel("MAINHANDSLOT", "Main Hand") },
    { label = SlotLabel("SECONDARYHANDSLOT", "Off Hand"), value = SlotLabel("SECONDARYHANDSLOT", "Off Hand") },
    { label = SlotLabel("RANGEDSLOT", "Ranged"), value = SlotLabel("RANGEDSLOT", "Ranged") },
    { label = SlotLabel("SHIRTSLOT", "Shirt"), value = SlotLabel("SHIRTSLOT", "Shirt") },
    { label = SlotLabel("TABARDSLOT", "Tabard"), value = SlotLabel("TABARDSLOT", "Tabard") },
  }

  ui.equipSlotItems = equipSlotItems
  ui.equipSlotDrop = util.CreateDropdown(ui.equipGroup, equipSlotWidth, equipSlotItems, function(value)
    if value == "" then
      ui.equippedBox:SetText("")
      return
    end
    if value then
      ui.equippedBox:SetText(value)
    end
  end)
  ui.equipSlotDrop:SetPoint("TOPLEFT", ui.equipSlotLabel, "BOTTOMLEFT", -16, -2)

  ui.equippedCheck:SetScript("OnClick", function(self)
    if self:GetChecked() then
      ui.noequippedCheck:SetChecked(false)
    end
    UpdateEquipGroupLayout()
  end)

  ui.noequippedCheck:SetScript("OnClick", function(self)
    if self:GetChecked() then
      ui.equippedCheck:SetChecked(false)
    end
    UpdateEquipGroupLayout()
  end)

  local bodyLabel = right:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  bodyLabel:SetPoint("TOPLEFT", right, "TOPLEFT", 0, -4)
  bodyLabel:SetText("Macro Body")

  ui.bodyScroll, ui.bodyBox = util.CreateScrollEditBox(right, 300, 360)
  ui.bodyScroll:SetPoint("TOPLEFT", right, "TOPLEFT", 0, -24)

  ui.status = right:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  ui.status:SetPoint("TOPLEFT", ui.bodyScroll, "BOTTOMLEFT", 0, -10)
  ui.status:SetText("")

  ui.addLineButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  ui.addLineButton:SetSize(110, 24)
  ui.addLineButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 18)
  ui.addLineButton:SetText("Add Line")

  ui.clearButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  ui.clearButton:SetSize(80, 24)
  ui.clearButton:SetPoint("LEFT", ui.addLineButton, "RIGHT", 8, 0)
  ui.clearButton:SetText("Clear")

  ui.saveButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  ui.saveButton:SetSize(140, 24)
  ui.saveButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 18)
  ui.saveButton:SetText("Create/Update")

  UIDropDownMenu_SetSelectedValue(ui.actionTypeDrop, actionTypeItems[1].value)
  UIDropDownMenu_SetText(ui.actionTypeDrop, actionTypeItems[1].label)
  UIDropDownMenu_SetSelectedValue(ui.targetDrop, targetItems[1].value)
  UIDropDownMenu_SetText(ui.targetDrop, targetItems[1].label)
  if ui.equipSlotDrop and ui.equipSlotItems then
    UIDropDownMenu_SetSelectedValue(ui.equipSlotDrop, ui.equipSlotItems[1].value)
    UIDropDownMenu_SetText(ui.equipSlotDrop, ui.equipSlotItems[1].label)
  end
  if ui.actionSlotDrop and ui.actionSlotItems then
    UIDropDownMenu_SetSelectedValue(ui.actionSlotDrop, ui.actionSlotItems[1].value)
    UIDropDownMenu_SetText(ui.actionSlotDrop, ui.actionSlotItems[1].label)
  end
  if ui.reactionDrop then
    UIDropDownMenu_SetSelectedValue(ui.reactionDrop, reactionItems[1].value)
    UIDropDownMenu_SetText(ui.reactionDrop, reactionItems[1].label)
  end
  if ui.stanceDrop then
    UIDropDownMenu_SetSelectedValue(ui.stanceDrop, stanceItems[1].value)
    UIDropDownMenu_SetText(ui.stanceDrop, stanceItems[1].label)
  end
  if ui.combatDrop then
    UIDropDownMenu_SetSelectedValue(ui.combatDrop, combatItems[1].value)
    UIDropDownMenu_SetText(ui.combatDrop, combatItems[1].label)
  end

  SetActionType(actionTypeItems[1].value)
  SetTargetUnit(targetItems[1].value)
  UpdateShowTooltipLayout()
  RefreshMacroListDropdown()
  SetupSpellbookHook()

  ui.actionBox:SetScript("OnReceiveDrag", function()
    HandleDrop(false)
  end)
  ui.actionBox:SetScript("OnMouseUp", function(_, button)
    if button == "LeftButton" then
      HandleDrop(false)
    end
  end)

  ui.sequenceBox:SetScript("OnReceiveDrag", function()
    HandleDrop(true)
  end)
  ui.sequenceBox:SetScript("OnMouseUp", function(_, button)
    if button == "LeftButton" then
      HandleDrop(true)
    end
  end)

  ui.sequenceDropBox:SetScript("OnReceiveDrag", function()
    HandleDrop(true)
  end)
  ui.sequenceDropBox:SetScript("OnMouseUp", function(_, button)
    if button == "LeftButton" then
      HandleDrop(true)
    end
  end)

  ui.iconButton:SetScript("OnReceiveDrag", function()
    HandleDrop(false)
  end)
  ui.iconButton:SetScript("OnMouseUp", function(_, button)
    if button == "LeftButton" then
      HandleDrop(false)
    end
  end)

  ui.showTooltipBox:SetScript("OnReceiveDrag", function()
    HandleTooltipDrop()
  end)
  ui.showTooltipBox:SetScript("OnMouseUp", function(_, button)
    if button == "LeftButton" then
      HandleTooltipDrop()
    end
  end)

  ui.addLineButton:SetScript("OnClick", function()
    local state = ui.CollectState()
    local line, err = builder.BuildLine(state)
    if not line then
      SetStatus(err or "")
      util.Print(err or "Unable to build line.")
      return
    end
    AppendToBody(line)
    SetStatus("Line added.")
  end)

  ui.clearButton:SetScript("OnClick", function()
    ui.bodyBox:SetText("")
    SetStatus("Cleared.")
  end)

  ui.saveButton:SetScript("OnClick", function()
    local name = util.Trim(ui.nameBox:GetText())
    if name == "" then
      SetStatus("Macro name required.")
      util.Print("Macro name required.")
      return
    end
    local body = util.Trim(ui.bodyBox:GetText())
    if body == "" then
      SetStatus("Macro body is empty.")
      util.Print("Macro body is empty.")
      return
    end
    body = NormalizeBodyWithShowTooltip(body, BuildShowTooltipLine())
    if body == "" then
      SetStatus("Macro body is empty.")
      util.Print("Macro body is empty.")
      return
    end

    local icon = ui.iconTexture or "Interface\\Icons\\INV_Misc_QuestionMark"
    local perChar = ui.charOnly:GetChecked()
    local ok, status = macro.Save(name, icon, body, perChar)
    if ok then
      if status == "updated" then
        SetStatus("Macro updated.")
        util.Print("Macro updated: " .. name)
      else
        SetStatus("Macro created.")
        util.Print("Macro created: " .. name)
      end
      RefreshMacroListDropdown(name)
    else
      SetStatus(status or "Failed to create macro.")
      util.Print(status or "Failed to create macro.")
    end
  end)
end

CreateMainFrame()
