ControlClass('UIButton', BorderedSquare)

ButtonMixin:Mixin(UIButton)

UIButton.InnerHeight = 24/36
UIButton.InnerWidth = 94/100

UIButton.CenterColor = Color(0.133, 0.149, 0.1529, 1)

UIButton.PressedLabelShift = Vector(0, 2 ,0)

local FontSize = 16

local Orange = Color(0.8666, 0.3843, 0, 1)

function UIButton:Initialize(labelText, width, height)

  width = width or 110
  height = height or 36

	BorderedSquare.Initialize(self, width, height, 2, true)
	ButtonMixin.Initialize(self)
	
	self:SetBackgroundColor(Color(0.06,0.06,0.06, 0.8))
	
	local center = GUIManager:CreateGraphicItem()
	 center:SetAnchor(GUIItem.Center, GUIItem.Middle)
	 center:SetColor(self.CenterColor)
	 self.CenterSquare = center
	self:AddGUIItemChild(center)
	
  local centerBg = GUIManager:CreateGraphicItem()
   centerBg:SetTexture("ui/ButtonBg.dds")
   //centerBg:SetColor(Color(1, 1, 1, 1))
   centerBg:SetIsVisible(false)	 
	self.CenterBg = centerBg
	center:AddChild(centerBg)
	
	local label = PageButtonFont:CreateFontString()
	 label:SetText(labelText or "some text")  
	 center:AddChild(label)
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
  self.CenterSquare:SetPosition(Vector(1-(centerWidth/2), -((centerHeight/2)-1), 0))
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
    self.CenterSquare:SetColor(self.CenterColor)
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
	  self.CenterSquare:SetColor(self.CenterColor)
	  self.CenterBg:SetIsVisible(false)
	end
end