
//class 'ScrollBar'(Draggable)

class 'ScrollBar'(BaseControl)

local ButtonPadding = 0.1
local ButtonWidth = 0.8
local ButtonScrollSpace = 0.5
local BarWidth = 0.7


function ScrollBar:__init()
	BaseControl.Initialize(self)

	local bg = self:CreateRootFrame(50, 600)
	bg:SetColor(Color(0.1, 0.1, 0.1, 1))
	
	local Up = ArrowButton(40, 40, "Up")
		Up.OnClicked = {self.UpClick, self}
		self:AddChild(Up)
	self.Up = Up
		//:SetPoint("Top", -10, -5)

	local Down = ArrowButton(40, 40, "Down")
		self:AddChild(Down)
		Down.OnClicked = {self.DownClick, self}
	self.Down = Down
		
	local Bar = SliderButton()
		self:AddChild(Bar)
	self.Bar = Bar
	
	self.ButtonIncrement = 0.05
	
	self:SetSize(50, 300)
	self.StepAmount = 1
	self:SetMinMax(0, 1)
	self.StepSize = 0.05
end

function ScrollBar:SetMinMax(min, max)
	
	self.MinValue = min
	self.MaxValue = max
	self.Value = min

	self.Range = max-min
	
	self.StepSize = self.StepAmount/self.Range
end

function ScrollBar:EnableScrolling()
  self.Disabled = false
  self.Bar:Show()
end

function ScrollBar:DisableScrolling()
  self.Disabled = true
  self.Bar:Hide()
end

function ScrollBar:OnSliderMoved(newValue)
	self.Value = self.MinValue+(self.Range*newValue)
	self:IntenalValueChanged(true)
end

function ScrollBar:UpClick(down)
	if(not self.Disabled and down) then
		self:SetValue(self.Value-(self.Range*self.StepSize))
	end
end

function ScrollBar:SetStepSize(amount)
	self.StepAmount = amount
	self.StepSize = amount/self.Range
end

function ScrollBar:DownClick(down)
	if(not self.Disabled and down) then
		self:SetValue(self.Value+(self.Range*self.StepSize))
	end
end

function ScrollBar:SetValue(newValue)
	self.Value = Clamp(newValue, self.MinValue, self.MaxValue)
	self:IntenalValueChanged()
end

function ScrollBar:IntenalValueChanged(fromSlider)
	if(not fromSlider) then
		self.Bar:SetValuePosition((self.Value-self.MinValue)/self.Range)
	end

	local ValueChanged = self.OnValueChanged
	
	if(ValueChanged) then
		ValueChanged[2](ValueChanged[1], self.Value)
	end
end

function ScrollBar:SetSize(width, height)
	BaseControl.SetSize(self, width, height)
	
	if(type(width) ~= "number") then
		width = height.x
		height = height.y
	end
	
	local ButtonSize = width*ButtonWidth

	self.Up:SetSize(ButtonSize, ButtonSize)
	self.Up:SetPoint("Top", 0, width*ButtonPadding, "Top")

	self.Down:SetSize(ButtonSize, ButtonSize)
	self.Down:SetPoint("Bottom", 0, -(width*ButtonPadding), "Bottom")
	
	local TotalButtonPadding = (width*ButtonPadding*2)
	
	local BarSize = width*BarWidth
	local ScrollStart = ButtonSize+TotalButtonPadding
  local ScrollEnd = height-ScrollStart
  self.ScrollClickRange = {ScrollStart, ScrollEnd, ScrollStart+(BarSize/2), ScrollEnd-(BarSize/2)}

	self.Bar:SetSize(BarSize, BarSize)
	self.Bar:SetPoint("Top", 0, ScrollStart, "Top")
	self.Bar:SetMaxValuePositon(height-((ScrollStart*2)+BarSize))
end


function ScrollBar:OnClick(button, down, x,y)
		
	if(down) then
		local frame = self:ContainerOnClick(button, down, x,y)
	
	  --one of our buttons or slider was clicked
		if(frame) then
			return frame
		else

		  if(self.Disabled) then
	      return
	    end
		
		  local scrollArea = self.ScrollClickRange
		  
		  if(y > scrollArea[1] and y < scrollArea[2]) then		    
		    local value
		    
		    if(y > scrollArea[4]) then
		      value = self.MaxValue
		    elseif(y < scrollArea[3]) then
		      value = self.MinValue
		    else
		      local ScrollPercent = (y-scrollArea[3])/(scrollArea[4]-scrollArea[3])

		      value = self.MinValue+(ScrollPercent*self.Range)
		    end
		    self:SetValue(value)
		    
		    return self
		  end
		end
	end
		//Draggable.OnClick(self, button, down, x, y)

		//return self
