/*
enum XAnchor = {
  GUIItem.Top
  GUIItem.Center
  GUIItem.Bottom
}

enum YAnchor = {
  GUIItem.Left,
  GUIItem.Middle,
  GUIItem.Right
}
*/

local PointToAnchor = {
  Top = {GUIItem.Middle, GUIItem.Top},
  Bottom = {GUIItem.Middle, GUIItem.Bottom},
  Left = {GUIItem.Left, GUIItem.Center},
  Right = {GUIItem.Right, GUIItem.Center},
  
  TopLeft = {GUIItem.Left, GUIItem.Top},
  TopRight = {GUIItem.Right, GUIItem.Top},
  BottomLeft = {GUIItem.Left, GUIItem.Bottom},
  BottomRight = {GUIItem.Right, GUIItem.Bottom},
  
  Center = {GUIItem.Middle, GUIItem.Center},
}

PointToAnchor.top = PointToAnchor.Top
PointToAnchor.bottom = PointToAnchor.Bottom
PointToAnchor.left = PointToAnchor.Left
PointToAnchor.right = PointToAnchor.Right
PointToAnchor.topleft = PointToAnchor.TopLeft
PointToAnchor.topright = PointToAnchor.TopRight
PointToAnchor.bottomleft = PointToAnchor.BottomLeft 
PointToAnchor.bottomright = PointToAnchor.BottomRight
PointToAnchor.center = PointToAnchor.Center

local WrapVector = Vector()

function classL(className, base)
  local  t = {}
  
  for funcname,func in pairs(base) do
    t[funcname] = func
  end
  
  _G[className] = t
end

local bor = bit.bor
local band = bit.band

local OnClickFlag = 1
local OnEnterFlag = 2
local OnMouseWheelFlag = 4

class'BaseControl' 

function BaseControl:__init(width, height, ...)
  if(width) then
    self:Initialize(width, height, ...)
  end
end

function BaseControl:Initialize(width, height)
  
  local flags = 0
  
  if(width) then
    self:CreateRootFrame(width, height)
  end

  if(self.OnClick) then
    flags = OnClickFlag
  end
  
  if(self.OnEnter) then
    flags = bor(flags, OnEnterFlag)
  end
  
  if(self.OnMouseWheel) then
    flags = bor(flags,OnMouseWheelFlag)
  end 
  
  self.Flags = flags
  self.ChildFlags = 0
  
  if(flags ~= 0) then
    self:SetupHitRec()
  end
end

function BaseControl:Uninitialize()

  if(self.Focused) then
    self:GetGUIManager():ClearFocusIfFrame(self)
  end

  if(self.Entered) then
    self:GetGUIManager():ClearMouseOver()
  end
  
  if(self.ChildControls) then
    for _,frame in ipairs(self.ChildControls) do
      frame:Uninitialize()
    end 
    self.ChildControls = nil
  end
  
  if(self.RootFrame) then
    GUI.DestroyItem(self.RootFrame)
    self.RootFrame = nil  
  end
end

function BaseControl:CreateRootFrame(width, height)
  local bg = GUIManager:CreateGraphicItem()
    bg:SetSize(Vector(width, height, 0))
    self:SetRootFrame(bg)

  return self.RootFrame
end

function BaseControl:SetRootFrame(frame)
  self.RootFrame = frame
  self.Size = Vector(frame:GetSize())
  self.Position = Vector(frame:GetPosition())
end

function BaseControl:GUIManagerChanged(newGUIManager)

  if(self.CachedGUIManager) then
    self.CachedGUIManager = newGUIManager

    for _,frame in ipairs(self.ChildControls) do
      frame:GUIManagerChanged(newGUIManager)
    end
  end
end

function BaseControl:GetGUIManager()
  
  if(not self.CachedGUIManager) then
    
    assert(self.Parent, "Unable to get the correct GUIManager for the control because it has no parent")
    
    self.CachedGUIManager = self.Parent:GetGUIManager()
  end
  
  return self.CachedGUIManager
end

function BaseControl:SetTexture(texture, x1, y1, x2, y2)
  
  local path = texture
  
  if(type(texture) == "table") then
    self.RootFrame:SetTexture(texture[1])
    self.RootFrame:SetTexturePixelCoordinates(texture[2], texture[3], texture[4], texture[5])
  else
    self.RootFrame:SetTexture(texture)
    
    if(x1) then
      self.RootFrame:SetTexturePixelCoordinates(x1, y1, x2, y2)
    end
  end
  
