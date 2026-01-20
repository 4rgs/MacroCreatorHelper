local addonName = ...

SLASH_MACROCREATORHELPER1 = "/mch"
SLASH_MACROCREATORHELPER2 = "/macrocreatorhelper"
SlashCmdList.MACROCREATORHELPER = function()
  if MCH and MCH.ui and MCH.ui.Toggle then
    MCH.ui.Toggle()
  elseif DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("MCH: UI not ready.")
  end
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
  MacroCreatorHelperDB = MacroCreatorHelperDB or {}
  MacroCreatorHelperDB.minimap = MacroCreatorHelperDB.minimap or { angle = 225 }
  if MCH and MCH.minimap and MCH.minimap.Init then
    MCH.minimap.Init()
  end
end)