end

class 'SliderButton'(Draggable)

function SliderButton:__init()
	Draggable.__init(self)
	self:SetupHitRec()
	
	local bg = self:CreateRootFrame(30, 30)
	bg:SetColor(Color(0, 1, 1, 1))
	
	self.MinValuePos = 0
	self.MaxValuePos = 500
	self.CurrentValuePositon = 0
	self.StartPositon = {0, 0}
end

function SliderButton:OnEnter()
		self.RootFrame:SetColor(Color(0, 1, 0, 1))
	return self
end

function SliderButton:OnLeave()
	self.RootFrame:SetColor(Color(0, 1, 1, 1))
end

function SliderButton:OnClick(...)
	return Draggable.OnClick(self, ...)
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

function SliderButton:UpdatePosition(newPos)
	self:SetPosition(self.StartPositon[1], self.StartPositon[2]+self.CurrentValuePositon, true)
end

function SliderButton:SetPosition(x, y, DragSetPosiiton)
	BaseControl.SetPosition(self, x, y)
	
	if(not DragSetPosiiton) then
		self.StartPositon[1] = self.Position.x
		self.StartPositon[2] = self.Position.y
	end
end

function SliderButton:OnDragStart()
	Draggable.OnDragStart(self)
	self.DragPos.x = self.Position.x
	
	self.MouseMin = self.DragStartPos[2]-self.CurrentValuePositon
	self.MouseMax = self.MouseMin+self.MaxValuePos
end

function SliderButton:DragMouseMove(x,y)

	if(self.DragStage == 0) then
    self:OnDragStart()
  end
	
	if(self.IsDragging) then
		local MousePos = y-self.MouseMin
		local NewPosiiton = Clamp(MousePos, self.MinValuePos, self.MaxValuePos)
		
			if(NewPosiiton ~= self.CurrentValuePositon) then
				self.CurrentValuePositon = Clamp(MousePos, self.MinValuePos, self.MaxValuePos)
				self.DragPos.y = self.StartPositon[2]+self.CurrentValuePositon
			
				self.DragRoot:SetPosition(self.DragPos)
				self.Parent:OnSliderMoved(self.CurrentValuePositon/self.MaxValuePos)
			end
	else
		MouseTracker.UnregisterCallback(self, "MouseMove")
	end
end

function SliderButton:OnDragStop()
	Draggable.OnDragStop(self, true)

	self:SetPosition(self.Position.x, self.StartPositon[2]+self.CurrentValuePositon, true)
end

local ArrowTextures = {
  Up = {0,0, 14, 15},
  Down = {14,0, 29, 15},
}

class 'ArrowButton'(BaseControl)


local NormalColor = Color(66/255, 66/255, 66/255, 1)
local MouseOverColor = Color(90/255, 90/255, 90/255, 1)

local Green = Color(0, 1, 0, 1)

function ArrowButton:__init(width, height, mode)
	BaseControl.Initialize(self, width, height)
	//self.RootFrame:SetBlendTechnique(GUIItem.Add)
	self:SetupHitRec()

  self.RootFrame:SetColor(NormalColor)

  local arrow = GUIManager:CreateGraphicItem()
	  arrow:SetColor(Color(1,1,1, 1))
	  arrow:SetBlendTechnique(GUIItem.Add)
	  arrow:SetTexture("ui/arrows.dds")
	  arrow:SetTexturePixelCoordinates(unpack(ArrowTextures[mode]))
	self.RootFrame:AddChild(arrow)
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
		self.RootFrame:SetColor(MouseOverColor)
  return self
end

function ArrowButton:OnLeave()
  self.MouseOver = false
  self.RootFrame:SetColor(NormalColor)
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
			  self.RootFrame:SetColor(MouseOverColor)
			else
			  self.RootFrame:SetColor(NormalColor)
			end
			
			if(self.OnClicked) then
				self.OnClicked[1](self.OnClicked[2], false)
			end 
		end
	end
	
	return self
end