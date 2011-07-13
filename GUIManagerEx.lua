
if(not GUIManagerEx) then
  GUIManagerEx = {}
end


local HotReload = ClassHooker:Mixin("GUIManagerEx")

function GUIManagerEx:OnClientLuaFinished()

end

function GUIManagerEx:OnLoad()
  self:SetHooks()
  self:LoadScriptAfter("lua/GUIManager.lua", "GUIManager.lua")
  
  self:HookFileLoadFinished("lua/Skulk_Client.lua", "SetSkulkViewTilt")
  
  MouseStateTracker:Init()
end

function GUIManagerEx:SetSkulkViewTilt()
  OnCommandSkulkViewTilt(Client.GetOptionBoolean("DisableSkulkViewTilt", false) and "false")
end

function GUIManagerEx:SetHooks()
  ClassHooker:SetClassCreatedIn("GUIManager", "lua/GUIManager.lua")
  self:HookClassFunction("GUIManager", "Initialize")
  self:RawHookClassFunction("GUIManager", "SendKeyEvent", self.SendKeyEvent):SetPassHandle(true)
  self:HookClassFunction("GUIManager", "SendCharacterEvent", self.SendCharacterEvent):SetPassHandle(true)
  self:HookClassFunction("GUIManager", "Update")
  
  //self:ReplaceClassFunction("GUIManager", "_SharedCreate")
  self:HookClassFunction("GUIManager", "DestroyGUIScript")
  self:ReplaceClassFunction("GUIManager", "DestroyGUIScriptSingle")
  
  //self:HookLibraryFunction(HookType.Post, "Client", "SetCursor", function(cursor) Shared.Message(tostring(cursor or "nil")) end)
end

function GUIManagerEx:Initialize(self)
  self.TopLevelFrames = {}
  self.AddedFrames = {}
  self.KeyDown = {}
  
  GUIManager.Callbacks = CallbackHandler:New(GUIManager)
  GUIManager.DblClickSpeed = 0.5
end

function GUIManagerEx:DestroyGUIScript(self, frame)
  self:CheckRemoveFrame(frame)
end

function GUIManagerEx:DestroyGUIScriptSingle(self, scriptName)
  
  for index, script in ipairs(self.scriptsSingle) do
    if script[2] == scriptName then
      if table.removevalue(self.scriptsSingle, script) then
        self:CheckRemoveFrame(self, script[1])
        SafeCall(script[1].Uninitialize, script[1])
       break
      end
    end
  end
  
end

local WheelMessages = nil

local NoUpEvent = {
  [InputKey.MouseZ] = true,
  [InputKey.MouseX] = true,
  [InputKey.MouseY] = true,
}

--self is really GUIManager
function GUIManagerEx.SendKeyEvent(handle, self, key, down)
  PROFILE("MouseTracker:SendKeyEvent")

  if(not Client.GetMouseVisible()) then
    
  end
  local IsRepeat = false

  if(not NoUpEvent[key]) then
    IsRepeat = self.KeyDown[key] and down
    self.KeyDown[key] = down
  end

  if(key == InputKey.MouseZ and GetWheelMessages) then
    if(WheelMessages == nil) then
     WheelMessages = GetWheelMessages() or false
     
      if(WheelMessages) then
        RawPrint("WheelMsgs %i", #WheelMessages)
      end
    end
    
    if(WheelMessages and #WheelMessages ~= 0) then
      local direction = WheelMessages[1]
      table.remove(WheelMessages, 1)
      
      
      self.WheelDirection = direction
      
      local x,y = Client.GetCursorPosScreen()
      self:TraverseFrames(self:GetFrameList(), x, y, 4, self.DoOnMouseWheel)
      
      
      if(direction == 1) then
        //RawPrint("WheelUp")
      elseif(direction == -1) then
        //RawPrint("WheelDown")
      else
       // RawPrint(direction or "nil")
      end
    end
  end

  local focus = self.FocusedFrame
  local eventHandled = false
  
  if(focus and focus.SendKeyEvent and focus:SendKeyEvent(key, down, IsRepeat)) then
    eventHandled = true
  end

  if(key == InputKey.MouseX or key == InputKey.MouseY) then
    self.MouseMoved = true
   return key, down
  end

  if(self.EatKeyUp == key) then
    self.EatKeyUp = nil
   eventHandled = true
  end

  local IsClick = (key == InputKey.MouseButton0 or key == InputKey.MouseButton1 or key == InputKey.MouseButton3)
  local ProcessClick = true

  //hack to handle when the buy menu is open
  if(IsClick and (not MainMenuMod or not MainMenuMod:IsMenuOpen())) then
    local player = Client.GetLocalPlayer()
    
    ProcessClick = not player or not (player.buyMenu or player.showingBuyMenu)
  end

  if(not eventHandled and IsClick and ProcessClick) then
    eventHandled = self:MouseClick(key, down)
  end
    
  if(eventHandled) then
    handle:BlockOrignalCall()
    handle:SetReturn(true)
  end
  
  return key, down, IsRepeat
end

function GUIManagerEx.SendCharacterEvent(handle, self, ...)

  local focus = self.FocusedFrame
  
  if(focus and focus.SendCharacterEvent and focus:SendCharacterEvent(...)) then
    handle:BlockOrignalCall()
    handle:SetReturn(true)
  end
end

function GUIManagerEx:Update(self, time)
  
  WheelMessages = nil
  
  if(self.FocusedFrame and not self.FocusedFrame:IsShown()) then
    self:ClearFocus()
  end

  local MouseVisible = Client.GetMouseVisible()
  
  if(MouseVisible) then
    if(not self.MouseIsVisible) then
      self:MouseShown()
      self.MouseIsVisible = true
    end
    
    if(self.MouseMoved) then
      self:OnMouseMove()
      self.MouseMoved = false
    end
  else
    if(self.MouseIsVisible) then
      self:MouseHidden()
      self.MouseIsVisible = false
    end
  end
end

if(HotReload) then
  GUIManagerEx:SetHooks()
end