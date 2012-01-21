//
//   Created by:   fsfod
//

local HotReload = GUIMenuManager

local UIMenuParent

if(not HotReload) then

GUIMenuManager = {
  Name = "GUIMenuManager",
  MenuLayer = 20,
  MenuClass = "PagedMainMenu",
  MessageBoxClass = "MessageBox",
  
  WindowedModeActive = false,

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
  Flags = 0,
  ChildFlags = 255,
  GetGUIManager = function() return GUIMenuManager end,
  UIParent = true,
}

GUIMenuManager.TopLevelUIParent = UIMenuParent

else
  UIMenuParent = GUIMenuManager.TopLevelUIParent
end



function GUIMenuManager:Initialize()
  BaseGUIManager.Initialize(self)

  Event.Hook("ClientConnected", function() self:OnClientConnected() end)
  Event.Hook("ClientDisconnected", function(reason) self:OnClientDisconnected(reason) end)

  self:SetHooks()
end

function GUIMenuManager:LoadComplete(disconnectMsg)

  self.DisconnectMessage = disconnectMsg

  self.MenuClass = Client.GetOptionString("MainMenuClass", "ClassicMenu")
  
  self:CreateAnchorFrame(Client.GetScreenWidth(), Client.GetScreenHeight(), self.MenuLayer)
  
  UIMenuParent.Size = Vector(Client.GetScreenWidth()/UIScale, Client.GetScreenHeight()/UIScale, 0)

  self.CurrentWindowLayer = self.MenuLayer+1
end

