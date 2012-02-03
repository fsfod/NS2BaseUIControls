//
//   Created by:   fsfod
//

local HotReload = ClassHooker:Mixin("GUIMenuManager")

function GUIMenuManager:SetHooks()


  self:HookLibraryFunction(HookType.Replace, "MenuManager", "SetMenu", function() end) 
  
  self:HookLibraryFunction(HookType.Replace, "MenuManager", "GetMenu", function() 
    return (self:IsMenuOpen() and "") or nil 
  end)

  //uncomment to disable menu cinematic
  //self:HookLibraryFunction(HookType.Raw, "MenuManager", "SetMenuCinematic")

  self:ReplaceFunction("MainMenu_Open", function()
    
    if not Shared.GetIsRunningPrediction() then
      OptionsDialogUI_OnInit()
      self:ShowMenu()
    end
    
  end)

  //self:ReplaceFunction("MainMenu_SetAlertMessage", "Hook_SetAlertMessage")


  self:ReplaceFunction("LeaveMenu", function() 

    MenuManager.SetMenu(nil)
    MenuManager.SetMenuCinematic(nil)
    MenuMenu_PlayMusic(nil)

  end)
  
  //so we can can call this in CloseMenu and not worry about an infinite loop from LeaveMenu being called by the real MainMenu_ReturnToGame
  //self:ReplaceFunction("MainMenu_ReturnToGame", function() end)
end

function GUIMenuManager:SetFlashMenuHooks()

  self:HookLibraryFunction(HookType.Normal, "MenuManager", "SetMenu", function(menu)
    if(menu) then
      MouseStateTracker:SetMainMenuState()
    else
      MouseStateTracker:ClearMainMenuState()
    end
  end)
  
  //self:HookFunction("MainMenu_SetAlertMessage", function() MouseStateTracker:ClearStack() end)
end

/*
function GUIMenuManager:Hook_SetAlertMessage(alertMessage)

  MouseStateTracker:ClearStack()

  self:ShowMenu()
  self:ShowMessage("Disconnected from server", alertMessage)

  MainMenu_Loaded()
end
*/

function GUIMenuManager:DisableFlashMenu()

  MenuManager.SetMenu(nil)

  self.FlashMenu = false

  self:RemoveAllHooks()
  self:SetHooks()

  self:ShowMenu()
end

function GUIMenuManager:SwitchToFlash()
  self.FlashMenu = true

  self:RemoveAllHooks()
  self:SetFlashMenuHooks()

  self:Deactivate()

  self:InternalHide()

  MenuManager.SetMenu(kMainMenuFlash)
end


if(not HotReload) then
  Event.Hook("Console_flashmenu", function() GUIMenuManager:SwitchToFlash() end)
  Event.Hook("Console_newmenu", function() GUIMenuManager:DisableFlashMenu() end)
end