end

function BaseControl:SetLabel(str, offset, yOffset)
  
  local label = self.BC_Label
  
  if(not label) then
    label = GUIManager:CreateTextItem()
    label:SetFontSize(17)
    
    label:SetTextAlignmentX(GUIItem.Align_Min)
    label:SetTextAlignmentY(GUIItem.Align_Center)
    label:SetAnchor(GUIItem.Left, GUIItem.Center)
    
    self.BC_Label = label
    self:AddGUIItemChild(label)
  end
    
  label:SetText(str)
  label:SetPosition(Vector(-(label:GetTextWidth(str)+(offset or 6)), yOffset or 0, 0))
end

function BaseControl:CreateFontString(fontSizeOrTemplate, anchorPoint, x, y)
  local font

  if(type(fontSizeOrTemplate) == "number") then
    font = GUIManager:CreateTextItem()
    font:SetFontSize(fontSizeOrTemplate)
   
    if(anchorPoint) then
      local point = PointToAnchor[anchorPoint]
      font:SetAnchor(point[1], point[2])
    end
  else
   font = fontSizeOrTemplate:CreateFontString()
  end

  if(x) then
    font:SetPosition(Vector(x, y, 0))
  end
  
  self:AddGUIItemChild(font)
  
  return font
end

function BaseControl:SetLayer(layer)
  self.RootFrame:SetLayer(layer)
end

function BaseControl:SetColor(redOrColour, g, b, a)
  
  if(g) then
    redOrColour = Color(redOrColour, g, b, a)
  end
  
  self.RootFrame:SetColor(redOrColour)
end

function BaseControl:SetPosition(VecOrX, y)
  
  if(y) then
    if(not self.Position) then
      self.Position = Vector(VecOrX, y, 0)
    else
      self.Position.x = VecOrX
      self.Position.y = y
    end
  else
    if(not self.Position) then
      self.Position = Vector(VecOrX)
    else
      self.Position.x = VecOrX.x
      self.Position.y = VecOrX.y
    end
  end
  
  self.RootFrame:SetPosition(self.Position)
  
  if(self.HitRec and self.Size and self.Parent) then
    self:UpdateHitRec()
  end
end

function BaseControl:OnResolutionChanged(oldX, oldY, width, height)
  self:UpdatePosition()
end

function BaseControl:UpdatePosition()
  
  if(self.SpecialAnchor) then
    self:SetPoint(unpack(self.SpecialAnchor))
  elseif(self.HitRec) then
    self:UpdateHitRec()
  end
end

function BaseControl:SetSize(VecOrX, y, SkipHitRecUpdate)
  
  if(y) then
    self.Size.x = VecOrX
    self.Size.y = y
  else
    if(not self.Size) then
      self.Size = Vector(VecOrX)
    else
      self.Size.x = VecOrX.x
      self.Size.y = VecOrX.y
    end
  end
  
  self.RootFrame:SetSize(self.Size)
    
  if(self.SpecialAnchor and not SkipHitRecUpdate) then
    self:SetPoint(unpack(self.SpecialAnchor))
  end
  
  if(not SkipHitRecUpdate) then
    if(self.HitRec and self.Position and self.Parent) then
      self:UpdateHitRec()
    end
  
    --Should really optimize this for only controls that not anchored to Left and Top
    if(self.ChildControls) then
      for _,frame in ipairs(self.ChildControls) do      
        if(frame.HitRec) then
          frame:UpdateHitRec()
        end
      end
    end
  end
end

function BaseControl:GetHeight()
  
  if(self.Size) then
    return self.Size.y
  elseif(self.RootFrame) then
    return self.RootFrame:GetSize().y
  else
    return 0
  end
end

function BaseControl:SetHeight(height)
  self:SetSize(self:GetWidth(), height)
end

function BaseControl:GetWidth()
  
  if(self.Size) then
    return self.Size.x
  elseif(self.RootFrame) then
    return self.RootFrame:GetSize().x
  else
    return 0
  end
end

function BaseControl:SetWidth(width)
  self:SetSize(width, self:GetHeight())
end

function BaseControl:GetTop()
  assert(self.HitRec)

  return self.HitRec[2]
end

function BaseControl:GetBottom()
  assert(self.HitRec and self.Size)
  
  return self.HitRec[2]+self.Size.y
