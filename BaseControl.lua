//
//   Created by:   fsfod
//

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

WidthUnchangedPoint = {
  Top = true,
  Bottom = true,
  [PointToAnchor["Top"]] = true,
  [PointToAnchor["Bottom"]] = true,
}

HeightUnchangedPoint = {
  Left = true,
  Right = true,
  [PointToAnchor["Left"]] = true,
  [PointToAnchor["Right"]] = true,
}

_G.PointToAnchor = PointToAnchor

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

local bor = bit.bor
local band = bit.band

ControlFlags = {
  OnClick = 1,
  OnEnter = 2,
  OnMouseWheel = 4,
  Draggable = 8,
  IsWindow = 16,
  Focusable = 32,
}

local GUIItem = GUIItem
local SetPosition = GUIItem.SetPosition
local SetSize = GUIItem.SetSize
local GetPosition = GUIItem.GetPosition
local GetSize = GUIItem.SetSize
local AddChild = GUIItem.AddChild

if(decoda_output) then
  local old_AddChild = AddChild
    
  AddChild = function(self, child)
    assert(child and child:GetParent() ~= self)
      
    old_AddChild(self, child)
  end
end 

function ChangePositionSizeFunctions(setPos, setSize, getPos, getSize)
  SetPosition = setPos
  SetSize = setSize
  GetPosition = getPos
  GetSize = getSize
end


ControlClass('BaseControl')

function BaseControl:Initialize(width, height)

  local flags = 0

  if(width) then
    SetSize(self, Vector(width, height, 0))

    self.Position = Vector()
    self.Size = Vector(width, height, 0)
    self.RootFrame = self
  end

  self.RootFrame = self.RootFrame or self

  if(self.OnClick) then
    flags = ControlFlags.OnClick
  end
  
  if(self.OnEnter) then
    flags = bor(flags, ControlFlags.OnEnter)
  end
  
  if(self.OnMouseWheel) then
    flags = bor(flags, ControlFlags.OnMouseWheel)
  end 
  
  self.Flags = flags
  self.ChildFlags = 0
  
  if(flags ~= 0) then
    self:SetupHitRec()
  end
end

function BaseControl:InitFromTable(optionTable)
  
  if(optionTable.FontSize or optionTable.Text) then
  else
    self:Initialize(optionTable.Width, optionTable.Height)
  end
  
end

//self is really the static table of the control
function BaseControl:SetDefaultOptions(options)
  self.DefaultOptions = options
  
  for k,v in pairs(options) do
    self[k] = v
  end
end

function BaseControl:Uninitialize(fromParent)
  
  local parent = self.Parent

  if(self.Focused) then
    self:GetGUIManager():ClearFocusIfFrame(self)
  end

  if(self.Entered) then
    self:GetGUIManager():ClearMouseOver()
  end

  if(self.ChildControls) then
    for _,frame in ipairs(self.ChildControls) do
      frame:Uninitialize(true)
    end 
    self.ChildControls = nil
  end


  if(not fromParent) then
    DestroyControl(self)
  end
end

local function MakeCreateGUIItem()

  local CreateItem = GUI.CreateItem
  local vec = Vector()

  BaseControl.CreateGUIItem = function(self, xOrVec, y)
  
    local item = CreateItem()

    item.SetPosition = SetPosition
    item.SetSize = SetSize
    
    self:AddGUIItemChild(item)
    
    if(xOrVec) then
      
      if(y) then
        vec.x = x
        vec.y = y
        
        xOrVec = vec
      end

      UIItemSetPosition(item, xOrVec)
    end
    
    return item
  end


end

MakeCreateGUIItem()

local tempSize = Vector()

function BaseControl:CreateControl(controlClass, ...)

  local Class = _G[controlClass]

  if(not Class) then
    error("BaseControl:CreateControl: Control class "..(controlClass or "nil").. "does not exist")
  end

  local control = CreateControl(controlClass)

  control:Initialize(...)

  return control
end

local CreatChildControlsFromTable = _G.CreatChildControlsFromTable
local ApplySharedControlOptions = _G.ApplySharedControlOptions

