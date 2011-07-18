local HotReload = GUIMenuManager

local UIMenuParent

if(not HotReload) then

GUIMenuManager = {
  Name = "GUIMenuManager",
  MenuLayer = 20,
  DefaultMenuClass = "GUIMainMenu",

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
}

GUIMenuManager.TopLevelUIParent = UIMenuParent
end

function GUIMenuManager:Initialize()
  BaseGUIManager.Initialize(self)
  
  self.AchorSize = Vector(Client.GetScreenWidth(), Client.GetScreenHeight(), 0)
  UIMenuParent.Size = self.AchorSize 

  local anchorFrame = GUI.CreateItem()

  anchorFrame:SetColor(Color(0, 0, 0, 0))
  anchorFrame:SetSize(self.AchorSize)
  anchorFrame:SetLayer(self.MenuLayer)

  self.AnchorFrame = anchorFrame
  UIMenuParent.RootFrame = anchorFrame
end

local msgBoxTable = {}

function GUIMenuManager:GetFrameList()
  if(self.MsgBox) then
    msgBoxTable[1] = self.MsgBox

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

function GUIMenuManager:ShowMessage(Message, ...)  
  local msgString = Message
  
  if(select('#', ...) ~= 0) then
    msgString = string.format(Message, ...)
  end

  self.MsgBox = self.DefaultMsgBox
  self.MsgBox:Open("SimpleMsg", msgString)
end

function GUIMenuManager:ShowMessageBox(msgBox)
  self:CheckCloseMsgBox()
  
  if(msgBox.Parent ~= UIParent) then
    self:ParentToMainMenu(msgBox)
  end
  
  msgBox:SetPoint("Center", 0, 0, "Center")

  self.MsgBox = msgBox
  msgBox:Show()
end

function GUIMenuManager:MsgBoxClosed()
  assert(self.MsgBox.Hidden)
  self.MsgBox = nil
end

function GUIMenuManager:CheckCloseMsgBox()

  local msgBox = self.MsgBox
 
  if(msgBox) then
    SafeCall(msgBox, msgBox.Close)
    msgBox = nil
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
  
  MouseStateTracker:SetMainMenuState()
  
  if(message) then
    self:ShowMessage(message)
  end
end

function GUIMenuManager:CloseMenu()

  if(self:IsMenuOpen()) then
    self.MainMenu:Hide()
  end

  MouseStateTracker:ClearMainMenuState()

  self:CheckCloseMsgBox()
end

function GUIMenuManager:ReturnToMainPage()
  self:CheckCloseMsgBox()

  self.MainMenu:ReturnToMainPage()
end

function GUIMenuManager:SwitchToPage(page)
  self:CheckCloseMsgBox()

  self.MainMenu:SwitchToPage(page)
end

function GUIMenuManager:RecreatePage(pageName)
  self:CheckCloseMsgBox()

  self.MainMenu:RecreatePage(pageName)
end