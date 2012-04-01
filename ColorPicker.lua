//
//   Created by:   fsfod
//

ControlClass("ColorPicker", BorderedSquare)

function ColorPicker:Initialize(width, height)
  
  if(not width) then
    width = 45
    height = 20
  end
  BorderedSquare.Initialize(self, width, height, 2)
  
  self.Color = Color()
end

function ColorPicker:SetCurrentColor(color)
  self.Color = color
  self:SetColor(color)
end

function ColorPicker:OnColourChanged(colour)
  self:SetColor(colour)
  
  self.Color = colour

  self:FireEvent(self.ColourChanged, self.Color)
end

function ColorPicker:OnClick(button, down)

  if(button == InputKey.MouseButton0 and down) then
    local picker = self:GetGUIManager():CreateWindow("ColorPickerPopup")
  
    picker:SetPosition(self:GetScreenPosition()+Vector(self:GetWidth(), -(picker:GetHeight()/2), 0))
    
    picker.Owner = self
    picker:SetCurrentColor(self.Color)
  end
end

ControlClass("ColorPickerPopup", BorderedSquare)

ColorPickerPopup.FormatString = "%.5g"
ColorPickerPopup.BarOffset = 54
ColorPickerPopup.Height = 115
ColorPickerPopup.Width = 290


function ColorPickerPopup:Initialize(width, height)
  
  if(not width) then
    width = self.Width
    height = self.Height
  end
  
  BorderedSquare.Initialize(self, width, height, 3)
  
  self:SetDraggable()
  self:AddFlag(ControlFlags.IsWindow)
  
  self.Color = Color(0.1, 0.1, 0.1, 1)

  local barWidth = width-(self.BarOffset+50)

  local red = self:CreateControl("Slider", barWidth, 20, 0, 255)
    red:SetLabel("Red")
    red:SetPosition(self.BarOffset, 20)
    red.ValueChanged = function(value)
      self:ColorValueChanged(math.floor(value))
    end
  self:AddChild(red)
  self.RedBar = red
  
  local green = self:CreateControl("Slider", barWidth, 20, 0, 255)
    green:SetLabel("Green")
    green:SetPosition(self.BarOffset, 50)
    green.ValueChanged = function(value)
      self:ColorValueChanged(nil, math.floor(value))
    end
  self:AddChild(green)
  self.GreenBar = green
  
  local blue = self:CreateControl("Slider", barWidth, 20, 0, 255)
    blue:SetLabel("Blue")
    blue:SetPosition(self.BarOffset, 80)
    blue.ValueChanged = function(value)
      self:ColorValueChanged(nil, nil, math.floor(value))
    end
  self:AddChild(blue)
  self.BlueBar = blue
  
  local redNum = self:CreateControl("TextBox", 40, 20)
    redNum:SetPoint("TopRight", -6, 20, "TopRight")
    
    redNum.TextChanged = function()
      local result = redNum:TryParseNumber(false, 0, 255)

      if(result) then
        self:ColorValueChanged(result, nil, nil)
      end
    end
    
  self:AddChild(redNum)
  self.RedNumber = redNum
  
  local greenNum = self:CreateControl("TextBox", 40, 20)
    greenNum:SetPoint("TopRight", -6, 50, "TopRight")
    
    greenNum.TextChanged = function()
      local result = greenNum:TryParseNumber(false, 0, 255)

      if(result) then
        self:ColorValueChanged(nil, result, nil)
      end
    end
    
  self:AddChild(greenNum)
  self.GreenNumber = greenNum
  
  local blueNum = self:CreateControl("TextBox", 40, 20)
    blueNum:SetPoint("TopRight", -6, 80, "TopRight")
    
    blueNum.TextChanged = function()
      local result = blueNum:TryParseNumber(false, 0, 255)

      if(result) then
        self:ColorValueChanged(nil, nil, result)
      end
    end
   
  self:AddChild(blueNum)
  self.BlueNumber = blueNum
  
  self.ColorBox = self
  
  self:ColorValueChanged(1, 1, 1)
end

function ColorPickerPopup:SetCurrentColor(colour)
  self:ColorValueChanged(colour.r*255, colour.g*255, colour.b*255, true)
end

function ColorPickerPopup:Update()
 
  if(self.Hidden) then
    return
  end
 
  if(not self.Owner or not IsValidControl(self.Owner) or not self.Owner:IsShown()) then
    self.Owner = nil
    self:Hide()
   return
  end
end

function ColorPickerPopup:ColorValueChanged(r, g, b, notFromInput)

  if(r) then    
    self.RedBar:SetValue(r)
    
    //don't update the text if the color value is the same since the user might be deleting a 0 or a dot
    if(self.Color.r ~= r/255) then    
     self.RedNumber:SetText(string.format(self.FormatString, r))
    end
    
    self.Color.r = r/255
  end

  if(g) then    
    self.GreenBar:SetValue(g)
    

    //don't update the text if the color value is the same since the user might be deleting a 0 or a dot
    if(self.Color.g ~= g/255) then
      self.GreenNumber:SetText(string.format(self.FormatString, g))
    end
    
    self.Color.g = g/255
  end
  
  if(b) then
    self.BlueBar:SetValue(b)
    
    //don't update the text if the color value is the same since the user might be deleting a 0 or a dot
    if(self.Color.b ~= b/255) then
     self.BlueNumber:SetText(string.format(self.FormatString, b))
    end
    
    self.Color.b = b/255
  end
  
  self:SetColor(self.Color)
  
  if(not notFromInput) then

    if(self.Owner) then
      self.Owner:OnColourChanged(self.Color)
    end
  end
end