end

function BaseControl:GetLeft()
  assert(self.HitRec)

  return self.HitRec[1]
end

function BaseControl:GetRight()
  assert(self.HitRec and self.Size)

  return self.HitRec[1]+self.Size.x
end

function BaseControl:GetScreenPosition()
  return self.RootFrame:GetScreenPosition(Client.GetScreenWidth(), Client.GetScreenHeight())
end

--should only update HitRec when were parented to something 
function BaseControl:UpdateHitRec(rec)
  
  local xAnchor = self.RootFrame:GetXAnchor()
  local yAnchor = self.RootFrame:GetYAnchor()
  
  local Pos = self.Position
  local x,y
  
  if(not self.Parent and xAnchor == GUIItem.Left and yAnchor == GUIItem.Top) then
    x,y = Pos.x,Pos.y
  else
    local Size = (self.Parent or UIParent).Size
  
    if(xAnchor == GUIItem.Left) then
      x = Pos.x
    elseif(xAnchor == GUIItem.Right) then
      x = Size.x+Pos.x
    else
      x = Pos.x+(Size.x/2)
    end

    if(yAnchor == GUIItem.Top) then
      y = Pos.y
    elseif(yAnchor == GUIItem.Bottom) then
      y = Size.y+Pos.y
    else
      y = Pos.y+(Size.y/2)
    end
  end
  
  rec = rec or self.HitRec
   rec[1] = x
   rec[2] = y
   rec[3] = x+self.Size.x
   rec[4] = y+self.Size.y
end

function BaseControl:AddGUIItemChild(frame)
  self.RootFrame:AddChild(frame)
end

function BaseControl:AddChild(control)

  if(not self.ChildControls) then
    self.ChildControls = {}
  end
  
  self:AddGUIItemChild(control.RootFrame)
  control.Parent = self
  
  if(control.OnParentSet) then
    control:OnParentSet()
  end

  if(control.HitRec) then
    control:UpdateHitRec()
  end
  
  local flags = bor(control.Flags, control.ChildFlags)
  
  if(flags ~= 0 and flags ~= band(flags, self.ChildFlags)) then
    self:NotifyChildFlags(flags)
  end
  
  table.insert(self.ChildControls, control)
end

function BaseControl:NotifyChildFlags(flags)
  flags = bor(self.ChildFlags, flags)
  self.ChildFlags = flags 

  local parent = self.Parent

  if(not self.HitRec) then
    self:SetupHitRec()
  end

  if(parent and band(parent.ChildFlags, flags) ~= flags) then
    parent:NotifyChildFlags(flags)
  end
end

function BaseControl:RemoveChild(frame)
  local found = table.removevalue(self.ChildControls, frame)
  
  if(found) then
    self.RootFrame:RemoveChild(frame.RootFrame)
  end
  
  return found
end

function BaseControl:SetupHitRec()
  self.HitRec = {0, 0, 0, 0}
  
  if(self.Parent) then
    self:UpdateHitRec()
  end
end

function BaseControl:SetConfigBinding(...)
  self.ConfigBinding = ConfigDataBind(...)

  //controls have to implement this
  self:SetValueFromConfig()
  
  return self.ConfigBinding
end

function BaseControl:SetConfigBindingAndTriggerChange(...)
  self.ConfigBinding = ConfigDataBind(...)

  //controls have to implement this
  self:ConfigValueChanged(self.ConfigBinding:GetValue())
  
  return self.ConfigBinding
end

function BaseControl:FireEvent(Action, ...)
  --client code doesn't need bother to check if anything has registered the event
  if(not Action) then
    return
  end
  
  if(type(Action) == "table") then
    return Action[1](unpack(Action, 2), ...)
  else
    if(type(Action) == "string") then
      if(not _G[Action]) then
        RawPrint("BaseControl:FireEvent Could not find global function named ".. Action)
       return
      end
      Action = _G[Action]
    end
    return Action(...)
  end
end

