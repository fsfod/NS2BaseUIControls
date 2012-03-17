//
//   Created by:   fsfod
//

ControlClass('DropDownMenu', ListView)

function DropDownMenu:Initialize(width, height)
  ListView.Initialize(self, width, height, nil, 16, 4)
  
  self:AddFlag(ControlFlags.IsWindow)
  
  self.ItemSelected = {self.EntryPicked, self}
  self.Hidden = true
  
  self:SetColor(0, 0, 0, 1)
  //self:Hide()
end

function DropDownMenu:EntryPicked(data, index)
  self.Owner:SetSelectedItem(index, true)
  self:Close(true)
end

function DropDownMenu:CheckUnparent()

  local current = self:SafeGetGUIManager()

  if(current) then
    current:RemoveFrame(self)
  end
end

function DropDownMenu:Open(owner, position, list, index)

  local GUIMgr = owner:GetGUIManager()

  self:CheckUnparent()
  GUIMgr:AddFrame(self)

  self.Owner = owner
  self.ViewStart = 1

  local height = #list*self.ItemDistance
  local x,y = GUIMgr:GetSpaceToScreenEdges(position)

  --make sure our list doesn't run offscreen
  if(height > y) then
    height = math.floor(y/self.ItemDistance)*self.ItemDistance
  end
  
  self:SetPosition(position)
  self:SetSize(owner:GetWidth(), height)

  if(self.Hidden) then
    self:Show()
    
    GUIMgr:SetFocus(self)
  else
   // self:UnregisterForMouseMove()
  end

  /*
  if(GUIMgr:IsMainMenuChild(owner)) then
    GUIMgr:ParentToMainMenu(self)
  end
  */
  self:Show()
  
  self:SetDataList(list)
end

function DropDownMenu:OnFocusLost(newFocus)
  self:Close()
end

function DropDownMenu:Close(fromClick)
  
  if(self.Hidden) then
    return
  end

  self:UnregisterForMouseMove()

  self:Hide()

  if(IsValidControl(self.Owner)) then
    self.Owner:DropDownClosed()
  end
  self.Owner = nil

  local GUIMgr = self:SafeGetGUIManager()

  //default to parenting to GUIMenuManager so we get any scale updates
  if(GUIMgr == nil) then    
    GUIMenuManager:AddWindow(self)
  end
end

function DropDownMenu:Update()
  
  if(self.Owner and (not IsValidControl(self.Owner) or not self.Owner:IsShown())) then
    self:Close()
  end
end

function DropDownMenu:OnEnter()
  self:RegisterForMouseMove()
end

function DropDownMenu:MouseMove(x, y)
  local hitrec = self.HitRec

  local index = self:GetItemAtCoords(x-hitrec[1], y-hitrec[2])

  if(index) then
    self:SetSelectedIndex(self.ViewStart+index-1)
  end
  
end

function DropDownMenu:OnLeave()
  self:UnregisterForMouseMove()
end

function DropDownMenu:SendKeyEvent(key, down, isRepeat)

  if not self.Hidden and down and key == InputKey.Escape then
    self:Close(true)    
   return true
  end
  
  return false
end

function DropDownMenu:Uninitialize()
  
  if(self.Entered) then
    self:UnregisterForMouseMove()
  end
  
  if(self.Owner) then
    self.Owner:DropDownClosed()
  end
  
  ListView.Uninitialize(self)
end
