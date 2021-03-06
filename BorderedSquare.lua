//
//   Created by:   fsfod
//

ControlClass('BorderedSquare', BaseControl)

local DefaultLineWidth = 1
local DefaultSize = 60

local Red = Color(1,0,0,1)

BorderedSquare.BackgroundColor = Color(0.06,0.06,0.06, 0.8)//Color(0.588, 0.627, 0.666, 1)
BorderedSquare.Color = ControlGrey1

function BorderedSquare:Initialize(width, height, lineWidth, skipSetSize)
  
  self.LineWidth = lineWidth or DefaultLineWidth 
  height = height or DefaultSize
  width = width or DefaultSize

  BaseControl.Initialize(self, width, height)
  BaseControl.SetColor(self, self.BackgroundColor)

  local top = self:CreateGUIItem()
    top:SetColor(ControlGrey1)
  self.Top = top
  
  local bottom = self:CreateGUIItem()
    bottom:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    //the wonky rounding of the coorinates cause this to look wrong
    bottom:SetPosition(Vector(0,-self.LineWidth, 0))
    bottom:SetColor(ControlGrey1)
  self.Bottom = bottom

  local left = self:CreateGUIItem()
    left:SetColor(ControlGrey1)
  self.Left = left
  
  local right = self:CreateGUIItem()
    right:SetAnchor(GUIItem.Right, GUIItem.Top)
    //the wonky rounding of the coorinates cause this to look wrong
    //right:SetPosition(Vector(0,-1,0))
    right:SetColor(ControlGrey1)
  self.Right = right
  
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
  BaseControl.SetColor(self, colour)
end

function BorderedSquare:SetSize(width, height)
  
  width, height = BaseControl.SetSize(self, width, height)
  
  local SizeVec = Vector(width, self.LineWidth, 0)
  
  self.Top:SetSize(SizeVec)
  SizeVec.x = width+(self.LineWidth*0.5)
  SizeVec.y = self.LineWidth+0.5
  self.Bottom:SetSize(SizeVec)
  
  SizeVec.x = self.LineWidth
  SizeVec.y = height
  self.Left:SetSize(SizeVec)
  
  if(self.LineWidth == 2) then
    SizeVec.y = height
  else
    SizeVec.y = height+(self.LineWidth*0.5)
  end
  
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



ControlClass('BasePage', BorderedSquare)

function BasePage:SetupFromTable(options)
  BasePage.Initialize(self, options.Width, options.Height, options.PageName, options.Title)
  
  ApplySharedControlOptions(self, options)
  
  CreatChildControlsFromTable(self, options)
end

function BasePage:Initialize(width, height, pageName, titleString)
  
  BorderedSquare.Initialize(self, width, height, 2)

  self.TraverseChildFirst = true

  self.PageName = pageName

  self:SetColor(PageBgColour)

  if(not titleString) then 
    titleString = pageName
  end


///title:GetTextWidth(titleString)+40

  local titlebox = self:CreateControl("BorderedSquare", 200, 24, 2)
    titlebox:SetPoint("Top", 0, 2, "Bottom")
    titlebox:SetColor(Color(0.1, 0.1, 0.1, 1))
   self:AddChild(titlebox)
   
  local title = titlebox:CreateFontString(20)
    title:SetText(titleString)
    title:SetAnchor(GUIItem.Center, GUIItem.Middle)
    title:SetTextAlignmentX(GUIItem.Align_Center)
    title:SetTextAlignmentY(GUIItem.Align_Center)
  self.Title = title
   
  if(GUIMenuManager.WindowedModeActive) then
   local closeButton = self:CreateControl("CloseButton", self)
    closeButton:SetPoint("TopRight", -5, 5, "TopRight")
    self:AddChild(closeButton)
  end
end

function BasePage:AddBackButton(point, x, y, relPoint)
  
  //dont need back buttons for window pages
  if(GUIMenuManager.WindowedModeActive) then
    return
  end
  
  local backButton =  self:CreateControl("UIButton", "Back to menu")
    backButton:SetPoint(point, x, y, relPoint)
    backButton.ClickAction = function() self.Parent:ReturnToMainPage() end
  self:AddChild(backButton)
end

function BasePage:Close()
  self:Hide()
end
  
  