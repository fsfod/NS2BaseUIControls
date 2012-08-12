//
//   Created by:   fsfod
//

local HotReload = GameGUIManager

local UIParent

if(not HotReload) then

GameGUIManager = {
  Name = "GameGUIManager",
  SingleInstance = {},
}

setmetatable(GameGUIManager, {__index = BaseGUIManager})

UIParent = {
  Position = Vector(0, 0, 0),
  Size = Vector(800, 600, 0),
  GetXAnchor = function() return GUIItem.Left end,
  GetYAnchor = function() return GUIItem.Top end,
  IsShown = function() return true end,
  Flags = 0,
  ChildFlags = 255,
  GetGUIManager = function() return GameGUIManager end,
  UIParent = true,
}

GameGUIManager.TopLevelUIParent = UIParent

else
  UIParent = GameGUIManager.TopLevelUIParent
end

function GameGUIManager:Initialize()
  BaseGUIManager.Initialize(self)
  
end

function GameGUIManager:LoadComplete()
  self:CreateAnchorFrame(Client.GetScreenWidth(), Client.GetScreenHeight())
  
  local size = Vector(Client.GetScreenWidth()/UIScale, Client.GetScreenHeight()/UIScale, 0)
  UIParent.Size = size
end

function GameGUIManager:Reset()

  self:DestroyAllFrames()

  self:CreateAnchorFrame(Client.GetScreenWidth(), Client.GetScreenHeight())
  
  UIParent.RootFrame = self.AnchorFrame
  UIParent.Size = self.AnchorSize
  
  self.SingleInstance = {}
  
  //WORKAROUND for layers going all wierd
  GUIMenuManager:DoLayerFix()
end

function GameGUIManager:DestroySingleInstance(name)

  local frame = self.SingleInstance[name]

  if(frame) then
    self:RemoveFrame(frame, true)
    
    self.SingleInstance[name] = nil
  end
end

function GameGUIManager:CreateFrame(name, ...)

  local frame = self:InternalCreateFrame(name, ...)  

  if(frame) then
    self:AddFrame(frame)
  end

  return frame
end

function GameGUIManager:GetSingleInstanceControl(name, ...)

  if(self.SingleInstance[name]) then
    return self.SingleInstance[name]
  end

  local frame = self:InternalCreateFrame(name, ...)

  if(frame) then
    self:AddFrame(frame)
    
    self.SingleInstance[name] = frame
  end

  return frame
end

function GameGUIManager:PassOnClickEvent(button, down)
  return true
end

function GameGUIManager:IsActive()
  return self.Active and Client.GetMouseVisible() 
end

function GameGUIManager:MouseClick(button, down)

  local player = Client.GetLocalPlayer()
  
  //hack to handle when the buy menu is open
  if(player and (player.buyMenu or player.showingBuyMenu)) then
    return false
  end

  return BaseGUIManager.MouseClick(self, button, down)
end

function GameGUIManager:Update()
  
  self:UpdateFrames() 

  if(not self:IsActive()) then
    return 
  elseif(not Client.GetMouseVisible()) then

    if(self.MouseVisible) then
      self:ClearStateData()
      self.MouseVisible = false
    end

   return
  else
    if(not self.MouseVisible) then
      self.MouseVisible = true
    end
  end

  if(self.FocusedFrame and not self.FocusedFrame:IsShown()) then
    self:ClearFocus()
  end

  self.DoneMouseMove = false
end

if(HotReload) then
  GameGUIManager:LuaReloaded()
end