local function OptionsTable_TextHandler(self, optionTable)

  local control = self:CreateFontString(optionTable.FontSize or 20)
  
  if(optionTable.Text) then
    control:SetText(optionTable.Text)
  end
  
  ApplySharedControlOptions(control, optionTable)
  
  return control

end

local ExtraTypes = {
  Text = OptionsTable_TextHandler,
}

function BaseControl:CreateControlFromTable(optionTable, ...)

  local controlType = optionTable.Type

  local Class = _G[controlType]

  if(not Class) then
    if(ExtraTypes[controlType]) then
      return ExtraTypes[controlType](self, optionTable, ...)
    end
    
    error("BaseControl:CreateControl: Control class "..(controlType or "nil").. "does not exist")
  end

  if(optionTable.RestoreSavedOptions) then
    RestoreSavedOptions(self, optionTable)
  end

  local control = CreateControl(controlType)
  control.__Constructing = true
  //set parent before calling InitFromTable so that option values that refrance this control work
  control.Parent = self
  control:InitFromTable(optionTable, ...)
  
  ApplySharedControlOptions(control, optionTable)
  //just clear it again so we don't trigger an assert in AddChild
  control.Parent = nil
  self:AddChild(control)

  CreatChildControlsFromTable(control, optionTable)
  
  control.__Constructing = false

  return control
end

function BaseControl:CreatChildControlsFromTable(controlList)
  
  for key,entry in pairs(controlList) do
    local control = self:CreateControlFromTable(entry)
    
    if(type(key) ~= "number") then
      control.Name = key
      self[key] = control 
    end
  end
end

function BaseControl:CreateFontString(fontSizeOrTemplate, anchorPoint, x, y, clipText)
  local font

  if(type(fontSizeOrTemplate) == "number") then

    font = GUIManager:CreateTextItem()
    font:SetFontSize(fontSizeOrTemplate)
  else
    font = fontSizeOrTemplate:CreateFontString()
    fontSizeOrTemplate = fontSizeOrTemplate.FontSize
  end

  font.FontSize = fontSizeOrTemplate

  local point

  if(anchorPoint) then
    point = PointToAnchor[anchorPoint]
    font:SetAnchor(point[1], point[2])
  end

  if(x) then
    font:SetPosition(Vector(x, y, 0))
   
    if(clipText) then
      local width = self:GetWidth()

      if(anchorPoint) then
        if(point[1] == GUIItem.Right) then
          x = (width)+x
        elseif(point[1] == GUIItem.Middle) then
          x = x-(width/2)
        end
      end
      
      font:SetTextClipped(true, width-x, fontSizeOrTemplate)
    end
  end
  
  self:AddGUIItemChild(font)
  
  return font
end

function BaseControl:GUIManagerChanged(newGUIManager)

  if(self.CachedGUIManager) then
    self.CachedGUIManager = newGUIManager

    if(self.ChildControls) then

      for _,frame in ipairs(self.ChildControls) do
       frame:GUIManagerChanged(newGUIManager)
      end
    end
  end
end

function BaseControl:SafeGetGUIManager()
  
  if(not self.CachedGUIManager) then
    
    if(not self.Parent) then
      return nil
    end
    
    local result = self.Parent:GetGUIManager()
    
    if(not result) then
      return nil
    end

    self.CachedGUIManager = result
  end
  
  return self.CachedGUIManager
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
    GUIItem.SetTexture(self.RootFrame, texture[1])
    self.RootFrame:SetTexturePixelCoordinates(texture[2], texture[3], texture[4], texture[5])
  else
    GUIItem.SetTexture(self.RootFrame, texture)
    
    if(x1) then
      self.RootFrame:SetTexturePixelCoordinates(x1, y1, x2, y2)
    end
  end
end

function BaseControl:SetLabel(str, offset, yOffset, anchorRight)
  
  local label = self.BC_Label
  
  if(not label) then
    label = self:CreateFontString(self.FontSize or 18)

    //label:SetTextAlignmentX(GUIItem.Align_Min)
    //label:SetTextAlignmentY(GUIItem.Align_Center)
    
    self.BC_Label = label
    //self:AddGUIItemChild(label)
  end

  label:SetText(str)
  
  if(anchorRight) then
    label:SetPoint("Right", (offset or 6), yOffset or 0, "Left")
  else
    label:SetPoint("Left", -(offset or 6), yOffset or 0, "Right")
  end
