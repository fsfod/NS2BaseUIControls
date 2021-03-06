//
//   Created by:   fsfod
//

ControlClass('Slider', ScrollBar)

Slider:SetDefaultOptions{
  Height = 20,
  Width = 100,
  
  MinValue = 0,
  MaxValue = 1,
  StepSize = 1,
}

function Slider:InitFromTable(options)

  ScrollBar.Initialize(self, options.Width, options.Height)
  
  self.MinValue = ResolveToNumber(options.MinValue, self)
  self.MaxValue = ResolveToNumber(options.MaxValue, self)
  
  self:SetMinMax(self.MinValue, self.MaxValue)
  
  self.ValueChanged = ResolveToEventReceiver(options.ValueChanged, self)
  
  if(options.StepSize) then
    self:SetStepSize(ResolveToNumber(options.StepSize))
  end
end

function Slider:Initialize(options)
  ScrollBar.Initialize(self, options.Width, options.Height)
  
  self:SetColor(Color(0.15, 0.15, 0.15, 1))

  self:SetMinMax(options.MinValue or self.MinValue, options.MaxValue or self.MaxValue)
  
  if(options.StepSize) then
    self:SetStepSize(options.StepSize)
  end
end

function Slider:ShowAmountText()
  if(not self.AmountText) then
    self.AmountText = self:CreateFontString(18, "Top", 0, -24)  
    self.AmountText:SetTextAlignmentX(GUIItem.Align_Center)
  end
  
  self.AmountText:SetIsVisible(true)
end

function Slider:SetValueAndTiggerEvent(value)
  self:InteralSetValue(value, false, false)
end

function Slider:SetValueFromConfig()
  self:SetValue(self.ConfigBinding:GetValue())
end

function Slider:ConfigValueChanged(value)
  self:SetValue(value)
  self:FireEvent(self.ValueChanged, self.Value, false, self)
end

function Slider:BarDragEnded()

  if(self.NoValueChangedWhileDraging) then
    if(self.ConfigBinding) then
      self.ConfigBinding:SetValue(self.Value)
    end
    
    self:FireEvent(self.ValueChanged, self.Value, true, self)
  end
end


function Slider:InteralSetValue(value, fromSlider, noValueChangedEvent)

  if(self.ClampFraction) then
    if(math.floor(value) == self.Value) then
      return
    else
      value = math.floor(value)
    end
  end

  self.Value = Clamp(value, self.MinValue, self.MaxValue)

  if(not fromSlider) then
    self.Bar:SetValuePosition((self.Value-self.MinValue)/self.Range)
  end
  
  if(self.AmountText) then
    local text = (self.ValueConverter and self.ValueConverter(self.Value)) or string.format("%.2f", self.Value)
    
    self.AmountText:SetText(text)
  end

  if(not self.NoValueChangedWhileDraging or not fromSlider) then
    if(self.ConfigBinding) then
      self.ConfigBinding:SetValue(self.Value)
    end

    if(not noValueChangedEvent) then
      self:FireEvent(self.ValueChanged, self.Value, fromSlider, self)
    end
  end
end