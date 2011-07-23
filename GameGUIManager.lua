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
  ChildFlags = 255,
  GetGUIManager = function() return GameGUIManager end,
}

GameGUIManager.TopLevelUIParent = UIParent

else
  
  UIParent = GameGUIManager.TopLevelUIParent
end

function GameGUIManager:Initialize()
  BaseGUIManager.Initialize(self)

  self:CreateAnchorFrame(Client.GetScreenWidth(), Client.GetScreenHeight())

  UIParent.Size = self.AnchorSize 
  UIParent.RootFrame = self.AnchorFrame
end

function GameGUIManager:DestroySingleInstance(name)

  local frame = self.SingleInstance[name]

  if(frame) then
    self:RemoveFrame(frame, true)
    
    self.SingleInstance[name] = nil
  end
end

function GameGUIManager:CreateFrame(name, ...)
  local frameClass = _G[name]

  if(not frameClass) then
    error(string.format("CreateFrame: There is no frame type named %s", name))
  end

  if(not frameClass.GetGUIManager) then
    error(string.format("CreateFrame: Frame %s is not derived from BaseControl", name))
  end
  
  local sucess, frame = SafeCall(frameClass, ...)  
  
  if(not sucess) then
    return nil
  end

  self:AddFrame(frame)

  return frame
end

function GameGUIManager:GetSingleInstanceControl(name, ...)

  if(self.SingleInstance[name]) then
    return self.SingleInstance[name]
  end

  local frame = self:CreateFrame(name, ...)

  self.SingleInstance[name] = frame
  
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
  
  for _,frame in ipairs(self.TopLevelFrames) do
    frame:Update()
  end

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