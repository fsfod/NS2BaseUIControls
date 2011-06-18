
class 'ComboBox'(BaseControl)


function ComboBox:Initialize(width, height, itemList, labelCreator)

  BaseControl.Initialize(self, width, height)
  
  self:SetColor(0.1, 0.1, 0.1, 1)
  
  local button = ArrowButton(height, height, "Down")
    button:SetPoint("TopRight", 0, 0, "TopRight")
    button.OnClicked = {self.ToggleDropDown, self}
    self:AddChild(button)
  self.Button = button
    
  local itemText = GUIManager:CreateTextItem()
   itemText:SetFontSize(17)
   itemText:SetPosition(Vector(3, 0, 0))
    self.RootFrame:AddChild(itemText)
  self.ItemText = itemText
  
  self.DropDownOpen = false
  
  self.ItemList = itemList or {"test1", "test2", "test3", "test4", "test5"}
  
  self.LabelCache = {}
  
  self.GetItemLabel = labelCreator or self.GetItemLabel
  
  for i,data in ipairs(self.ItemList) do
    self.LabelCache[i] = self.GetItemLabel(data, i)
  end
  
  
  self:SetSelectedItem(1)
end

function ComboBox.GetItemLabel(item)
  
  if(type(item) == "string") then
    return item
  else
    return tostring(item)
  end
  
end

function ComboBox:SetLabel(str)
  
  local label = self.Label
  
  if(not label) then
    label = GUIManager:CreateTextItem()
    label:SetFontSize(17)
    self.Label = label
    self.RootFrame:AddChild(label)
  end
    
  label:SetText(str)
  label:SetPosition(Vector(-(label:GetTextWidth(str)+3), 0, 0))
end

function ComboBox:DropDownClosed()
  self.DropDownOpen = false
end

function ComboBox:OnClick(...)
 return self.ContainerOnClick(self, ...)
end


function ComboBox:SetSelectedItem(index, fromDropDown)
  
  self.SelectedIndex = index
  
  if(fromDropDown) then
    self.DropDownOpen = false
    
    self:FireEvent(self.ItemPicked, self.ItemList[index], index)
  end
  
  if(self.ItemList) then
    local item = self.ItemList[self.SelectedIndex]

    if(item) then
      self.ItemText:SetText(self.GetItemLabel(item))
    end
  end
end

local dropdown

function ComboBox:ToggleDropDown(down)
  
  if(not down) then
    return
  end
  
  if(not self.DropDownOpen) then
    
    if(not dropdown) then
      dropdown = DropDownMenu(self:GetWidth(), self:GetHeight()*7)
    end
    
    local pos = self:GetScreenPosition()
      dropdown:Open(self, self.LabelCache, self.SelectedIndex)
      dropdown:SetPosition(pos.x, pos.y+self:GetHeight()+3)
      
    
    self.DropDownOpen = true
  else
    dropdown:Close()
    
    self.DropDownOpen = false
  end
  
end

class 'DropDownMenu'(ListView)

function DropDownMenu:Initialize(width, height)
  ListView.Initialize(self, width, height)
  
  self.ItemSelected = {self.EntryPicked, self} 
  self:Hide()
end

function DropDownMenu:EntryPicked(data, index)
  self.Owner:SetSelectedItem(index, true)
  self:Close(true)
end

function DropDownMenu:Open(owner, list, index)
  
  self.Owner = owner
  self:SetSize(owner:GetWidth(), #list*self.ItemDistance)
  
  if(self.Hidden) then
    MouseTracker:AddFrame(self)
    MouseTracker:SetFocus(self)
    self:Show()
  else
    MouseTracker.UnregisterCallback(self, "MouseMove")
  end
  
  self:SetDataList(list)
end

function DropDownMenu:OnFocusLost(newFocus)
  self:Close()
end

function DropDownMenu:Close(fromClick)
  
  if(self.Hidden) then
    return
  end
  
  MouseTracker:CheckRemoveFrame(self)
  MouseTracker.UnregisterCallback(self, "MouseMove")
  
  self:Hide()
    
  if(not fromClick) then
    self.Owner:DropDownClosed()
  end
  
  self.Owner = nil
end

function DropDownMenu:Update()
  
  if(not self.Owner:IsShown()) then
    self:Close()
  end
end

function DropDownMenu:OnEnter()
  MouseTracker.RegisterCallback(self, "MouseMove")
  
  return self
end

function DropDownMenu:MouseMove(x, y)
	local hitrec = self.HitRec

  local index = self:GetItemAtCoords(x-hitrec[1], y-hitrec[2])

  if(index) then
    self:SetSelectedIndex(self.ViewStart+index-1)
  end
  
end

function DropDownMenu:OnLeave()
  MouseTracker.UnregisterCallback(self, "MouseMove")
end