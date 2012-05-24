//
//   Created by:   fsfod
//

ControlClass('UpDownControl', BaseControl)

UpDownControl.ButtonWidth = 18

function UpDownControl:Initialize(options)
  BaseControl.Initialize(self, options.Width, options.Height)
  
  local numberBox = self:CreateControl("TextBox", width-((UpDownControl.ButtonWidth*2)+2), 20)
    numberBox:SetPoint("Center", -1, 0, "Center")
    numberBox.FocusLost = {self.CheckTextBoxValue, self}
  self.NumberBox = numberBox
  self:AddChild(numberBox)
    
  self.ClampFraction = options.ClampFraction
    
  self.MinValue = options.MinValue or 0
  self.MaxValue = options.MaxValue or 1
  self.StepSize = options.StepSize or 1
  self.Value = self.Min
  
  self:UpdateTextBox()

  local down = self:CreateControl("ArrowButton", UpDownControl.ButtonWidth, height+1, "Left")
    down:SetPoint("Left", 0, 1, "Left")
    down.OnClicked = {self.DownClick, self}
  self:AddChild(down)
  self.Down = down

  local up = self:CreateControl("ArrowButton", UpDownControl.ButtonWidth, height+1, "Right")
    up:SetPoint("Right", 0, 1, "Right")
    up.OnClicked = {self.UpClick, self}
  self:AddChild(up)
  self.Up = up
end

function UpDownControl:DownClick(isDown)
  if(isDown) then
    self:SetValue(self.Value-self.StepSize, true)
  end
end

function UpDownControl:UpClick(isDown)
  if(isDown) then
    self:SetValue(self.Value+self.StepSize, true)
  end
end

function UpDownControl:CheckTextBoxValue()
  local sucess, result = pcall(tonumber, self.NumberBox:GetText())
  
  if(not sucess or not result) then
    self.NumberBox:SetText(tostring(self.Value or self.MinValue))
   return false
  end
  
  self:SetValue(result, true)
end

function UpDownControl:UpdateTextBox()
  self.NumberBox:SetText(tostring(self.Value or 0))
end

function UpDownControl:OnMouseWheel(direction)

  //direction = direction/GetWheelScrollLineCount()

  self:SetValue(self.Value+(self.StepSize*direction), true)
end

function UpDownControl:SetValue(value, fromInput)

  if(self.ClampFraction) then
    if(math.floor(value) == self.Value) then
      self:UpdateTextBox()
     return
    else
      value = math.floor(value)
    end
  end

  self.Value = Clamp(value, self.MinValue, self.MaxValue)

  self:UpdateTextBox()

  if(fromInput) then
    self:FireEvent(self.ValueChanged, self.Value)
    
    if(self.ConfigBinding) then
      self.ConfigBinding:SetValue(self.Value)
    end
  end
end

function UpDownControl:SetValueFromConfig()
  self:SetValue(self.ConfigBinding:GetValue())
end

function UpDownControl:ConfigValueChanged(value)
  self:SetValue(value)
  self:FireEvent(self.ValueChanged, self.Value)
end