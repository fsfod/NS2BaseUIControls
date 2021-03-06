//
//   Created by:   fsfod
//

ControlClass("BaseWindow", BorderedSquare)

function BaseWindow:Initialize(width, height, titleString, noCloseButton)
  BorderedSquare.Initialize(self, width, height, 2)

  self:SetColor(WindowBGColor)

  self:SetDraggable()
  self:AddFlag(ControlFlags.IsWindow)

  self:SetPoint("Center", 0, 0, "Center")

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

  local closeButton = self:CreateControl("CloseButton", self)
   closeButton:SetPoint("TopRight", -5, 5, "TopRight")
  self:AddChild(closeButton)
  
  if(noCloseButton) then
    closeButton:Hide()
  end
end

function BaseWindow:InitFromTable(options)
  self:Initialize(options.Width, options.Height, options.Title or "", not options.HasCloseButton)
  
  
end

function BaseWindow:Close(fromCloseButton)

  if(self.DestroyOnClose) then
    self:GetGUIManager():RemoveFrame(self, true)
  else
    self:Hide()
  end
end

ControlClass('CloseButton', BaseControl)

ButtonMixin:Mixin(CloseButton)

local maxX = 16
local minX = 2

CloseButton.TexturePath ="ui/closebutton.dds"
CloseButton.DefaultHeight = 20
CloseButton.XOffset = 2
CloseButton.XOffsetVec = Vector(CloseButton.XOffset, CloseButton.XOffset, 0)



local xheight = CloseButton.DefaultHeight-(CloseButton.XOffset*2)
CloseButton.XHeightVec = Vector(xheight, xheight, 0)

function CloseButton:Initialize(window)
  
  local height = self.DefaultHeight

  BaseControl.Initialize(self, height, height)
  ButtonMixin.Initialize(self)
  
  //self:SetColor(0.4, 0.4, 0.4, 1)

  self.ClickAction = function() self.Parent:Close(true) end
 
  self:SetTexture(self.TexturePath, 0, 0, 64, 64)
  
   local x = self:CreateGUIItem()
    x:SetPosition(self.XOffsetVec)
    x:SetSize(self.XHeightVec)
    x:SetTexture(self.TexturePath)
    x:SetTexturePixelCoordinates(64, 0, 63+64, 64)
    x:SetIsVisible(true)

  local x2 = self:CreateGUIItem()
    x2:SetPosition(self.XOffsetVec)
    x2:SetSize(self.XHeightVec)
    x2:SetTexture(self.TexturePath)
    x2:SetTexturePixelCoordinates(63+64, 0, 63+64+64, 64)//64, 0, 63+64, 64)
    x2:SetBlendTechnique(GUIItem.Add)
    x2:SetIsVisible(false)
  self.Highlight = x2
end

function CloseButton:OnEnter()
  self.Highlight:SetIsVisible(true)
end

function CloseButton:OnLeave()
	self.Highlight:SetIsVisible(false)
end


ControlClass('ResizeButton', BaseControl)


ResizeButton.DefaultHeight = 30

function ResizeButton:InitFromTable()
  self:Initialize()
end

function ResizeButton:Initialize()
  
  local height = self.DefaultHeight
  BaseControl.Initialize(self, height, height)
  
  self:SetColor(0.4, 0.4, 0.4, 1)

  self:SetDraggable()
end

function ResizeButton:OnDragStart()

  self.DragStartOffset = self.CurrentValuePositon
  
  self.ParentSize = Vector(self.Parent:GetSize())
  RawPrint("DragStarted")
  
  self.ParentAnchorPoint = self.Parent.AnchorPoint1
  self.Parent.AnchorPoint1 = nil
end

function ResizeButton:OnDragMove(pos)
  
  local newSize = self.ParentSize+pos
  local currentSize = self.Parent.Size

  if(newSize.x == currentSize.x and newSize.y == currentSize.y) then
    return
  end
  
  //self:SetLabel(string.format("pos: %f,%f size:%f/%f,%f/%f", pos.x, pos.y, newSize.x, self.ParentSize.x, newSize.y, self.ParentSize.y))
  
  self.Parent:SetSize(newSize)
end

function ResizeButton:OnDragStop()
  self.Parent.AnchorPoint1 = self.ParentAnchorPoint
end