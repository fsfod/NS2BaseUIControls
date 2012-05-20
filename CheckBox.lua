//
//   Created by:   fsfod
//

ControlClass('CheckBox', BaseControl)

local Orange = Color(0.8666, 0.3843, 0, 1)
local DimOrange = Color(0.8666/3, 0.3843/3, 0, 1)


function CheckBox:Initialize(options)
  local label = options.Label or "Some text 1111z"
  
  self.FontSize = options.FontSize or 20

  local labeltxt = self:CreateFontString(self.FontSize)
   labeltxt:SetText(label)

  local width = labeltxt:GetTextWidth(label)
  local height = labeltxt:GetTextHeight(label)+4
  self.Label = labeltxt

  BaseControl.Initialize(self, height, height)
  
  self:SetLabelOnLeft(options.LabelOnLeft)

  self.Checked = options.Checked or false
  
  self:SetColor(0, 0, 0, 0)
  
  local button = self:CreateControl("CheckButton", height, self.Checked)
    self:AddChild(button)
  self.Button = button
end

function CheckBox:SetLabelOnLeft(labelOnLeft)
   self.LabelOnLeft = labelOnLeft
   self:UpdateLabelPosition()
end

function CheckBox:UpdateLabelPosition()
   
  local label = self.Label 
   
  if(self.LabelOnLeft) then
    label:SetPoint("Left", -4, 2, "Right")
  else
    label:SetPoint("Right", 4, 2, "Left")
  end
end

function CheckBox:OnCheckedToggled()
  self.Checked = not self.Checked
  
  if(self.ConfigBinding) then
    self.ConfigBinding:SetValue(self.Checked)
  end
  
  self:FireEvent(self.CheckChanged, self.Checked)

  return self.Checked
end

function CheckBox:ConfigValueChanged(checked)
  self:SetChecked(checked)
  self:FireEvent(self.CheckChanged, self.Checked)
end

function CheckBox:SetValueFromConfig()
  self:SetChecked(self.ConfigBinding:GetValue())
end

function CheckBox:SetChecked(checked)
  self.Checked = checked
  
  self.Button:SetCheckedState(checked)
end

function CheckBox:IsChecked()
  return self.Checked
end

ControlClass('CheckButton', BaseControl)

function CheckButton:Initialize(height, checked)
  BaseControl.Initialize(self, height, height)
  ButtonMixin.Initialize(self)

  local cross = self:CreateGUIItem()
    cross:SetSize(Vector(height, height, 0))
    cross:SetColor(Orange)
    cross:SetTexture("ui/checkbox.dds")
  self.Cross = cross
  
  self:SetCheckedState(checked or false)
  
  local border = self:CreateGUIItem()
    border:SetSize(Vector(height, height, 0))
    border:SetColor(ControlGrey1)
    border:SetTexture("ui/checkbox.dds")
    border:SetTexturePixelCoordinates(0, 0, 63, 64)
  self.Border = border
  
  self:SetColor(Color(0, 0, 0, 0))
end

function CheckButton:OnLeave()
  self.Border:SetColor(ControlGrey1)
end

function CheckButton:OnEnter()
  self.Border:SetColor(DimOrange)
end

function CheckButton:SetCheckedState(checked)
  local cross = self.Cross
  
  self.Checked = checked
  
  if(checked) then
    cross:SetTexturePixelCoordinates(128, 0, 128+64, 64)
    cross:SetColor(ControlDarkOrange)
  else
    cross:SetTexturePixelCoordinates(192, 0, 256, 64)
    cross:SetColor(PageBgColour)
  end
end

function CheckButton:OnClick(button, down)
  if(down and button == InputKey.MouseButton0) then
    
    local checked = self.Parent:OnCheckedToggled(self)
    
    self:SetCheckedState(checked)
    
    if(checked) then
      PlayerUI_PlayCheckboxOnSound()
    else
      PlayerUI_PlayCheckboxOffSound()
    end
  end
end