function GUIMenuManager:UpdateScale()

  local width, height = Client.GetScreenWidth()/UIScale, Client.GetScreenHeight()/UIScale

  UIMenuParent.Size = Vector(width, height, 0)

  if(#self.AllFrames > 1) then

    //skip the mainmenu
    for i=2,#self.AllFrames do
      local frame = self.AllFrames[i]
      
      frame:Rescale()
      frame:ParentSizeChanged()
    end
  end

  if(self.MainMenu) then
    
    self.MainMenu:SetSize(width, height)

    for i,frame in ipairs(self.MainMenu.ChildControls) do
      frame:Rescale()
      frame:ParentSizeChanged()
    end
  end
  
  return
end

function GUIMenuManager:OnResolutionChanged(oldX, oldY, width, height)

  if(self.AnchorFrame) then
    self.AnchorFrame:SetSize(Vector(width, height, 0))
  end

  width, height = width/UIScale, height/UIScale

  UIMenuParent.Size = Vector(width, height, 0)

  if(#self.AllFrames > 1) then

    //skip the mainmenu
    for i=2,#self.AllFrames do
      local frame = self.AllFrames[i]
      
      frame:Rescale()
      frame:OnResolutionChanged(oldX, oldY, width, height)
    end
  end

  if(self.MainMenu) then
    local onResolutionChanged = self.MainMenu.OnResolutionChanged

    if(onResolutionChanged) then
      SafeCall(onResolutionChanged, self.MainMenu, oldX, oldY, width, height)
    else
      //if the menu doesn't have a on OnResolutionChanged fallback to just adjusting its size
      self.MainMenu:SetSize(width, height)
    end
     
    //FIXME should really handle this better since we scale the size of the menu directly so that it size is increased when we decrease scale
    for i,frame in ipairs(self.MainMenu.ChildControls) do
      frame:Rescale()
    end
  end
end

function GUIMenuManager:OnClientConnected()
 
  if(self.MainMenu and self.MainMenu.OnClientConnected) then
    self.MainMenu:OnClientConnected()
  end
end

function GUIMenuManager:OnClientDisconnected(reason)
 
  if(self.MainMenu and self.MainMenu.OnClientDisconnected) then
    self.MainMenu:OnClientDisconnected()
  end

/*
  if(not StartupLoader.IsMainVM) then
    Client.SetOptionInteger("menumod/DisconnectTime",  Shared.GetSystemTime())
    Client.SetOptionString("menumod/DisconnectReason", reason)
  end
*/
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
    //self.AllFrames[1] will always contain self.MainMenu
    return self.AllFrames
  end
end

function GUIMenuManager:SetMainMenu(menuFrame)
  
  if(self.MainMenu) then
    table.removevalue(self.AllFrames, self.MainMenu)
    table.removevalue(self.NonWindowList, self.MainMenu)
  end

  menuFrame.Parent = UIMenuParent
  menuFrame:SetPosition(0, 0)

  self.MainMenu = menuFrame

  table.insert(self.NonWindowList, 1, menuFrame)
  table.insert(self.AllFrames, 1, menuFrame)
end

function GUIMenuManager:IsMainMenuChild(frame)
  return true
end

/* Start of merged MainMenuMod.lua */

function GUIMenuManager:GetPageInfo(name)
  return self.PageInfos[name]
end

function GUIMenuManager:IsOptionPage(name)
  local info = self.PageInfos[name]
  
  return info and info.OptionPage
end

function GUIMenuManager:GetPageList()

  local list = {}

  for name, info in pairs(self.PageInfos) do
    table.insert(list, name)
  end

  return list
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

  self.PageInfos[pageName] = {Name = pageName, Label = label, ClassName = className, OptionPage = false}
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

function GUIMenuManager:ShowMessage(title, message, ...)  

  if(select('#', ...) ~= 0) then
    message = string.format(message, ...)
  end

  local msgBox = self:CreateWindow(self.MessageBoxClass, title, message)
  
  if(msgBox) then
    msgBox:SetPoint("Center", 0, 0, "Center")
  else
    RawPrint(message)
  end
end

function GUIMenuManager:CheckCloseMsgBox()

  local msgBox = self.MessageBox
 
  if(msgBox) then
    SafeCall(msgBox.Close, msgBox)
    
    self.MessageBox = nil
  end
end

function GUIMenuManager:GetMenu()
  return self.MainMenu
end

function GUIMenuManager:CreateMenu()
  self.CreatedMenu = true

  local menuClass = _G[self.MenuClass]
  assert(menuClass)

  local success, menuOrErrorMsg = pcall(CreateControl, self.MenuClass)
  
  if(success) then
    //menuOrErrorMsg.SetSize = function(self, size) GUIItem.SetSize(self, size*UIScale) end
    //menuOrErrorMsg.SetPosition = function(self, position) GUIItem.SetPosition(self, position*UIScale) end
   
    self.Callbacks:Fire("PreMenuCreate", menuOrErrorMsg)
   
    menuOrErrorMsg:Initialize(Client.GetScreenWidth()/UIScale, Client.GetScreenHeight()/UIScale)
    //GUIItem.SetSize(menuOrErrorMsg, Vector(Client.GetScreenWidth(), Client.GetScreenHeight(), 0))

    self:SetMainMenu(menuOrErrorMsg)

    self.Callbacks:Fire("MenuCreated", menuOrErrorMsg)
  else
    Print("Error while Creating Menu:%s", menuOrErrorMsg)
   return false
  end
  
  return true
end

function GUIMenuManager:SwitchMainMenu(newMenu)
  assert(type(newMenu) == "string")

  if(self.CreatedMenu) then  
    self:RecreateMenu()
  end
    
  Client.SetOptionString("MainMenuClass", newMenu)
  
  self.MenuClass = newMenu
end

function GUIMenuManager:RecreateMenu()
  //don't instantly recreate it since it could of been called by a buttons on click
  self.AsyncRecreate = true
end

function GUIMenuManager:InternalRecreateMenu()
  self.MainMenu = nil
  self.CreatedMenu = false

  self.MessageBox = nil
  self.IntenalMesssageBox = nil
  
  self:DestroyAllFrames()
  
  self:CreateAnchorFrame(Client.GetScreenWidth(), Client.GetScreenHeight(), self.MenuLayer)

  UIMenuParent.Size = Vector(Client.GetScreenWidth()/UIScale, Client.GetScreenHeight()/UIScale, 0)
  
  if(self:CreateMenu()) then
    self.AnchorFrame:SetIsVisible(true)
  end

  self.CurrentWindowLayer = self.MenuLayer+1

  //retrigger any mouseover stuff for the new menu
  self:OnMouseMove()
end

function GUIMenuManager:Update()
  BaseGUIManager.Update(self)

  if(self.AsyncRecreate) then
    //clear it before the call incase it fails so were not constantly trying to recreate
    self.AsyncRecreate = nil
    
    self:InternalRecreateMenu()
  end
end

function GUIMenuManager:InternalShow()
  self.Hidden = false
  
  if(self.AnchorFrame) then
   self.AnchorFrame:SetIsVisible(true)
  end
end

function GUIMenuManager:InternalHide()

  self.Hidden = true
  
  if(self.AnchorFrame) then
   self.AnchorFrame:SetIsVisible(false)
  end
end

function GUIMenuManager:MenuStartup()
  self:HookFunction("LeaveMenu", function() self:InternalCloseMenu() end, InstantHookFlag)
  
  self.MenuStartupDone = true
 
  //Client.PrecacheLocalSound("sound/ns2.fev/music/main_menu")
end

function GUIMenuManager:ShowMenu(message)
  
  if(not self.MenuStartupDone) then
    self:MenuStartup()
  end
  
  if(not self.MainMenu) then
    if(not self.CreatedMenu) then
      self:CreateMenu()
    end
  else
    if(not self:IsMenuOpen()) then
      self.MainMenu:Show()
    end
  end

  MainMenu_Loaded()

  self:Activate()

  MouseStateTracker:SetMainMenuState()


  if(self.DisconnectMessage) then
    
    self:ShowMessage("Disconnected From Server", self.DisconnectMessage)
    self.DisconnectMessage = nil
    
  else
    
    if(message) then
      self:ShowMessage("", message)
    end
  end

  self:InternalShow()
  
  GameGUIManager:Deactivate()
end



function GUIMenuManager:CloseMenu()

  //our hooks from these functions will call InternalCloseMenu
  if(self:IsMenuOpen()) then
    
    if(Client.GetIsConnected()) then
      MainMenu_ReturnToGame()
    else
      LeaveMenu()
    end
    
  else
    //normally this call should should effectivly do nothing
    self:InternalCloseMenu()
  end
end

function GUIMenuManager:InternalCloseMenu()

  if(self:IsMenuOpen()) then
    self.MainMenu:Hide()
  end

  self:Deactivate()

  MouseStateTracker:ClearMainMenuState()

  self:CheckCloseMsgBox()
  
  self:InternalHide()
  
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

  if(self.MainMenu) then
    self.MainMenu:RecreatePage(pageName)
  end
end

if(not HotReload) then
  Event.Hook("Console_showmenu", function() GUIMenuManager:ShowMenu() end)
  Event.Hook("Console_hidemenu", function() GUIMenuManager:CloseMenu() end)
end