end
/*
function BaseControl:SetLayer(layer)
  self.RootFrame:SetLayer(layer)
end
*/
function BaseControl:SetColor(redOrColour, g, b, a)
  
  if(g) then
    redOrColour = Color(redOrColour, g, b, a)
  end
  
  GUIItem.SetColor(self, redOrColour)
end

function BaseControl:GetPosition()
  return self.Position or GetPosition(self)
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

  SetPosition(self, self.Position)
  
  self:TryUpdateHitRec()
end

function BaseControl:OnResolutionChanged(oldX, oldY, width, height)
  self:ParentSizeChanged()
end

function BaseControl:ParentSizeChanged()

  if(self.AnchorPoint1) then
    self:UpdatePointOffset(self.AnchorPoint2)
    
    if(self.AnchorPoint2) then
      self:UpdateSizeFromPoints()
    end
  else
    self:TryUpdateHitRec()
  end
end

function BaseControl:ResizeInplace(x, y, side)
  
  local posX, posY = self:GetLeft(), self:GetTop()
  
  if(side[1] == 0) then
    posX = -x
  else
    posX = self:GetLeft()
  end
  
  if(false) then
    self:SetPosition(posX, posY)
  else
    self:SetPosition(posX, posY)
  end
end

function BaseControl:SetSize(VecOrX, y, SkipHitRecUpdate)

  local size = self.Size

  if(y) then
    size.x = VecOrX
    size.y = y
  else
    if(not size) then
      self.Size = Vector(VecOrX)
      size = self.Size
    else
      size.x = VecOrX.x
      size.y = VecOrX.y
    end
  end

  SetSize(self, size)

  if(self.AnchorPoint1) then
    self:UpdatePointOffset()
  end

  if(not SkipHitRecUpdate) then
    self:TryUpdateHitRec(true)
  end

  if(self.ChildControls) then

    for _,frame in ipairs(self.ChildControls) do 
      frame:ParentSizeChanged()
    end
  end

  return size.x, size.y
end

function BaseControl:TryUpdateHitRec()
  
  if(self.HitRec and self.Position and self.Parent) then
    self:UpdateHitRec()
  end
end

function BaseControl:GetSize()
  return self.Size or GetSize(self)
end

function BaseControl:GetHeight()
  return self:GetSize(self).y
end

function BaseControl:SetHeight(height)
  self:SetSize(self:GetWidth(), height)
end

function BaseControl:GetWidth()
  return self:GetSize(self).x
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
  return  GUIItem.GetScreenPosition(self, Client.GetScreenWidth(), Client.GetScreenHeight())
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

  assert(frame)

  table.insert(debug.getfenv(self), frame)

  AddChild(self, frame)

  return frame
end

function BaseControl:AddChild(control)

  assert(control.Parent ~= self)

  if(not self.ChildControls) then
    self.ChildControls = {}
  end
  
  assert(control.RootFrame)
  
  AddChild(self, control.RootFrame)
  control.Parent = self
  
  if(control.OnParentSet) then
    control:OnParentSet()
  end

  control:TryUpdateHitRec()

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

function BaseControl:DestoryChild(frame)
  local found = table.removevalue(self.ChildControls, frame)

  assert(found)

  GUIItem.RemoveChild(self.RootFrame, frame.RootFrame)
  
  frame:Uninitialize()
end

function BaseControl:RemoveChild(frame)
  local found = table.removevalue(self.ChildControls, frame)

  if(found) then
    GUIItem.RemoveChild(self.RootFrame, frame.RootFrame)
  end
  
  return found
end

function BaseControl:RemoveGUIItemChild(frame)
  local found = false
  
  local instanceTable = debug.getfenv(self)
  
  for i,v in ipairs(instanceTable) do
    if(v == frame) then
      table.remove(instanceTable, i)
      found = true
     break
    end
  end

  if(found) then
    GUIItem.RemoveChild(self.RootFrame, frame.RootFrame)
  end
  
  return found
