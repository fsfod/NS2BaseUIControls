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
    DeathPersist = {
      chat = true,
      scoreboard = true,
    },
    RoundPersist = {
      chat = true,
      scoreboard = true,
    },

    MouseFunctions = {
      ["SetMouseVisible"] = SetMouseVisible,
      ["SetMouseCaptured"] = SetMouseCaptured,
      ["SetMouseClipped"] = SetMouseClipped,
      ["SetCursor"] = SetCursor,
    },
  }
  
  Event.Hook("Console_resetmouse", function() MouseStateTracker:ClearStack() end)
  
else
  HotReload = true
  
  SetMouseVisible = MouseStateTracker.MouseFunctions.SetMouseVisible
  SetMouseCaptured = MouseStateTracker.MouseFunctions.SetMouseCaptured
  SetMouseClipped = MouseStateTracker.MouseFunctions.SetMouseClipped
  SetCursor = MouseStateTracker.MouseFunctions.SetCursor
end

MouseStateTracker.Debug = false

ClassHooker:Mixin("MouseStateTracker")


function MouseStateTracker:Init()
  self:SetHooks(true)
  self:SetMainMenuState()
  
  //Event.Hook("UpdateClient", function()
  //  MouseStateTracker:Update()
  //end)
end

function MouseStateTracker:Update()
  //self:ApplyStack()
end

function MouseStateTracker:PrintDebug(...)
  if(self.Debug) then
    RawPrint(...)
  end
end

function MouseStateTracker:SetHooks(startup) 
  self:ReplaceClassFunction("Alien", "_UpdateMenuMouseState", "UpdateBuyMenuState")

  self:PostHookClassFunction("Commander", "UpdateCursor")  
  self:HookClassFunction("Commander", "SetupHud", function() self:PushState("commander", true, false, true) end)
  
  self:PostHookClassFunction("Armory", "OnUse", "ArmoryBuy_Hook")
  self:HookFunction("ArmoryUI_Close", function() self:PopState("buymenu") end)
  
  self:PostHookClassFunction("Marine", "CloseMenu",
    function(entitySelf)
      if entitySelf == Client.GetLocalPlayer()  then
        self:TryPopState("buymenu")
      end
  end)
  
   ClassHooker:SetClassCreatedIn("GUIScoreboard")
  
  self:PostHookClassFunction("GUIScoreboard", "_SetMouseVisible", function(scoreSelf)
    if(scoreSelf.mouseVisible) then
      if(not self.OwnerToState["scoreboard"]) then
        self:PushState("scoreboard", true, false, false)
      end
    else
      self:TryPopState("scoreboard")
    end
  end)
  
  
  //self:HookLibraryFunction(HookType.Post, "Client", "SetPitch", function() 
  //  self:PrintDebug("Client.SetPitch")
 // end)

  //self:HookLibraryFunction(HookType.Post, "Client", "SetYaw", function()
 //   self:PrintDebug("Client.SetYaw")
 // end)
  
  
  PlayerEvents:HookIsCommander(self, "CommaderStateChanged")
  PlayerEvents:HookPlayerDied(self, "PlayerDied")
  PlayerEvents:HookTeamChanged(self, "TeamChanged")
  
  if(startup or self.MouseFunctionHooks) then
    self:DisableMouseFunctions() 
  end
end

function MouseStateTracker:TeamChanged(old, new)
  self:ClearAllExcept(self.RoundPersist)
end

function MouseStateTracker:PlayerDied()
  self:ClearAllExcept(self.DeathPersist)
end

function MouseStateTracker:ArmoryBuy_Hook(objSelf, player, elapsedTime, useAttachPoint)

  if(not player or player ~= Client.GetLocalPlayer() or Shared.GetIsRunningPrediction()) then
    return
  end
  
  if(player.showingBuyMenu and not self.OwnerToState["buymenu"]) then
    self:PushState("buymenu", true, false, false)
  end
end

function MouseStateTracker:CommaderStateChanged(isCommander)
  if(not isCommander) then
    self:TryPopState("commander")
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
  self:PrintDebug("SetMainMenuState")
  
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
  self:PrintDebug("MouseStateTracker:ClearAllExcepte")
  
  local LookUpTable = {}
  
  for i,state in pairs(self.StateStack) do
    local name = state.Owner
    
    if(keepList[name]) then
      LookUpTable[name] = i
    else
      --nil out this refrance since were not keeping this state entry
      self.OwnerToState[name] = nil
    end
  end

  self.StateStack = {}

  for name,state in pairs(self.OwnerToState) do
    if(LookUpTable[name]) then
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

  self:PrintDebug("MouseStateTracker:ClearStack")

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
  self:PrintDebug("PushMouseState "..(ownerName or "nil"))
  
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
  
  self:PrintDebug("PopMouseState "..ownerName)
  
  local index = self:GetStateIndex(ownerName)
  
  if(not index) then
    RawPrint("there is no MouseState named "..ownerName.." in the stack")
   return
  end
  
  local state = table.remove(self.StateStack, index)

  self.OwnerToState[ownerName] = nil

  self:ApplyStack()

  self.StackTop = self.StackTop-1
end

function MouseStateTracker:ApplyStack()
  
  self:PrintDebug("ApplyStack %i", #self.StateStack)
  
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