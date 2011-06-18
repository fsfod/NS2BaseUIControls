class 'CheckBox'(BaseControl)
ButtonMixin:Mixin(CheckBox)

local Orange = Color(0.8666, 0.3843, 0, 1)
local DimOrange = Color(0.8666/3, 0.3843/3, 0, 1)

local grey = Color(0.133, 0.149, 0.1529, 1)

function CheckBox:Initialize(width, height, checked)
  BaseControl.Initialize(self, width, height)
  ButtonMixin.__init(self)

  local cross = GUIManager:CreateGraphicItem()
    cross:SetSize(Vector(width, height, 0))
	  cross:SetColor(Orange)
	  cross:SetTexture("ui/checkbox.png")
	self.RootFrame:AddChild(cross)
  self.Cross = cross
  
  self:InternalSetChecked(checked or false)
  
   local border = GUIManager:CreateGraphicItem()
    border:SetSize(Vector(width, height, 0))
	  border:SetColor(grey)
	  border:SetTexture("ui/checkbox.png")
	  border:SetTexturePixelCoordinates(0, 0, 63, 64)
	self.Border = border
	self.RootFrame:AddChild(border)
  
  self:SetColor(Color(0, 0, 0, 0))
end

function CheckBox:OnLeave()
  self.Border:SetColor(grey)
end

function CheckBox:OnEnter()
  self.Border:SetColor(DimOrange)
 return self
end

function CheckBox:SetChecked(checked)
  self:InternalSetChecked(checked)
end

function CheckBox:IsChecked()
  return self.Checked
end

function CheckBox:InternalSetChecked(checked)
  
  self.Checked = checked
  
  if(self.Checked) then
    cross:SetTexturePixelCoordinates(128, 0, 128+64, 64)
    cross:SetColor(Orange)
  else
   cross:SetTexturePixelCoordinates(192, 0, 256, 64)
   cross:SetColor(Color(0.07, 0.07, 0.07, 1))
  end
end

function CheckBox:Clicked(down)
  if(down) then
    self:InternalSetChecked(not self.Checked)
    self:FireEvent(self.CheckedChanged, self.Checked)
  end
end