--the control needs to set its size if it want to pass a reltivePoint
function BaseControl:SetPoint(point, x, y, reltivePoint)
  
  local root = self.RootFrame
  
  if(reltivePoint) then
    self.SpecialAnchor = {point, x, y, reltivePoint}
  end
  
  local point = PointToAnchor[point]
  root:SetAnchor(point[1], point[2])

  --the point a controls position is based off is TopLeft in the ns2 gui system
  if(reltivePoint) then
    local relpoint = PointToAnchor[reltivePoint]
    local Size = self.Size
    
    if(relpoint[1] == GUIItem.Right) then
      x = (-Size.x)+x
    elseif(relpoint[1] == GUIItem.Middle) then
      x = x-(Size.x/2)
    end
    
    if(relpoint[2] == GUIItem.Bottom) then
      y = (-Size.y)+y
    elseif(relpoint[2] == GUIItem.Center) then
      y = y-(Size.y/2)
    end
  end

  self:SetPosition(x, y)
end

function BaseControl:Show()
  
  self.Hidden = false
  
  if(self.RootFrame) then
   self.RootFrame:SetIsVisible(true)
  end
end

function BaseControl:Hide()
  
  self.Hidden = true
  
  if(self.Focused) then
     self:GetGUIManager():ClearFocus()
  end
  
  if(self.RootFrame) then
   self.RootFrame:SetIsVisible(false)
  end
end

function BaseControl:RegisterForMouseMove(functionName)
  self:GetGUIManager().RegisterCallback(self, "MouseMove", functionName)
end

function BaseControl:UnregisterForMouseMove()
  self:GetGUIManager().UnregisterCallback(self, "MouseMove")
end

function BaseControl:IsInParentChain(parent)
  assert(parent)
  
  return self.Parent and (self.Parent == parent or self.Parent:IsInParentChain(parent))
end

function BaseControl:IsShown()
  
  if(self.Hidden or (self.Parent and self.Parent.Hidden)) then
    return false
  else
    if(self.Parent) then
      return self.Parent:IsShown()
    end
  end
  
  return true
end

function BaseControl:Update()
end

function BaseControl:SendKeyEvent()
end

function BaseControl:SendCharacterEvent()
end

ButtonMixin = {}

function ButtonMixin:Mixin(target)
  target.OnClick = self.OnClick
end

function ButtonMixin:__init()
  
  if(self.ClickSound == nil) then
    self.ClickSound = buttonClickSound
  end
  
  self:SetupHitRec()
end

function ButtonMixin:OnClick(button, down)
  if(button == InputKey.MouseButton0) then
    if(down) then
      if(self.ClickSound) then
        MenuManager.PlaySound(self.ClickSound)
      end
      
      if(self.Clicked) then
        self:Clicked(true)
      end

      if(self.ClickAction) then
        self:FireEvent(self.ClickAction)
      end
    else
      if(self.Clicked) then
        self:Clicked(false)
      end
    end
  end
end


class 'FontTemplate'

function FontTemplate:__init(...)
  if(type(select(1, ...)) == "string") then
    self.FontName, self.FontSize = ...
  else
    self.FontSize = ...
  end
end

function FontTemplate:SetAnchor(xAnchor, yAnchor)
  self.XAnchor = xAnchor
  self.YAnchor = yAnchor
end

function FontTemplate:CreateFontString()
  local result = GUIManager:CreateTextItem()
   self:Apply(result)
  return result
end

function FontTemplate:SetBold()
  self.Bold = true
end

function FontTemplate:SetFontName(name)
  self.FontName = name
end

function FontTemplate:SetFontSize(size)
  self.FontSize = size
end

function FontTemplate:SetColour(redOrColour, g, b, a)
  if(not g) then
    self.Colour = Color(colour)
  else
    self.Colour = Color(redOrColour, g, b, a)
  end
end

function FontTemplate:SetCenterAlignAndAnchor()
  self:SetTextAlignment(GUIItem.Align_Center, GUIItem.Align_Center)
  self:SetAnchor(GUIItem.Center, GUIItem.Middle)
end

function FontTemplate:SetTextAlignment(x, y)
  self.TextAlignmentX = x
  self.TextAlignmentY = y
end

function FontTemplate:Apply(font)
  
  if(self.FontName) then
    font:SetFontName(self.FontName)
  end
  
  if(self.FontSize) then
    font:SetFontSize(self.FontSize)
  end
  
  if(self.Bold) then
    font:SetFontIsBold(true)
  end

  if(self.TextAlignmentX) then
    font:SetTextAlignmentX(self.TextAlignmentX)
    font:SetTextAlignmentY(self.TextAlignmentY)
  end
  
  if(self.XAnchor) then
    font:SetAnchor(self.XAnchor, self.YAnchor)
  end
  
  if(self.Colour) then
    font:SetColor(self.Colour)
  end
end

