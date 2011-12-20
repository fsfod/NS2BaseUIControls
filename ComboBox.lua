//
//   Created by:   fsfod
//

ControlClass('ComboBox', BorderedSquare)

function ComboBox:Initialize(width, height, itemList, labelCreator)
  BorderedSquare.Initialize(self, width, height, 2)

   self:SetBackgroundColor(Color(0.1, 0.1, 0.1, 0.85))

  local button = self:CreateControl("ArrowButton", height, height, "Down")
    button:SetPoint("TopRight", 0, 0, "TopRight")
    button.OnClicked = {self.ToggleDropDown, self}
    self:AddChild(button)
  self.Button = button

  local itemText = self:CreateFontString(height)
   itemText:SetPosition(Vector(4.5, 1.5, 0))
    self:AddGUIItemChild(itemText)
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

local MenuDropDown, NormalDropDown

function ComboBox:ToggleDropDown(down)
  
  if(not down) then
    return
  end

  if(not self.DropDownOpen) then
    local dropdown
     
    //our dropdown could of been left belonging to another GUIManager like GameGUIManager that destroys all its frames so make sure we still have a valid dropdown if its created
    if(not NormalDropDown or not IsValidControl(NormalDropDown)) then
      NormalDropDown =  self:GetGUIManager():CreateWindow("DropDownMenu", self:GetWidth(), self:GetHeight()*7)
      
      local oldUninitialize = NormalDropDown.Uninitialize
      
      NormalDropDown.Uninitialize = function(self) 
        NormalDropDown = nil
        oldUninitialize(self) 
      end
      //self.DropDown = NormalDropDown
    end

    local pos = self:GetScreenPosition()
    
    NormalDropDown:Open(self, Vector(pos.x, pos.y+self:GetHeight()+3, 0), self.LabelCache, self.SelectedIndex)      
    
    self.DropDownOpen = true
  else
    NormalDropDown:Close()   
    self.DropDownOpen = false
  end
  
end