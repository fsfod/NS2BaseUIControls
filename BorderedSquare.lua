

class 'BorderedSquare'(BaseControl)

local DefaultLineWidth = 1
local DefaultSize = 60

local BorderColour = Color(0.133, 0.149, 0.1529, 1)
local BackgroundColor = Color(0.588, 0.627, 0.666, 1)

local Red = Color(1,0,0,1)

function BorderedSquare:__init(width, height, lineWidth, skipSetSize)
	
	self.LineWidth = lineWidth or DefaultLineWidth 
	height = height or DefaultSize
	width = width or DefaultSize
	
	BaseControl.Initialize(self, width, height)
	
  local bg = self.RootFrame
	  bg:SetColor(BackgroundColor)
  
  local top = GUIManager:CreateGraphicItem()
    top:SetColor(BorderColour)
  self.Top = top
  
  local bottom = GUIManager:CreateGraphicItem()
    bottom:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    //the wonky rounding of the coorinates cause this to look wrong
		//bottom:SetPosition(Vector(0,-self.LineWidth, 0))
    bottom:SetColor(BorderColour)
  self.Bottom = bottom
  
  local left = GUIManager:CreateGraphicItem()
    left:SetColor(BorderColour)
  self.Left = left
  
  local right = GUIManager:CreateGraphicItem()
    right:SetAnchor(GUIItem.Right, GUIItem.Top)
    //the wonky rounding of the coorinates cause this to look wrong
		//right:SetPosition(Vector(-self.LineWidth,0, 0))
    right:SetColor(BorderColour)
  self.Right = right
  
  bg:AddChild(top)
  bg:AddChild(bottom)
  bg:AddChild(left)
  bg:AddChild(right)
  
  self.HitRec = {}
  
  if(not skipSetSize) then
    self:SetSize(width, height)
  end
  
  return self
end

function BorderedSquare:SetBorderColour(colour)
	self.Left:SetColor(colour)
	self.Right:SetColor(colour)
	self.Top:SetColor(colour)
	self.Bottom:SetColor(colour)
end

function BorderedSquare:SetBackgroundColor(colour)
	self.RootFrame:SetColor(colour)
end

function BorderedSquare:SetSize(width, height)

  BaseControl.SetSize(self, width, height)
  
  local SizeVec = Vector(width, self.LineWidth, 0)
  
  self.Top:SetSize(SizeVec)
  SizeVec.x = width+(self.LineWidth*0.5)
  self.Bottom:SetSize(SizeVec)
  
  SizeVec.x = self.LineWidth
  SizeVec.y = height
  self.Left:SetSize(SizeVec)
  
  SizeVec.y = height+(self.LineWidth*0.5)
  self.Right:SetSize(SizeVec)
  
  //self.Bottom:SetPosition(Vector(0,-(self.LineWidth*0.9), 0))
  //self.Right:SetPosition(Vector(-(self.LineWidth*0.9),0, 0))
  /*
  SizeVec.x = width-(LineWidth*2)
  SizeVec.y = 0
  self.Right:SetPositon(SizeVec)
  
  SizeVec.x = 0
  SizeVec.y = width-(LineWidth*2)
  self.Bottom:SetPositon(SizeVec)*/
end

class 'BasePage'(BorderedSquare)

function BasePage:__init(width, height, titleString)
  
  BorderedSquare.__init(self, width, height, 2)

  self.RootFrame:SetColor(PageBgColour)

  local title = GUIManager:CreateTextItem()
    title:SetFontSize(20)
    title:SetText(titleString)
	  title:SetAnchor(GUIItem.Center, GUIItem.Middle)
	  title:SetTextAlignmentX(GUIItem.Align_Center)
	  title:SetTextAlignmentY(GUIItem.Align_Center)
  self.Title = title
///title:GetTextWidth(titleString)+40

  local titlebox = BorderedSquare(200, 24, 2)
    titlebox:SetPoint("Top", 0, 0, "Bottom")
    titlebox:SetColor(Color(0.1, 0.1, 0.1, 1))
    titlebox.RootFrame:AddChild(title)
   self:AddChild(titlebox)
end
  
  
  