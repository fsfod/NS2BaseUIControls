
//ControlClass('ScrollBar', Draggable)

ControlClass('ScrollBar', BaseControl)

local ButtonPadding = 0.1
local ButtonWidth = 0.8
local ButtonScrollSpace = 0.5
local BarWidth = 0.7


function ScrollBar:__init(width, height)
  BaseControl.Initialize(self)

  self.TraverseChildFirst = true

  width = width or 25
  height = height or 300

  local SideScroll = width > height
  self.SideScroll = SideScroll

  local bg = self:CreateRootFrame(width, height)
  bg:SetColor(Color(0.1, 0.1, 0.1, 1))
  
  local Up = ArrowButton(40, 40, (SideScroll and "Left") or "Up")
    Up.OnClicked = {self.UpClick, self}
    self:AddChild(Up)
  self.Up = Up
    //:SetPoint("Top", -10, -5)

  local Down = ArrowButton(40, 40, (SideScroll and "Right") or "Down")
    self:AddChild(Down)
    Down.OnClicked = {self.DownClick, self}
  self.Down = Down
    
  local Bar = SliderButton()
    Bar.SideScroll = self.SideScroll
    self:AddChild(Bar)
  self.Bar = Bar
  
  self:SetSize(width, height)
  
  self.StepAmount = 1
  self:SetMinMax(0, 1)
  self.StepSize = 0.05
end

function ScrollBar:SetMinMax(min, max)

  self.MinValue = min
  self.MaxValue = max
  //self.Value = min

  self.Range = max-min
  
  self.StepSize = self.StepAmount/self.Range
  
  //InteralSetValue will clamp the value for us
  self:InteralSetValue(self.Value or min, false, true)
end

function ScrollBar:EnableScrolling()
  self.Disabled = false
  self.Bar:Show()
end

function ScrollBar:DisableScrolling()
  self.Disabled = true
  self.Bar:Hide()
end

function ScrollBar:SetStepSize(amount)
  self.StepAmount = amount
  self.StepSize = amount/self.Range
end

function ScrollBar:SetValue(newValue)
  self:InteralSetValue(newValue, false, true)
end

function ScrollBar:OnSliderMoved(newValue)
  self:InteralSetValue(self.MinValue+(self.Range*newValue), true)
end

function ScrollBar:BarDragStarted()
  self:FireEvent(self.DragStarted, self)
end

function ScrollBar:BarDragEnded()
  self:FireEvent(self.DragEnded, self)
end

function ScrollBar:OnMouseWheel(direction)
  if(not self.SideScroll) then
    direction = -direction
  end

  local amount = (self.Range*self.StepSize)*direction
 
  if(not self.Disabled) then
    self:InteralSetValue(self.Value+amount)
  end
end

function ScrollBar:UpClick(down)
  if(not self.Disabled and down) then
    self:InteralSetValue(self.Value-(self.Range*self.StepSize))
  end
end

function ScrollBar:DownClick(down)
  if(not self.Disabled and down) then
    self:InteralSetValue(self.Value+(self.Range*self.StepSize))
  end
end

function ScrollBar:InteralSetValue(value, fromSlider, fromInput)
  self.Value = Clamp(value, self.MinValue, self.MaxValue)
  
  if(not fromSlider) then
    self.Bar:SetValuePosition((self.Value-self.MinValue)/self.Range)
  end

  if(not fromInput) then
    self:FireEvent(self.ValueChanged, self.Value, fromSlider)
  end
end

function ScrollBar:SetSize(width, height)
  BaseControl.SetSize(self, width, height)
  
  if(type(width) ~= "number") then
    width = height.x
    height = height.y
  end
  
  local SizeSide,LongSide

  if(not self.SideScroll) then
    SizeSide,LongSide = width, height
  else
    SizeSide,LongSide = height, width
  end
  
  local ButtonSize = SizeSide*ButtonWidth  
  local TotalButtonPadding = (SizeSide*ButtonPadding*2)
  
  local BarSize = SizeSide*BarWidth
  local ScrollStart = ButtonSize+TotalButtonPadding
  local ScrollEnd = LongSide-ScrollStart
  
  self.ScrollClickRange = {ScrollStart, ScrollEnd, ScrollStart+(BarSize/2), ScrollEnd-(BarSize/2)}
 
  self.Up:SetSize(ButtonSize, ButtonSize)
  self.Down:SetSize(ButtonSize, ButtonSize)
  
  if(not self.SideScroll) then
    self.Up:SetPoint("Top", 0, width*ButtonPadding, "Top")
    self.Down:SetPoint("Bottom", 0, -(width*ButtonPadding), "Bottom")
    
    self.Bar:SetPoint("Top", 0, ScrollStart, "Top")
  else
    self.Up:SetPoint("Left", height*ButtonPadding, 0, "Left")
    self.Down:SetPoint("Right", -(height*ButtonPadding), 0, "Right")

    self.Bar:SetPoint("Left", ScrollStart, 0, "Left")
  end

  self.Bar:SetSize(BarSize, BarSize)
    
  self.Bar:SetMaxValuePositon(LongSide-((ScrollStart*2)+BarSize))
end


