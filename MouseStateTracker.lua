local HotReload = false
local SetMouseVisible, SetMouseCaptured, SetMouseClipped, SetCursor

if(not MouseStateTracker) then
  
  SetMouseVisible = Client.SetMouseVisible
  SetMouseCaptured = Client.SetMouseCaptured
  SetMouseClipped = Client.SetMouseClipped
  SetCursor = Client.SetCursor
  
  MouseStateTracker = {
    StateStack = {},
    OwnerToState = {},
    StackTop = 0,

    MouseFunctions = {
      ["SetMouseVisible"] = SetMouseVisible,
      ["SetMouseCaptured"] = SetMouseCaptured,
      ["SetMouseClipped"] = SetMouseClipped,
      ["SetCursor"] = SetCursor,
    },
  }
  
  Event.Hook("Console_resetmouse", function()MouseStateTracker:ClearState() end)
  
else
  HotReload = true
  
  SetMouseVisible = MouseStateTracker.MouseFunctions.SetMouseVisible
  SetMouseCaptured = MouseStateTracker.MouseFunctions.SetMouseCaptured
  SetMouseClipped = MouseStateTracker.MouseFunctions.SetMouseClipped
  SetCursor = MouseStateTracker.MouseFunctions.SetCursor
end

ClassHooker:Mixin("MouseStateTracker")


function MouseStateTracker:Init()
  self:DisableMouseFunctions()
  self:SetHooks()
  self:SetMainMenuState()
end

function MouseStateTracker:SetHooks() 
  self:ReplaceClassFunction("Alien", "_UpdateMenuMouseState", "UpdateBuyMenuState")

  self:PostHookClassFunction("Commander", "UpdateCursor")  
  self:HookClassFunction("Commander", "SetupHud", function() self:PushState("commander", true, false, true) end)
  
  self:HookClassFunction("Armory", "OnUse", "ArmoryBuy_Hook")
  self:HookFunction("ArmoryUI_Close", function() self:PopState("buymenu") end)
  
  PlayerEvents:HookIsCommander(self, "CommaderStateChanged")
end


function MouseStateTracker:ArmoryBuy_Hook(objSelf, player, elapsedTime, useAttachPoint)
  if(objSelf ~= Client.GetLocalPlayer()) then
    return
  end
  
  if (objSelf:GetIsBuilt() and objSelf:GetIsActive() and not self.OwnerToState["buymenu"]) then
  	self:PushState("buymenu", true, false, false)
  end
end

function MouseStateTracker:CommaderStateChanged(isCommander)
  if(not isCommander) then
    self:PopState("commander")
  else
  end
end

function MouseStateTracker:UpdateCursor(commEntity)
  
  local Cursor = commEntity.lastCursorTexture
  
  if(Cursor) then
    local commstate = self.OwnerToState["commander"]
    assert(commstate)
    
    if(Cursor ~= commstate.Icon) then
      commstate.Icon = Cursor
      self:ApplyStack()
    end
  end
end

function MouseStateTracker:UpdateBuyMenuState(alienSelf)
  if(alienSelf ~= Client.GetLocalPlayer()) then
    return
  end
  
  if(alienSelf:GetBuyMenuIsDisplaying()) then
    self:PushState("buymenu", true, false, false)
  else
    self:PopState("buymenu")
  end
end

function MouseStateTracker:DisableMouseFunctions() 
  local hooklist = {}

  hooklist[1] = self:HookLibraryFunction(HookType.Replace, "Client", "SetMouseVisible", function() end)
  hooklist[2] = self:HookLibraryFunction(HookType.Replace, "Client", "SetMouseCaptured", function() end)
  hooklist[3] = self:HookLibraryFunction(HookType.Replace, "Client", "SetMouseClipped", function() end)
  hooklist[4] = self:HookLibraryFunction(HookType.Replace, "Client", "SetCursor", function() end)

  self.MouseFunctionHooks = hooklist
end

