local util = MCH.util

MCH.builder = MCH.builder or {}

function MCH.builder.BuildCondition(state)
  local parts = {}
  if state.targetUnit and state.targetUnit ~= "none" then
    table.insert(parts, "@" .. state.targetUnit)
  end
  if state.modShift then
    table.insert(parts, "mod:shift")
  end
  if state.modCtrl then
    table.insert(parts, "mod:ctrl")
  end
  if state.modAlt then
    table.insert(parts, "mod:alt")
  end
  if state.stanceMode and state.stanceMode ~= "none" then
    table.insert(parts, state.stanceMode)
  end
  if state.combatMode and state.combatMode ~= "none" then
    table.insert(parts, state.combatMode)
  end
  if state.reactionMode and state.reactionMode ~= "none" then
    table.insert(parts, state.reactionMode)
  end
  local eqText = util.Trim(state.equippedItem)
  if eqText ~= "" then
    if state.equippedMode == "equipped" then
      table.insert(parts, "equipped:" .. eqText)
    elseif state.equippedMode == "noequipped" then
      table.insert(parts, "noequipped:" .. eqText)
    end
  end
  if #parts > 0 then
    return "[" .. table.concat(parts, ",") .. "]"
  end
  return ""
end

function MCH.builder.BuildReset(state)
  local parts = {}
  if state.resetTarget then
    table.insert(parts, "target")
  end
  if state.resetCombat then
    table.insert(parts, "combat")
  end
  if state.resetShift then
    table.insert(parts, "shift")
  end
  if state.resetCtrl then
    table.insert(parts, "ctrl")
  end
  if state.resetAlt then
    table.insert(parts, "alt")
  end
  local seconds = util.Trim(state.resetTime)
  if seconds ~= "" then
    table.insert(parts, seconds)
  end
  return table.concat(parts, "/")
end

function MCH.builder.NormalizeSequence(sequence)
  local text = util.Trim(sequence)
  text = text:gsub("[\r\n]+", ", ")
  text = text:gsub("%s*,%s*", ", ")
  return text
end

function MCH.builder.BuildLine(state)
  local cond = MCH.builder.BuildCondition(state)
  local actionType = state.actionType

  if actionType == "castsequence" then
    local sequence = MCH.builder.NormalizeSequence(state.sequence)
    if sequence == "" then
      return nil, "Sequence is empty."
    end
    local options = {}
    if cond ~= "" then
      table.insert(options, cond)
    end
    local reset = MCH.builder.BuildReset(state)
    if reset ~= "" then
      table.insert(options, "reset=" .. reset)
    end
    local optText = ""
    if #options > 0 then
      optText = table.concat(options, " ") .. " "
    end
    return "/castsequence " .. optText .. sequence
  end

  local action = util.Trim(state.action)
  if action == "" then
    return nil, "Action is empty."
  end

  if actionType == "equipslot" then
    local slot = util.Trim(state.actionSlot)
    if slot == "" then
      return nil, "Slot is empty."
    end
    local parts = { "/equipslot" }
    if cond ~= "" then
      table.insert(parts, cond)
    end
    table.insert(parts, slot)
    table.insert(parts, action)
    return table.concat(parts, " ")
  end

  local cmd = "/cast"
  if actionType == "use" then
    cmd = "/use"
  elseif actionType == "equip" then
    cmd = "/equip"
  end
  local line = cmd .. " "
  if cond ~= "" then
    line = line .. cond .. " "
  end
  line = line .. action
  return line
end
