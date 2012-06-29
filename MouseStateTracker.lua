//
//   Created by:   fsfod
//

local HotReload = false
local SetMouseVisible, SetMouseClipped, SetCursor

if(not MouseStateTracker) then
    
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

    DefaultCursor = "ui/Cursor_MenuDefault.dds",
  }  
else
  HotReload = true
  
  SetMouseVisible = MouseStateTracker.MouseFunctions.SetMouseVisible
  SetMouseClipped = MouseStateTracker.MouseFunctions.SetMouseClipped
  SetCursor = MouseStateTracker.MouseFunctions.SetCursor
end

MouseStateTracker.Debug = false

ClassHooker:Mixin("MouseStateTracker")


function MouseStateTracker:Init()
  self:SetHooks()
  
  LoadTracker:HookFileLoadFinished("lua/GUIScoreboard.lua", function() 
     self:InjectHook({"scoreboard", "GUIScoreboard", "_SetMouseVisible"})
  end)
  //self:SetMainMenuState()
  
  //Event.Hook("UpdateClient", function()
  //  MouseStateTracker:Update()
  //end)
end
 
function MouseStateTracker:OnClientLoadComplete()

  SetMouseVisible = Client.SetMouseVisible
  SetMouseClipped = Client.SetMouseClipped
  SetCursor = Client.SetCursor

  self.MouseFunctions = {
    ["SetMouseVisible"] = SetMouseVisible,
    ["SetMouseClipped"] = SetMouseClipped,
    ["SetCursor"] = SetCursor,
  }

  self:DisableMouseFunctions()
  
  if(not StartupLoader.IsMainVM) then
    self:ClearMainMenuState()
    self:InjectHooks()
  end
  
  self.MouseTracker_SetIsVisible = self.MouseTracker_SetIsVisible or MouseTracker_SetIsVisible
  
  MouseTracker_SetIsVisible = function()
  end
end

function MouseStateTracker:Update()
  //self:ApplyStack()
end

function MouseStateTracker:PrintDebug(...)
  if(self.Debug) then
    RawPrint(...)
  end
end

local hookTargets = {
  {"buymenu", "Player", "OpenMenu"},
  {"buymenu", "Player", "CloseMenu", Pop = true},

  {"buymenu", "Armory", "OnUse"},

  {"buymenu", "Marine", "OnDestroy", Pop = true},
  {"buymenu", "Marine", "CloseMenu", Pop = true},

  {"buymenu", "Alien", "Buy"},
  {"buymenu", "Alien", "CloseMenu", Pop = true},
  
  {"buymenu", "PrototypeLab", "OnUse"},
}

local hookMT = {
  __index = function(self, key)
    return rawget(self, key) or _G[key]
  end,
  
  __newindex = function(self, key, value)
    _G[key] = value
  end,
}

function MouseStateTracker:InjectHooks()

  for i,entry in ipairs(hookTargets) do 
    self:InjectHook(entry)
  end

end

function MouseStateTracker:InjectHook(hook)
  
    local object = _G[hook[2]]
    local func = object and object[hook[3]]
    
    if(func) then
      
      local setIsVisible = function(isVisible, texture, clipped)
        self:SetIsVisibleHook(hook[1], isVisible, texture, clipped)
      end
      
      
      if(debug.getfenv(func) ~= _G) then
        
        debug.getfenv(func).MouseTracker_SetIsVisible = setIsVisible

      else
        
        debug.setfenv(func, setmetatable({MouseTracker_SetIsVisible = setIsVisible}, hookMT))
        
      end
      
    end
  
end

function MouseStateTracker:SetHooks(startup) 

  self:PostHookClassFunction("Commander", "UpdateCursor")  
  self:HookClassFunction("Commander", "SetupHud", function() self:PushState("commander", true, true) end)
  
  //self:HookLibraryFunction(HookType.Post, "Client", "SetPitch", function() 
  //  self:PrintDebug("Client.SetPitch")
 // end)

  //self:HookLibraryFunction(HookType.Post, "Client", "SetYaw", function()
 //   self:PrintDebug("Client.SetYaw")
 // end)
  ClassHooker:SetClassCreatedIn("OverheadSpectatorMode", "lua/OverheadSpectatorMode.lua")
 
  self:HookClassFunction("OverheadSpectatorMode", "Initialize", function()
    MouseStateTracker:PushState("Spectator", true, true)
  end)
    
  self:HookClassFunction("OverheadSpectatorMode", "Uninitialize", function()
    MouseStateTracker:PopState("Spectator")
  end) 
  
  PlayerEvents:HookIsCommander(self, "CommaderStateChanged")
  PlayerEvents:HookPlayerDied(self, "PlayerDied")
  PlayerEvents:HookTeamChanged(self, "TeamChanged")
