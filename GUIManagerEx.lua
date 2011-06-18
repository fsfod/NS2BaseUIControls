
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
end

function GUIManagerEx:SetSkulkViewTilt()
  OnCommandSkulkViewTilt(Client.GetOptionBoolean("DisableSkulkViewTilt", false) and "false")
end

function GUIManagerEx:SetHooks()
  ClassHooker:SetClassCreatedIn("GUIManager", "lua/GUIManager.lua")
  self:HookClassFunction("GUIManager", "Initialize")
  self:HookClassFunction("GUIManager", "SendKeyEvent", self.SendKeyEvent):SetPassHandle(true)
  self:HookClassFunction("GUIManager", "SendCharacterEvent", self.SendCharacterEvent):SetPassHandle(true)
  self:HookClassFunction("GUIManager", "Update")
  
  //self:ReplaceClassFunction("GUIManager", "_SharedCreate")
  self:HookClassFunction("GUIManager", "DestroyGUIScript", "CheckRemoveFrame", self.CheckRemoveFrame)

  self:HookLibraryFunction(HookType.Post, "Client", "ReloadGraphicsOptions", "CheckGraphicsOptions")
  //self:HookLibraryFunction(HookType.Post, "Client", "SetCursor", function(cursor) Shared.Message(tostring(cursor or "nil")) end)
end

function GUIManagerEx:Initialize(self)
  self.TopLevelFrames = {}
	self.AddedFrames = {}
	
	GUIManager.Callbacks = CallbackHandler:New(GUIManager)
	GUIManager.DblClickSpeed = 0.5
end

function GUIManagerEx:CheckGraphicsOptions()
  self.CheckSceenResNextFrame = 0
end

function GUIManagerEx:CheckRemoveFrame(self, frame)
	if(self.AddedFrames[frame]) then
		self.AddedFrames[frame] = nil
		
		for index, frm in ipairs(self.TopLevelFrames) do
			if(frame == frm ) then
				table.remove(self.TopLevelFrames, index)
			end
		end
	end
end

--self is really GUIManager
function GUIManagerEx.SendKeyEvent(handle, self, key, down, ...)
	PROFILE("MouseTracker:SendKeyEvent")

  if(not Client.GetMouseVisible()) then
    
  end

  local focus = self.FocusedFrame
  
  if(focus and focus.SendKeyEvent and focus:SendKeyEvent(key, down, ...)) then
    return true
  end

  if(key == InputKey.MouseX or key == InputKey.MouseY) then
    self.MouseMoved = true
   return
	end

	local eventHandled = false

	if(self.EatKeyUp == key) then
	  self.EatKeyUp = nil
	 eventHandled = true
	end

	if(not eventHandled and (key == InputKey.MouseButton0 or key == InputKey.MouseButton1 or key == InputKey.MouseButton3)) then
		eventHandled = self:MouseClick(key, down)
	end
	  
	if(eventHandled) then
	  handle:BlockOrignalCall()
		handle:SetReturn(true)
	end
end

function GUIManagerEx.SendCharacterEvent(handle, self, ...)

  local focus = self.FocusedFrame
  
  if(focus and focus.SendCharacterEvent and focus:SendCharacterEvent(...)) then
    handle:BlockOrignalCall()
		handle:SetReturn(true)
  end
end

function GUIManagerEx:Update(self, time)
  
  if(GUIManagerEx.CheckSceenResNextFrame) then
    local newValue = GUIManagerEx.CheckSceenResNextFrame+1
    
    if(newValue == 2) then
      if(CheckUpdateScreenRes()) then
        self:ScreenSizeChanged()
      end
      GUIManagerEx.CheckSceenResNextFrame = nil
    else
      GUIManagerEx.CheckSceenResNextFrame = newValue
    end
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