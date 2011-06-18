
class 'ComboBox'(BorderedSquare)

function ComboBox:__init(width, height, itemList, labelCreator)
  BorderedSquare.__init(self, width, height, 2)
  
   self:SetBackgroundColor(Color(0.1, 0.1, 0.1, 0.85))
  
  local button = ArrowButton(height, height, "Down")
    button:SetPoint("TopRight", 0, 0, "TopRight")
    button.OnClicked = {self.ToggleDropDown, self}
    self:AddChild(button)
  self.Button = button

  local itemText = GUIManager:CreateTextItem()
   itemText:SetFontSize(17)
   itemText:SetPosition(Vector(4, 3, 0))
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

function ComboBox:SetLabel(str, offset, yOffset)
  BaseControl.SetLabel(self, str, offset, yOffset or 2)
end

function ComboBox.GetItemLabel(item)
  
  if(type(item) == "string") then
    return item
  else
    return tostring(item)
  end
  
end

function ComboBox:DropDownClosed()
  self.DropDownOpen = false
end

function ComboBox:OnClick(...)
 return self.ContainerOnClick(self, ...)
end

function ComboBox:SetValueFromConfig()
  self:SetSelectedItem(self.ConfigBinding:GetValue())
end

function ComboBox:ConfigValueChanged(newIndex)
  self:SetSelectedItem(newIndex)

  self:FireEvent(self.ItemPicked, self.ItemList[newIndex], newIndex)
end


function ComboBox:CheckCreateConfigConverter()

  local binding = self.ConfigBinding

  --add simple sane converter if one is not provided
  --this just looks through our item list for the value loaded from the config and returns the index
  if(not binding.ValueConverter) then
    binding.ValueConverter = function(value, index) 
      if(index) then
        return value
      else
        return table.find(self.ItemList, value)
      end
    end
  end
end

function ComboBox:SetConfigBinding(...)

  local binding = ConfigDataBind(...)
  self.ConfigBinding = binding

  self:CheckCreateConfigConverter()
  self:SetSelectedItem(binding:GetValue())

  return binding
end

function ComboBox:SetConfigBindingAndTriggerChange(...)

  local binding = ConfigDataBind(...)
  self.ConfigBinding = binding

  self:CheckCreateConfigConverter()
  self:ConfigValueChanged(binding:GetValue())

  return binding
end

function ComboBox:GetSelectedItem()
  
  if(self.SelectedIndex) then
    return self.ItemList[self.SelectedIndex]
  end
  
end

function ComboBox:SetSelectedItem(index, fromDropDown)
  
  self.SelectedIndex = index
  
  if(fromDropDown) then
    self.DropDownOpen = false
    
    if(self.ConfigBinding) then
      self.ConfigBinding:SetValue(self.ItemList[index], index)
    end
    
    self:FireEvent(self.ItemPicked, self.ItemList[index], index)
  end
  
  if(self.ItemList and self.SelectedIndex) then
    local item = self.ItemList[self.SelectedIndex]

    if(item) then
      self.ItemText:SetText(self.GetItemLabel(item))
    end
  else
    self.ItemText:SetText("")
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
      dropdown:Open(self, Vector(pos.x, pos.y+self:GetHeight()+3, 0), self.LabelCache, self.SelectedIndex)      
    
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

function DropDownMenu:Open(owner, position, list, index)

  self.Owner = owner

  local height = #list*self.ItemDistance
  local x,y = GUIManager.GetSpaceToScreenEdges(position)

  --make sure our list doesn't run offscreen
  if(height > y) then
    height = math.floor(y/self.ItemDistance)*self.ItemDistance
  end
  self:SetPosition(position)
  self:SetSize(owner:GetWidth(), height)

  if(self.Hidden) then
    GetGUIManager():AddFrame(self)
    GetGUIManager():SetFocus(self)
    self:Show()
  else
    GUIManager.UnregisterCallback(self, "MouseMove")
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
  
  GetGUIManager():CheckRemoveFrame(self)
  GUIManager.UnregisterCallback(self, "MouseMove")
  
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
  GUIManager.RegisterCallback(self, "MouseMove")
  
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
  GUIManager.UnregisterCallback(self, "MouseMove")
end