

class 'BaseWindow' (BorderedSquare)

function BaseWindow:__init(width, height, titleString, noCloseButton)
  BorderedSquare.__init(self, width, height, 2)

  self:SetColor(WindowBGColor)

  self:SetDraggable()
  self:AddFlag(ControlFlags.IsWindow)

  self:SetPoint("Center", 0, 0, "Center")

  local closeButton = CloseButton(self)
   closeButton:SetPoint("TopRight", -5, 5, "TopRight")
  self:AddChild(closeButton)
  
  if(noCloseButton) then
    closeButton:Hide()
  end
end

function BaseWindow:Close(fromCloseButton)

  if(self.DestroyOnClose) then
    self:GetGUIManager():RemoveFrame(self, true)
  else
    self:Hide()
  end
end

class 'CloseButton'(BaseControl)

ButtonMixin:Mixin(CloseButton)

local maxX = 16
local minX = 2

CloseButton.TexturePath ="ui/closebutton.dds"
CloseButton.DefaultHeight = 20
CloseButton.XOffset = 2
CloseButton.XOffsetVec = Vector(CloseButton.XOffset, CloseButton.XOffset, 0)



local xheight = CloseButton.DefaultHeight-(CloseButton.XOffset*2)
CloseButton.XHeightVec = Vector(xheight, xheight, 0)

function CloseButton:__init(window)
  
  local height = self.DefaultHeight

  BaseControl.__init(self, height, height)
  ButtonMixin.__init(self)
  
  //self:SetColor(0.4, 0.4, 0.4, 1)

  self.ClickAction = function() self.Parent:Close(true) end
 
  self:SetTexture(self.TexturePath, 0, 0, 64, 64)
  
   local x = GUIManager:CreateGraphicItem()
    x:SetPosition(self.XOffsetVec)
    x:SetSize(self.XHeightVec)
    x:SetTexture(self.TexturePath)
    x:SetTexturePixelCoordinates(64, 0, 63+64, 64)
    x:SetIsVisible(true)
  self:AddGUIItemChild(x)
  
  local x2 = GUIManager:CreateGraphicItem()
    x2:SetPosition(self.XOffsetVec)
    x2:SetSize(self.XHeightVec)
    x2:SetTexture(self.TexturePath)
    x2:SetTexturePixelCoordinates(63+64, 0, 63+64+64, 64)//64, 0, 63+64, 64)
    x2:SetBlendTechnique(GUIItem.Add)
    x2:SetIsVisible(false)
  self.Highlight = x2
  self:AddGUIItemChild(x2)
end

function CloseButton:OnEnter()
  self.Highlight:SetIsVisible(true)
end

function CloseButton:OnLeave()
	self.Highlight:SetIsVisible(false)
end