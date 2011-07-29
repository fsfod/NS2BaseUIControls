local HotReload = GUIMenuManager

local UIMenuParent

if(not HotReload) then

GUIMenuManager = {
  Name = "GUIMenuManager",
  MenuLayer = 20,
  DefaultMenuClass = "GUIMainMenu",
  MessageBoxClass = "MessageBox",

  PageInfos = {},
  OptionPageList = {},
  DefaultPages = {
    ServerBrowser = "ServerBrowserPage",
    Main = "MenuMainPage",
    CreateServer = "CreateServerPage",
  },
}

setmetatable(GUIMenuManager, {__index = BaseGUIManager})

UIMenuParent = {
  Position = Vector(0, 0, 0),
  Size = Vector(800, 600, 0),
  GetXAnchor = function() return GUIItem.Left end,
  GetYAnchor = function() return GUIItem.Top end,
  IsShown = function() return GUIMenuManager:IsMenuOpen() end,
  ChildFlags = 255,
  GetGUIManager = function() return GUIMenuManager end,
}

GUIMenuManager.TopLevelUIParent = UIMenuParent
end

function GUIMenuManager:Initialize()
  BaseGUIManager.Initialize(self)

  self:CreateAnchorFrame(Client.GetScreenWidth(), Client.GetScreenHeight(), self.MenuLayer)
end

function GUIMenuManager:DoLayerFix()
  self:RecreateAnchorAndUpdateFrames(Client.GetScreenWidth(), Client.GetScreenHeight(), self.MenuLayer, self.IntenalMesssageBox, self.MessageBox)
end

local msgBoxTable = {}

function GUIMenuManager:GetFrameList()
  if(self.MessageBox) then
    msgBoxTable[1] = self.MessageBox

   return msgBoxTable
  else
    //self.TopLevelFrames[1] will always contain self.MainMenu
    return self.TopLevelFrames
  end
end

function GUIMenuManager:SetMainMenu(menuFrame)
  
  if(self.MainMenu) then
    table.removevalue(self.TopLevelFrames, self.MainMenu)
  end
  
  menuFrame.Parent = UIMenuParent
  menuFrame:SetPosition(0, 0)
  
  self.MainMenu = menuFrame
  
  table.insert(self.TopLevelFrames, 1, menuFrame)
end

function GUIMenuManager:IsMainMenuChild(frame)
  return true
end

/* Start of merged MainMenuMod.lua */

function GUIMenuManager:GetPageInfo(name)
  return self.PageInfos[name]
end


function GUIMenuManager:RegisterPage(pageName, label, className)

  local exists = self.PageInfos[pageName]

  assert(not exists or not exists.OptionPage)

  if(not className) then
    className = pageName
  end

  if(not label) then
    label = pageName
  end

  self.PageInfos[pageName] = {Name = pageName, ClassName = className, OptionPage = false}
end

function GUIMenuManager:RegisterOptionPage(name, label, className)

  local exists = self.PageInfos[name]

  assert(not exists or exists.OptionPage == true)

 // if() then
 //   error("RegisterOptionPage: error a page named "..name.." already exists")
 // end

  if(not className) then
    className = name
  end

  if(not label) then
    label = name
  end

  local entry = {Name = name, Label = label, ClassName = className, OptionPage = true}
  
  self.PageInfos[name] = entry
  
  if(not exists) then
    self.OptionPageList[#self.OptionPageList+1] = name
  end
end

function GUIMenuManager:IsMenuOpen()
  return self.MainMenu ~= nil and not self.MainMenu.Hidden
end

GUIMenuManager.IsActive = GUIMenuManager.IsMenuOpen

function GUIMenuManager:CreateMessageBox()

  local Creator = _G[self.MessageBoxClass]
  
  assert(Creator)
  
  local success, msgBoxOrError = pcall(Creator)
  
  if(not success) then
    Print("Error while Creating MessageBox:%s", msgBoxOrError)
   return
  end
    
  self.IntenalMesssageBox = msgBoxOrError
  
  msgBoxOrError:Hide()
  msgBoxOrError.Parent = UIMenuParent
  
  msgBoxOrError:SetPoint("Center", 0, 0, "Center")
  
  self.AnchorFrame:AddChild(msgBoxOrError.RootFrame)
end

function GUIMenuManager:GetDefaultMessageBox()
  if(not self.IntenalMesssageBox) then
    self:CreateMessageBox()
  end
  
  return self.IntenalMesssageBox
end

function GUIMenuManager:ShowMessage(message, ...)  
  
  if(select('#', ...) ~= 0) then
    message = string.format(message, ...)
  end

  self.MessageBox = self:GetDefaultMessageBox()
  self.MessageBox:Open("SimpleMsg", message)
end

function GUIMenuManager:ShowMessageBox(messageBox)
  assert(messageBox.Close)
  
  self:CheckCloseMsgBox()

  if(messageBox.Parent ~= UIMenuParent) then 
    messageBox.Parent = UIMenuParent
    self.AnchorFrame:AddChild(messageBox.RootFrame)
  end
  
  messageBox:SetPoint("Center", 0, 0, "Center")

  self.MessageBox = messageBox
  messageBox:Show()
end

function GUIMenuManager:MesssageBoxClosed(messageBox)
  assert(self.MessageBox.Hidden)
  self.MessageBox = nil
end

function GUIMenuManager:CheckCloseMsgBox()

  local msgBox = self.MessageBox
 
  if(msgBox) then
    SafeCall(msgBox.Close, msgBox)
    
    self.MessageBox = nil
  end
end

function GUIMenuManager:CreateMenu()
  self.CreatedMenu = true
   
  local menuClass = _G[self.DefaultMenuClass]
  assert(menuClass)

  local success, menuOrErrorMsg = pcall(menuClass, Client.GetScreenWidth(), Client.GetScreenHeight())
  
  if(success) then
    self:SetMainMenu(menuOrErrorMsg)
  else
    Print("Error while Creating Menu:%s", menuOrErrorMsg)
  end
end

function GUIMenuManager:ShowMenu(message)
  
  if(not self.MainMenu) then
    if(not self.CreatedMenu) then
      self:CreateMenu()
    end
  else
    if(not self:IsMenuOpen()) then
      self.MainMenu:Show()
    end
  end
  
  self:Activate()
  
  MouseStateTracker:SetMainMenuState()
  
  if(message) then
    self:ShowMessage(message)
  end
  
  self.AnchorFrame:SetIsVisible(true)
  
  GameGUIManager:Deactivate()
end

function GUIMenuManager:CloseMenu()

  if(self:IsMenuOpen()) then
    self.MainMenu:Hide()
  end
  
  self:Deactivate()

  MouseStateTracker:ClearMainMenuState()

  self:CheckCloseMsgBox()
  
  self.AnchorFrame:SetIsVisible(false)
  
  GameGUIManager:Activate()
end

function GUIMenuManager:ReturnToMainPage()
  self:CheckCloseMsgBox()

  self.MainMenu:ReturnToMainPage()
end

function GUIMenuManager:ShowPage(page)
  self:CheckCloseMsgBox()

  self.MainMenu:ShowPage(page)
end

function GUIMenuManager:RecreatePage(pageName)
  self:CheckCloseMsgBox()

  self.MainMenu:RecreatePage(pageName)
end