//
//   Created by:   fsfod
//

local HotReload = ClassHooker:Mixin("GUIMenuManager")

local kOpenMenuSound = "sound/NS2.fev/common/menu_confirm"

function GUIMenuManager:SetHooks()

  //uncomment to disable menu cinematic
  //self:HookLibraryFunction(HookType.Raw, "MenuManager", "SetMenuCinematic")
  self:ReplaceFunction("MainMenu_Open", function()
    OptionsDialogUI_OnInit()
    
    if(MainMenuMod and MainMenuMod.DisableMenuAmbientSound) then
      Shared.PlaySound(nil, kOpenMenuSound)
      self:ShowMenu()
    else
      MainMenu_OnOpenMenu()
    end
  end)
  

  self:HookFunction("MainMenu_OnOpenMenu", function()
    self:ShowMenu()
  end)

  //self:ReplaceFunction("MainMenu_SetAlertMessage", "Hook_SetAlertMessage")

  //self:HookFunction("LeaveMenu", function()     
  //end, InstantHookFlag)

  self:ReplaceFunction("LeaveMenu", function() 
    self:InternalCloseMenu()

    MenuManager.SetMenuCinematic(nil)
    MenuMenu_PlayMusic(nil)
  end)
  
  //so we can can call this in CloseMenu and not worry about an infinite loop from LeaveMenu being called by the real MainMenu_ReturnToGame
  //self:ReplaceFunction("MainMenu_ReturnToGame", function() end)
end



if(HotReload) then
  GUIMenuManager:SetHooks()
end