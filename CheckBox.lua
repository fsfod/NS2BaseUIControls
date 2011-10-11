ControlClass('CheckBox', BaseControl)

local Orange = Color(0.8666, 0.3843, 0, 1)
local DimOrange = Color(0.8666/3, 0.3843/3, 0, 1)

local grey = Color(0.133, 0.149, 0.1529, 1)


function CheckBox:Initialize(label, checked, labelOnLeft, fontsize)
  label = label or "Some text 1111z"
  
  self.FontSize = fontsize or 17
  
  local labeltxt = GUIManager:CreateTextItem()
   labeltxt:SetFontSize(self.FontSize)
   labeltxt:SetText(label)
  
  local width = labeltxt:GetTextWidth(label)
  local height = labeltxt:GetTextHeight(label)+4
  self.Label = labeltxt

  BaseControl.Initialize(self, width, height)
  self:AddGUIItemChild(labeltxt)
  
  self:SetLabelOnLeft(labelOnLeft)

  self.Checked = checked or false
  
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
  local height = self:GetHeight()
  local width = label:GetTextWidth(label:GetText())
   
  if(self.LabelOnLeft) then
    label:SetPosition(Vector(-(width+4), 2, 0))
  else
    label:SetPosition(Vector(height+3, 2, 0))
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

  local cross = GUIManager:CreateGraphicItem()
    cross:SetSize(Vector(height, height, 0))
    cross:SetColor(Orange)
    cross:SetTexture("ui/checkbox.dds")
  self:AddGUIItemChild(cross)
  self.Cross = cross
  
  self:SetCheckedState(checked or false)
  
  local border = GUIManager:CreateGraphicItem()
    border:SetSize(Vector(height, height, 0))
    border:SetColor(grey)
    border:SetTexture("ui/checkbox.dds")
    border:SetTexturePixelCoordinates(0, 0, 63, 64)
  self.Border = border
  self:AddGUIItemChild(border)
  
  self:SetColor(Color(0, 0, 0, 0))
end

function CheckButton:OnLeave()
  self.Border:SetColor(grey)
end

function CheckButton:OnEnter()
  self.Border:SetColor(DimOrange)
end

function CheckButton:SetCheckedState(checked)
  local cross = self.Cross
  
  self.Checked = checked
  
  if(checked) then
    cross:SetTexturePixelCoordinates(128, 0, 128+64, 64)
    cross:SetColor(Color(0.8666/1.5, 0.3843/1.5, 0, 1))
  else
    cross:SetTexturePixelCoordinates(192, 0, 256, 64)
    cross:SetColor(Color(0.07, 0.07, 0.07, 1))
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