function MouseStateTracker:EnableFunctions()
  
  if(not self.MouseFunctionHooks) then
    return
  end
  
  for i,hook in ipairs(self.MouseFunctionHooks) do
    self:RemoveHook(hook)
  end
  
  self.MouseFunctionHooks = nil
end

function MouseStateTracker:GetStateIndex(ownerName)
  for i,state in ipairs(self.StateStack) do
    if(state.Owner == ownerName) then
      return i
    end
  end

  return nil
end

function MouseStateTracker:SetMainMenuState()

  self.MainMenuActive = true

  SetMouseVisible(true)
  SetMouseCaptured(false)
  SetMouseClipped(false)
  SetCursor("ui/Cursor_MenuDefault.dds")
end

function MouseStateTracker:ClearMainMenuState()
  self.MainMenuActive = false
  self:ApplyStack()
end

function MouseStateTracker:ClearAllExcept(keepList)
  
  local LookUpTable = {}
  
  for name,_ in pairs(keepList) do
    if(self.OwnerToState[name]) then
      LookUpTable[name] = self:GetStateIndex(name)
    end
  end

  self.StateStack = {}

  for name,state in pairs(self.OwnerToState) do
    if(not LookUpTable[name]) then
      self.OwnerToState[name] = nil
    else
      table.insert(self.StateStack, state)
    end
  end
  
  table.sort(self.StateStack, function(state1, state2) return LookUpTable[state1.Owner] > LookUpTable[state2.Owner] end)
  
  self.StackTop = #self.StateStack

  if(not self.MainMenuActive) then
    --just set the defaults
    self:ApplyStack()
  end
end

function MouseStateTracker:ClearStack()

  self.StateStack = {}
  self.OwnerToState = {}
  self.StackTop = 0

  if(not self.MainMenuActive) then
    --just set the defaults
    self:ApplyStack()
  end
end

function MouseStateTracker:PushState(ownerName, mouseVisble, mouseCaptured, mouseClipped, cursorIcon)
  assert(ownerName)
  Print("PushMouseState "..ownerName)
  
  local exists = self.OwnerToState[ownerName]

	if(exists) then
	  local index = self:GetStateIndex(ownerName) or -1
	  
		Print("MouseStateTracker:PushState Warning found %s state already in stack at index %i", ownerName, index)
    
    
    if(index ~= -1 ) then
      table.remove(self.StateStack, index)
		end
	end

  local state = {
    Owner = ownerName,
   
    Visible = mouseVisble,
    Captured = mouseCaptured,
    Clipped = mouseClipped,
    Icon = cursorIcon,
  }

  self.StackTop = self.StackTop+1

  self.StateStack[self.StackTop] = state

  self.OwnerToState[ownerName] = state

  if(not self.MainMenuActive) then
    self:ApplyStack()
  end
end

function MouseStateTracker:TryPopState(ownerName)
  if(self.OwnerToState[ownerName]) then
    self:PopState(ownerName)
  end
end

function MouseStateTracker:PopState(ownerName)
  
  Print("PopMouseState "..ownerName)
  
  local index = self:GetStateIndex(ownerName)
  
  if(not index) then
    Print("there is no MouseState named "..ownerName.." in the stack")
   return
  end
  
  local state = table.remove(self.StateStack, index)

  self.OwnerToState[ownerName] = nil

  self:ApplyStack()

  self.StackTop = self.StackTop-1
end

function MouseStateTracker:ApplyStack()
  
  if(self.MainMenuActive) then
    return
  end

  local visible, captured, clipped = false, true, true
  local cursorImage = "ui/Cursor_MenuDefault.dds"

  for i,state in ipairs(self.StateStack) do
    if(state.Visible ~= nil) then
      visible = state.Visible
    end
    
    if(state.Captured ~= nil) then
      captured = state.Captured
    end
    
    if(state.Icon ~= nil) then
      cursorImage = state.Icon
    end   
  end

  if(visible) then
    SetCursor(cursorImage)
  end

  SetMouseVisible(visible)
  SetMouseCaptured(captured)
  SetMouseClipped(clipped)
end

if(HotReload) then
  MouseStateTracker:SetHooks()
end