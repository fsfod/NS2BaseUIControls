class 'UpDownControl'(BaseControl)

UpDownControl.ButtonWidth = 18

function UpDownControl:__init(width, height, min, max)
  BaseControl.Initialize(self, width, height)
  
  local numberBox = TextBox(width-(UpDownControl.ButtonWidth*2) , 20)
    numberBox:SetPoint("Center", 0, 0, "Center")
    numberBox.FocusLost = {self.CheckTextBoxValue, self}
  self.NumberBox = numberBox
  self:AddChild(numberBox)
    
  self.MinValue = min or 0
  self.MaxValue = max or 1
  self.Value = self.Min
  
  local down = ArrowButton(UpDownControl.ButtonWidth, 20, "Left")
    down:SetPoint("Left", 0, 0, "Left")
    down.OnClicked = {self.DownClick, self}
  self:AddChild(down)
  self.Down = down
  
  local up = ArrowButton(UpDownControl.ButtonWidth, 20, "Right")
    up:SetPoint("Right", 0, 0, "Right")
    up.OnClicked = {self.UpClick, self}
  self:AddChild(up)
  self.Up = up
end

function UpDownControl:DownClick(isDown)
  if(isDown) then
    self:SetValue(self.Value-1, true)
  end
end

function UpDownControl:UpClick(isDown)
  if(isDown) then
    self:SetValue(self.Value+1, true)
  end
end

function UpDownControl:CheckTextBoxValue()
  local sucess, result = pcall(tonumber, self.NumberBox:GetText())
  
  if(not sucess) then
    self.NumberBox:SetText(tostring(self.Value))
   return false
  end
  
  self:SetValue(result, true)
end

function UpDownControl:SetValue(value, fromInput)
 
  if(self.ClampFraction) then
    if(math.floor(value) == self.Value) then
      return
    else
      value = math.floor(value)
    end
  end

  self.Value = Clamp(value, self.MinValue, self.MaxValue)

  self.NumberBox:SetText(tostring(self.Value))
  
  if(fromInput) then
    self:FireEvent(self.ValueChanged, self.Value)
  end
end

function UpDownControl:SetValueFromConfig()
  self:SetValue(self.ConfigBinding:GetValue())
end

function UpDownControl:ConfigValueChanged(value)
  self:SetValue(value)
  self:FireEvent(self.ValueChanged, self.Value)
end