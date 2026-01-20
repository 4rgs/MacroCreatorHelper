MCH = MCH or {}
MCH.util = MCH.util or {}

function MCH.util.Trim(value)
  if not value then
    return ""
  end
  return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

function MCH.util.SetCheckboxLabel(check, text)
  local label = check.Text or check.text
  if label then
    label:SetText(text)
  end
end

function MCH.util.CreateEditBox(parent, width, height)
  local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
  box:SetSize(width, height or 20)
  box:SetAutoFocus(false)
  box:SetScript("OnEscapePressed", box.ClearFocus)
  return box
end

function MCH.util.CreateScrollEditBox(parent, width, height)
  local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
  scroll:SetSize(width, height)
  local edit = CreateFrame("EditBox", nil, scroll)
  edit:SetMultiLine(true)
  edit:SetFontObject("ChatFontNormal")
  edit:SetWidth(width - 26)
  edit:SetAutoFocus(false)
  edit:SetScript("OnEscapePressed", edit.ClearFocus)
  edit:SetScript("OnTextChanged", function(self)
    scroll:UpdateScrollChildRect()
  end)
  edit:SetHeight(height)
  scroll:SetScrollChild(edit)
  return scroll, edit
end

function MCH.util.CreateDropdown(parent, width, items, onSelect)
  local drop = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
  UIDropDownMenu_SetWidth(drop, width)
  UIDropDownMenu_Initialize(drop, function(_, level)
    for _, item in ipairs(items) do
      local info = UIDropDownMenu_CreateInfo()
      local label = item.label
      local value = item.value
      info.text = label
      info.value = value
      info.func = function()
        UIDropDownMenu_SetSelectedValue(drop, value)
        UIDropDownMenu_SetText(drop, label)
        if onSelect then
          onSelect(value)
        end
      end
      UIDropDownMenu_AddButton(info, level)
    end
  end)
  return drop
end

function MCH.util.Print(message)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("MCH: " .. message)
  end
end