end

function MouseStateTracker:TeamChanged(old, new)
  self:ClearAllExcept(self.RoundPersist)
end

function MouseStateTracker:PlayerDied()
  self:ClearAllExcept(self.DeathPersist)
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
      commstate.HotspotX = self.LastHotspotX
      commstate.HotspotY = self.LastHotspotY

      self.LastHotspotX = nil
      self.LastHotspotY = nil
      
      self:ApplyStack()
    end
  end
end

function MouseStateTracker:DisableMouseFunctions() 
  local hooklist = {}

  hooklist[1] = self:HookLibraryFunction(HookType.Replace, "Client", "SetMouseVisible", function() end)
  hooklist[2] = self:HookLibraryFunction(HookType.Replace, "Client", "SetMouseClipped", function() end)
  hooklist[3] = self:HookLibraryFunction(HookType.Replace, "Client", "SetCursor", function(image, hotspotX, hotspotY)
    self.LastHotspotX = hotspotX
    self.LastHotspotY = hotspotY
  end)

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

function MouseStateTracker:ControlSetCursor(control, path, hotX, HotY)
  assert(self.MainMenuActive)
  assert(control)

  SetCursor(path, hotX, HotY)
end

function MouseStateTracker:SetMainMenuState()
  self:PrintDebug("SetMainMenuState")
  
  if(not SetCursor) then
      RawPrint("MouseStateTracker:SetMainMenuState called before mouse functions are available")
    return
  end
  
  self.MainMenuActive = true

  SetMouseVisible(true)
  SetMouseClipped(false)
  SetCursor(self.DefaultCursor, 0, 0)
  
  if(MouseTracker_SetIsVisible) then
    MouseTracker_SetIsVisible(false)
  end
end

function MouseStateTracker:ClearMainMenuState()
  self.MainMenuActive = false
  
  if(not SetCursor) then
      RawPrint("MouseStateTracker:ClearMainMenuState called before mouse functions are available")
    return
  end

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

function MouseStateTracker:SetIsVisibleHook(ownerName, isVisible, texture, clipped)

  if(not isVisible) then
    self:TryPopState(ownerName)
  else
    self:PushState(ownerName, isVisible, clipped, texture)
  end

end

function MouseStateTracker:PushState(ownerName, mouseVisble, mouseClipped, cursorIcon, hotspotX, hotspotY)
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
    Clipped = mouseClipped,
    Icon = cursorIcon,
    HotspotX = hotspotX, 
    HotspotY = hotspotY,
  }

  self.StackTop = self.StackTop+1

  self.StateStack[self.StackTop] = state

  self.OwnerToState[ownerName] = state

  if(not self.MainMenuActive) then
    self:ApplyStack()
  end
end

function MouseStateTracker:IsStateActive(stateName)
  return self.OwnerToState[stateName]
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

local defaultCursor = {
  Icon = "ui/Cursor_MenuDefault.dds",
  HotspotX = 0,
  HotspotY = 0,
}

function MouseStateTracker:ApplyStack()
  
  self:PrintDebug("ApplyStack %i", #self.StateStack)
  
  if(self.MainMenuActive) then
    return
  end

  //Make our evil twin process mouse events correctly
  if(MouseTracker_SetIsVisible) then
    
    if(#self.StateStack == 0 and MouseTracker_GetIsVisible()) then
      self.MouseTracker_SetIsVisible(false)
    elseif(#self.StateStack ~= 0 and not MouseTracker_GetIsVisible()) then
      self.MouseTracker_SetIsVisible(true)
    end
  end

  local visible, clipped = false, true
  local cursorImage = defaultCursor

  for i,state in ipairs(self.StateStack) do
    if(state.Visible ~= nil) then
      visible = state.Visible
    end
    
    if(state.Clipped ~= nil) then
      clipped = state.Clipped
    end
    
    if(state.Icon ~= nil) then
      cursorImage = state
    end   
  end

  if(visible) then
    
    SetCursor(cursorImage.Icon, cursorImage.HotspotX or 0, cursorImage.HotspotY or 0)
  end

  SetMouseVisible(visible)
  SetMouseClipped(clipped)
end


Event.Hook("Console_resetmouse", function() MouseStateTracker:ClearStack() end)

if(HotReload) then
  MouseStateTracker:DisableMouseFunctions()
  MouseStateTracker:SetHooks()
end