end


local IsWindowFlag = ControlFlags.IsWindow

function BaseControl:GetTopLevelParentWindow()

  if(self:IsWindowFrame()) then
    return self
  end

  local lastFoundWindow
  local nextParent = self.Parent

  while nextParent do   
    if(nextParent:IsWindowFrame()) then
      lastFoundWindow = nextParent
    end

    nextParent = nextParent.Parent
  end

  return lastFoundWindow
end

function BaseControl:SetupHitRec()
  self.HitRec = {0, 0, 0, 0}

  self:TryUpdateHitRec()
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

function BaseControl:ReloadConfigValue()
  self:ConfigValueChanged(self.ConfigBinding:GetValue())
end

function BaseControl:FireEvent(Action, ...)
  --client code doesn't need bother to check if anything has registered the event
  if(not Action) then
    return
  end

  if(type(Action) == "table") then
    //http://www.lua.org/manual/5.1/manual.html#2.5
    //we could just pack the extra arguments into the action table and unpack it as the last arg but we would have to clean them out after the call
    assert(#Action == 2, "Only one extra agument is supported for event tables")
    
    return SafeCallResultsOnly(Action[1], /*unpack(Action, 2)*/Action[2], ...)
  else
    if(type(Action) == "string") then
      local gFunc = _G[Action]
      
      if(not gFunc) then
        RawPrint("BaseControl:FireEvent Could not find global function named ".. Action)
       return
      end
      
      if(type(gFunc) ~= "function") then
        RawPrint("BaseControl:FireEvent global object %s was not a function", Action)
       return
      end
      
      
      Action = gFunc
    end

    return SafeCallResultsOnly(Action, ...)
  end
end

function BaseControl:UpdatePointOffset(SkipHitRecUpdate)
  
  --the point a controls position is based off is TopLeft in the ns2 gui system
  
  local width, height
  
  if(self._FontSize) then
    //FIXME handle custom sized font strings
    local text = self:GetText()

    if(not text or text == "") then 
      width = 1
      height = self:GetTextHeight("g")
    else
      width = self:GetTextWidth(text)
      height = self:GetTextHeight(text)
    end
  else
    local Size = self.Size
    
    width = Size.x
    height = Size.y
  end

  local anchorInfo = self.AnchorPoint1
  
  local relpoint = anchorInfo[4]
  local x,y = anchorInfo[2], anchorInfo[3]
  
  if(relpoint[1] == GUIItem.Right) then
    x = (-width)+x
  elseif(relpoint[1] == GUIItem.Middle) then
    x = x-(width/2)
  end
    
  if(relpoint[2] == GUIItem.Bottom) then
    y = (-height)+y
  elseif(relpoint[2] == GUIItem.Center) then
    y = y-(height/2)
  end
  
  
  self:SetPosition(x, y, SkipHitRecUpdate)
end

local function CheckPoint(point, x, y, reltivePoint)
  
  if(not reltivePoint) then
    reltivePoint = point 
  end

  if(not x) then
    x,y = 0,0
  end

  point = PointToAnchor[point]
  reltivePoint = PointToAnchor[reltivePoint]

  if(not point) then
    error("Unknowed point " .. tostring(point))
  end

  if(not reltivePoint) then
    error("Unknowed relative point "..tostring(reltivePoint))
  end

  return {point, x, y, reltivePoint}, point == reltivePoint
end 

/*
 Point type
  1 = min/left
  2 = center
  3 = max/right
*/
function CalcSizeFromPoints(point1, point2, x1, x2, size)
  
  local sizeChange

  //flip the values around if point2 is on the right and point1 is on the left
  if(point1 > point2) then
    local temp = point2
    point2 = point1
    point1 = temp
    
    temp = x1
    x1 = x2
    x1 = temp
  end

  if(point1 == 0) then
    sizeChange = x1
  elseif(point1 == 1) then
    sizeChange = ((size/2)+x1)
  else
    sizeChange = size+x1
  end

  if(point2 == 0) then
    sizeChange = sizeChange+x2
  elseif(point2 == 1) then
    sizeChange = sizeChange+((size/2)+x2)
  else
    sizeChange = sizeChange+(-x2)
  end

  return size-sizeChange
end

function GetSizeFromPoints(anchor1, anchor2, size)
  
  local width, height
  
  local point1 = anchor1[1]
  local point2 = anchor2[1]
 
  if(point1[1] ~= point2[1]) then
    width = CalcSizeFromPoints(point1[1], point2[1], anchor1[2], anchor2[2], size.x)
  end
  
  if(point1[2] ~= point2[2]) then
    height = CalcSizeFromPoints(point1[2], point2[2], anchor1[3], anchor2[3], size.y)
  end
  
  return width, height
end

function BaseControl:SetPoint2(point, x, y, reltivePoint)
  
  local anchorPoint1 = self.AnchorPoint1
  assert(anchorPoint1, "Can't set second anchor point when the first is not set")
  
  local anchorPoint2, pointsSameSide = CheckPoint(point, x, y, reltivePoint)

  assert(pointsSameSide)

  if(anchorPoint1[1] == anchorPoint2[1] and anchorPoint1[4] == anchorPoint2[4]) then
    error("Error cant set Point2 sides to the same as Point1 one")
  end
  
  self.AnchorPoint2 = anchorPoint2
  
  if(self.Parent and self.AnchorPoint1) then
    self:UpdateSizeFromPoints()
  end
end

function BaseControl:UpdateSizeFromPoints()
  
  local anchor1, anchor2 = self.AnchorPoint1, self.AnchorPoint2
  
  local width,height = self.Size.x,self.Size.y
  
  local ParentSize = self.Parent.Size
 
  local point1 = anchor1[1]
  local point2 = anchor2[1]
 
  if(point1[1] ~= point2[1]) then
    width = CalcSizeFromPoints(point1[1], point2[1], anchor1[2], anchor2[2], ParentSize.x)
  end
  
  if(point1[2] ~= point2[2]) then
    height = CalcSizeFromPoints(point1[2], point2[2], anchor1[3], anchor2[3], ParentSize.y)
  end
  
  self:SetSize(width, height)
end

--the control needs to set its size if it want to pass a reltivePoint
function BaseControl:SetPoint(point, x, y, reltivePoint, SkipHitRecUpdate)
  
  local anchorPoint = CheckPoint(point, x, y, reltivePoint)

  self.AnchorPoint1 = anchorPoint

  self:SetAnchor(anchorPoint[1][1], anchorPoint[1][2])
  
  self:UpdatePointOffset()
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

function BaseControl:ShowChildControls()
  
  for _, control in ipairs(self.ChildControls) do
    control:Show()
  end

end

function BaseControl:HideChildControls()
  
  for _, control in ipairs(self.ChildControls) do
    control:Hide()
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

function BaseControl:SetDraggable(dragButton)
  self.DragButton = dragButton or InputKey.MouseButton0
  self.DragEnabled = true

  self:SetupHitRec()

  self:AddFlag(ControlFlags.Draggable)
end

function BaseControl:AddFlag(flagBit)
  self.Flags = bor(self.Flags, flagBit)
end

function BaseControl:IsWindowFrame()
  return band(self.Flags, ControlFlags.IsWindow) ~= 0
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

function ButtonMixin:Initialize()
  
  if(self.ClickSound == nil) then
    self.ClickSound = "sound/ns2.fev/common/button_click"
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


if(not FontTemplate) then
  FontTemplate = {}
  
  local instance_mt = {__index = FontTemplate}
  
  local mt = {
    __call = function(self, ...)
      local font = setmetatable({}, instance_mt)
      font:Initialize(...)
      
     return font
    end
  }
  
  setmetatable(FontTemplate, mt)
end

function FontTemplate:Initialize(...)
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

  local fontString = GUIManager:CreateTextItem()

  setmetatable(debug.getfenv(fontString), GUIItemTable)
  self:Apply(fontString)

  return fontString
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
  else
    font:SetFontName("arial")
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

