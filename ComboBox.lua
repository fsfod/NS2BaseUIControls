//
//   Created by:   fsfod
//

ControlClass('ComboBox', BorderedSquare)

ComboBox:SetDefaultOptions{
  Height = 20,
  Width = 80,
  ItemList = {"test1", "test2", "test3", "test4", "test5"},

  LabelCreator = function(item)
    if(type(item) == "string") then
      return item
    else
      return tostring(item)
    end
  end,
}


function ComboBox:InitFromTable(options)
  ComboBox.Initialize(self, options)

  self.ItemPicked = ResolveToEventReceiver(options.ItemPicked, self)
end

function ComboBox:Initialize(options)
  local height = options.Height or self.Height
  
  BorderedSquare.Initialize(self, options.Width, height, 2)

  self:SetBackgroundColor(Color(0.1, 0.1, 0.1, 0.85))

  local button = self:CreateControl("ArrowButton", height-4, height-4, "Down")
    button:SetPoint("TopRight", 0, 2, "TopRight")
    button.OnClicked = {self.ToggleDropDown, self}
    self:AddChild(button)
  self.Button = button

  self.FontSize = height-2

  local itemText = self:CreateFontString(self.FontSize)
   itemText:SetPosition(Vector(4.5, 1.5, 0))
  self.ItemText = itemText
  
  self.DropDownOpen = false
  
  if(options.ItemList) then
    self.ItemList = ResolveToTable(options.ItemList, self)
  end
  
  self.LabelCache = {}

  if(options.ItemLabels) then
    local labelList = options.ItemLabels
    self.LabelCreator = function(data, i) return labelList[i] end
  else
    self.LabelCreator = ResolveToFunction(options.LabelCreator, self)
  
    for i,data in ipairs(self.ItemList) do
      self.LabelCache[i] = self.LabelCreator(data, i)
    end
  end


  
  self:SetSelectedItem(1)
end

function ComboBox:SetLabel(str, offset, yOffset)
  BaseControl.SetLabel(self, str, offset, yOffset or 2)
end

function ComboBox:SetItemList(list)
  assert(list == nil or type(list) == "table")

  self.SelectedIndex = nil
  self.ItemText:SetText("")
  
  self.ItemList = list or {}
  self.LabelCache = nil
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

function ComboBox:OnMouseWheel(direction)
  
  local newIndex = Clamp((self.SelectedIndex or 1)+(-direction), 1, #self.ItemList)

  //don't try to select the next entry if the dropdown is open
  if(not self.DropDownOpen and newIndex ~= self.SelectedIndex) then
    self:SetSelectedItem(newIndex, true)
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
      self.ItemText:SetText(self.LabelCreator(item, self.SelectedIndex))
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
    
    if(not self.LabelCache) then
      self.LabelCache = {}
      
      for i,data in ipairs(self.ItemList) do
        self.LabelCache[i] = self.LabelCreator(data, i)
      end
    end
    
    NormalDropDown:Open(self, Vector(pos.x, pos.y+self:GetHeight()+3, 0), self.LabelCache, self.SelectedIndex)      
    
    self.DropDownOpen = true
  else
    NormalDropDown:Close()   
    self.DropDownOpen = false
  end
  
end