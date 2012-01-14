//
//   Created by:   fsfod
//

ControlClass('UIButton', BorderedSquare)

ButtonMixin:Mixin(UIButton)

UIButton.InnerHeight = 24/36
UIButton.InnerWidth = 94/100

UIButton.PressedLabelShift = Vector(0, 2 ,0)

local FontSize = 16

function UIButton:Initialize(labelText, width, height)

  width = width or 110
  height = height or 36

	BorderedSquare.Initialize(self, width, height, 2, true)
	ButtonMixin.Initialize(self)
	
	self:SetBackgroundColor(Color(0.06,0.06,0.06, 0.8))
	
	local center = self:CreateGUIItem()
	 center:SetAnchor(GUIItem.Center, GUIItem.Middle)
	 center:SetColor(ControlGrey1)
	 self.CenterSquare = center
	
  local centerBg = self:CreateGUIItem()
   centerBg:SetTexture("ui/ButtonBg.dds")
   centerBg:SetAnchor(GUIItem.Center, GUIItem.Middle)
   //centerBg:SetColor(Color(1, 1, 1, 1))
   centerBg:SetIsVisible(false)	 
	self.CenterBg = centerBg

	local label = self:CreateFontString(PageButtonFont)
	 label:SetText(labelText or "some text")  
	self.Label = label
	
  self:SetSize(width, height)
end

function UIButton:SetSize(width, height)

  BorderedSquare.SetSize(self, width, height)

  local centerHeight = self.InnerHeight*height
  local centerWidth = (self.InnerWidth*width)-2

  local centerSize = Vector(centerWidth, centerHeight, 0)

  self.CenterBg:SetSize(centerSize)
  self.CenterSquare:SetSize(centerSize)
 
  local centerPos = Vector(1-(centerWidth/2), -((centerHeight/2)), 0)

  self.CenterSquare:SetPosition(centerPos)
  self.CenterBg:SetPosition(centerPos)
end


function UIButton:Clicked(down)
	if(down) then
    self.Label:SetPosition(UIButton.PressedLabelShift)
  else
    self.Label:SetPosition(Vector.origin)
  end
end


function UIButton:SetLabel(label)
  self.Label:SetText(label)
end

function UIButton:SetHighlightLock(locked)
  self.HighlightLocked = locked
 
  if(locked) then
    self.CenterSquare:SetColor(ControlGrey1)
  else
    self.CenterSquare:SetColor(Color(0.1, 0.1, 0.1, 1))
  end

  self.CenterBg:SetIsVisible(locked)
end

function UIButton:OnEnter()

  if(not self.HighlightLocked) then
	  self.CenterSquare:SetColor(Color(0.1, 0.1, 0.1, 1))
	  self.CenterBg:SetIsVisible(true)
	
	  PlayerUI_PlayButtonEnterSound()
	end
end

function UIButton:OnLeave()
  if(not self.HighlightLocked) then
	  self.CenterSquare:SetColor(ControlGrey1)
	  self.CenterBg:SetIsVisible(false)
	end
end