function ScrollBar:OnClick(button, down, x,y)
    
  if(down) then
    if(self.Disabled) then
      return
    end
    
    local scrollArea = self.ScrollClickRange
    
    local MousePos = (not self.SideScroll and y) or x
          
    if(MousePos > scrollArea[1] and MousePos < scrollArea[2]) then        
      local value
      
      if(MousePos > scrollArea[4]) then
        value = self.MaxValue
      elseif(MousePos < scrollArea[3]) then
        value = self.MinValue
      else
        local ScrollPercent = (MousePos-scrollArea[3])/(scrollArea[4]-scrollArea[3])
    
        value = self.MinValue+(ScrollPercent*self.Range)
      end
      self:InteralSetValue(value)
    end
  end
end

ControlClass('SliderButton', BaseControl)

function SliderButton:__init()
  BaseControl.Initialize(self, 30, 30)
  
  self:SetColor(Color(0.78, 0.3, 0, 1))
  
  self.MinValuePos = 0
  self.MaxValuePos = 500
  self.CurrentValuePositon = 0
  self.StartPositon = {0, 0}

  self:SetDraggable()
end

function SliderButton:OnEnter()
  self:SetColor(Color(0.9, 0.4, 0, 1))
end

function SliderButton:OnLeave()
  self:SetColor(Color(0.78, 0.3, 0, 1))
end

function SliderButton:SetValuePosition(percent)
  self.CurrentValuePositon = percent*self.MaxValuePos
  self:UpdatePosition()
end

function SliderButton:SetMaxValuePositon(max)
  
  if(self.CurrentValuePositon ~= 0) then
    self.CurrentValuePositon = (self.CurrentValuePositon/self.MaxValuePos)*max
  end

  self.MaxValuePos = max

  self:UpdatePosition()
end

function SliderButton:UpdatePosition()
  
  if(not self.SideScroll) then
    self:SetPosition(self.StartPositon[1], self.StartPositon[2]+self.CurrentValuePositon, true)
  else
    self:SetPosition(self.StartPositon[1]+self.CurrentValuePositon, self.StartPositon[2], true)
  end
end

function SliderButton:SetPosition(x, y, DragSetPosiiton)
  BaseControl.SetPosition(self, x, y)
  
  if(not DragSetPosiiton) then
    self.StartPositon[1] = self.Position.x
    self.StartPositon[2] = self.Position.y
  end
end

function SliderButton:OnDragStart()

  self.DragStartOffset = self.CurrentValuePositon
  
  self.Parent:BarDragStarted(self)
end

function SliderButton:OnDragMove(pos)
  
  local offset = pos.y
  
  if(self.SideScroll) then
    offset = pos.x
  end

  offset = Clamp(self.DragStartOffset+offset, self.MinValuePos, self.MaxValuePos)
  
  if(offset ~= self.CurrentValuePositon) then
    self.CurrentValuePositon = offset
    
    self:UpdatePosition()

    self.Parent:OnSliderMoved(offset/self.MaxValuePos)
  end
end

function SliderButton:OnDragStop()

  if(not self.SideScroll) then
    self:SetPosition(self.Position.x, self.StartPositon[2]+self.CurrentValuePositon, true)
  else
    self:SetPosition(self.StartPositon[1]+self.CurrentValuePositon, self.Position.y,  true)
  end

  self.Parent:BarDragEnded()
end

local ArrowTextures = {
  Up = {0,0, 14, 15},
  Down = {14,0, 29, 15},
  Left = {29,0, 45,15},
  Right = {45,0, 29,15},
}

ControlClass('ArrowButton', BaseControl)


local NormalColor = Color(66/255, 66/255, 66/255, 1)
local MouseOverColor = Color(90/255, 90/255, 90/255, 1)

local Green = Color(0, 1, 0, 1)

function ArrowButton:__init(width, height, mode)
  BaseControl.Initialize(self, width, height)
  //self.RootFrame:SetBlendTechnique(GUIItem.Add)
  self:SetupHitRec()

  self:SetColor(NormalColor)

  local arrow = GUIManager:CreateGraphicItem()
    arrow:SetColor(Color(1,1,1, 1))
    arrow:SetBlendTechnique(GUIItem.Add)
    arrow:SetTexture("ui/arrows.dds")
    arrow:SetTexturePixelCoordinates(unpack(ArrowTextures[mode]))
  self:AddGUIItemChild(arrow)
  self.Overlay = arrow

  self:SetSize(Vector(width, height, 0))

  self.IsDown = false
end

function ArrowButton:SetSize(width, height)
  BaseControl.SetSize(self, width, height)
  self.Overlay:SetSize(self.Size)
end

function ArrowButton:OnEnter()
  self.MouseOver = true
  self:SetColor(MouseOverColor)
end

function ArrowButton:OnLeave()
  self.MouseOver = false
  self:SetColor(NormalColor)
end

function ArrowButton:OnClick(button, down)
  
  if(button == InputKey.MouseButton0) then
    if(down) then      
      self.IsDown = true
      
      if(self.OnClicked) then
        self.OnClicked[1](self.OnClicked[2], true)
      end 

      self.Overlay:SetColor(Color(0, 1, 1, 1))
    else
      self.IsDown = false
      
      self.Overlay:SetColor(Color(1, 1, 1, 1))

      if(self.MouseOver) then
        self:SetColor(MouseOverColor)
      else
        self:SetColor(NormalColor)
      end
      
      if(self.OnClicked) then
        self.OnClicked[1](self.OnClicked[2], false)
      end 
    end
  end
end