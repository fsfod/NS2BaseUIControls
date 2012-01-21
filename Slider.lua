//
//   Created by:   fsfod
//

ControlClass('Slider', ScrollBar)

function Slider:Initialize(width, height, minValue, maxValue)
  ScrollBar.Initialize(self, width, height)
  
  self:SetColor(Color(0.15, 0.15, 0.15, 1))

  if(minValue) then
    self:SetMinMax(minValue, maxValue)
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
  self:FireEvent(self.ValueChanged, self.Value)
end

function Slider:BarDragEnded()

  if(self.NoValueChangedWhileDraging) then
    if(self.ConfigBinding) then
      self.ConfigBinding:SetValue(self.Value)
    end
    
    self:FireEvent(self.ValueChanged, self.Value)
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
      self:FireEvent(self.ValueChanged, self.Value, fromSlider)
    end
  end
end