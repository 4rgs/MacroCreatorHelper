MCH.macro = MCH.macro or {}

function MCH.macro.Save(name, icon, body, perChar)
  local index = GetMacroIndexByName(name)
  if index and index > 0 then
    EditMacro(index, name, icon, body)
    return true, "updated"
  end

  local numGlobal, numChar = GetNumMacros()
  local maxGlobal = MAX_ACCOUNT_MACROS or 18
  local maxChar = MAX_CHARACTER_MACROS or 18
  if perChar and numChar >= maxChar then
    return false, "No character macro slots."
  end
  if (not perChar) and numGlobal >= maxGlobal then
    return false, "No global macro slots."
  end

  local created = CreateMacro(name, icon, body, perChar)
  if created then
    return true, "created"
  end
  return false, "Failed to create macro."
end
