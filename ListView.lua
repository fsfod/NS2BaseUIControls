class'LVTextItem'

local white = Color(1, 1, 1, 1)
local black = Color(0, 0, 0, 1)

function LVTextItem:__init()

  local font = GUIManager:CreateTextItem()
	 font:SetFontSize(17)
	 font:SetColor(white)
	self.Text = font
	
	self.PositionVector = Vector(0,0,0)
end

function LVTextItem:SetData(msg)
  self.Text:SetText(msg)
end

function LVTextItem:OnShow()
  self.Text:SetIsVisible(true)
end

function LVTextItem:OnHide()
  self.Text:SetIsVisible(false)
end

function LVTextItem:SetWidth(width)
end

function LVTextItem:SetPos(x, y)
  local vec = self.PositionVector
  
  vec.x = x
  vec.y = y
  
  self.Text:SetPosition(vec)
end

function LVTextItem:GetRoot()
  return self.Text
end

function CreateTextItem()
  return LVTextItem()
end

class 'ListView'(BaseControl)

ListView.DefaultHeight = 120
ListView.DefaultWidth = 300
ListView.SelectedItemColor = Color(0, 0, 0.3, 1)


function ListView:Initialize(width, height, itemCreator, itemHeight, itemSpacing)
	
	height = height or ListView.DefaultHeight
	width = width or ListView.DefaultWidth
	
	self.ItemSpacing = itemSpacing or self.ItemSpacing or 1
	self.ItemHeight = itemHeight or self.ItemHeight or 16	
	self.ItemDistance = self.ItemHeight + self.ItemSpacing
	self.ScrollBarWidth = 18
	
	if(self.ItemsSelectble == nil) then
	  self.ItemsSelectble = true
	end

	self.CurrentItemIndex = 1
	
	local bg = GUIManager:CreateGraphicItem()
	  bg:SetColor(Color(0.5,0.5,0.5,0.5))
	
	self:SetRootFrame(bg)
	self:SetupHitRec()

  local selectBG = GUIManager:CreateGraphicItem()
    selectBG:SetSize(Vector(width, self.ItemHeight, 0))
    selectBG:SetColor(self.SelectedItemColor)
    bg:AddChild(selectBG)
  self.SelectBG = selectBG


	self.ItemsAnchor = GUIManager:CreateGraphicItem()
	self.ItemsAnchor:SetColor(Color(0,0,0,0))
	bg:AddChild(self.ItemsAnchor)
	
	self.CreateItem = itemCreator or self.CreateItem or CreateTextItem
	
	local scrollbar = ScrollBar()
	 scrollbar:SetPoint("TopRight", 0, 0, "TopRight")
	 scrollbar.OnValueChanged = {self, self.OnScrollChanged}
	 scrollbar:SetStepSize(1)
	 scrollbar:DisableScrolling()
	 scrollbar:Hide()
	self.ScrollBar = scrollbar
	self:AddChild(scrollbar)

  self.ScrollHiddenUntilNeeded = true

  self.Items = {}

	self:SetSize(width, height)


	self:CreateItems()
	self.AnchorPosition = Vector(0,0,0)
end

function ListView:Uninitialize()
  BaseControl.Uninitialize(self)
end

function ListView:SetScrollBarWidth(width)
  
  self.ScrollBarWidth = width
  self.ScrollBar:SetSize(width, self:GetHeight())
end

function ListView:SetSize(width, height)
  BaseControl.SetSize(self, width, height)
  self.ScrollBar:SetSize(self.ScrollBarWidth, height)
 
  self.MaxVisibleItems = math.floor(height/(self.ItemDistance))
  
  self.ItemWidth = width-15
end

function ListView:GetItemAtCoords(x, y)
 local ItemDistance = self.ItemHeight+self.ItemSpacing
  
 local index = ((y-(y%ItemDistance))/ItemDistance)+1
 
  if(index <= #self.Items and index <= #self.ItemDataList) then
    return index
  end
 
  return nil
end

function ListView:OnItemSelected(index)
  
  local DataIndex = self.ViewStart+index-1
  
  self.SelectedItem = DataIndex

  self.SelectBG:SetIsVisible(true)
  self.SelectBG:SetPosition(Vector(0, (index-1)*self.ItemDistance, 0))
  
  self:FireEvent(self.ItemSelected, self.ItemDataList[DataIndex], DataIndex)
end

function ListView:OnClick(button, down, x,y)

  if(not down) then
	  if(self.ClickedItem) then
	    self.ClickedItem:OnClick(button, false)
	    self.ClickedItem = nil
	  end
	  
	  return
  end
  
  local frame = self:ContainerOnClick(button, down, x,y)
	
	--the scroll bar was clicked
  if(frame) then
		return frame
	end
  
----start of item hit dection and selection code-------
  
  local ItemDistance = self.ItemHeight+self.ItemSpacing
  
  local index = self:GetItemAtCoords(x,y)
  
  if(index) then
    local item = self.Items[index]
    local DataIndex = self.ViewStart+index-1

    if(self.ItemsSelectble) then
      self:OnItemSelected(index)
    end

    if(item.OnClick) then
      item:OnClick(button, down, x, y%ItemDistance)
      
      self.ClickedItem = item
     return self
    else
      if(self.ItemDblClicked and self.LastClickTime and self.LastClickedIndex == DataIndex and 
        (Client.GetTime()-self.LastClickTime) < MouseTracker.DblClickSpeed) then

        self:FireEvent(self.ItemDblClicked, self.ItemDataList[DataIndex], DataIndex)
      end
    
      self.LastClickedIndex = DataIndex
      self.LastClickTime = Client.GetTime()
    end
  end
end

function ListView:ResetSelection()
  self.SelectedItem = nil
  self.ClickedItem = nil
  
  self.SelectBG:SetIsVisible(false)
end

function ListView:SetSelectedIndex(index)
  assert(index > 0 and index <= #self.ItemDataList)
  
  self.SelectedItem = index
  
  if(index < self.ViewStart or index > self.ViewStart+self.MaxVisibleItems) then
    self.SelectBG:SetIsVisible(false)
  else
    self.SelectBG:SetIsVisible(true)
    
    
    self.SelectBG:SetPosition(Vector(0, (index-self.ViewStart)*self.ItemDistance, 0))
  end
end

function ListView:GetSelectedIndex()
  return self.SelectedItem
end

function ListView:GetSelectedIndexData()
  
  local index = self.SelectedItem
  
  if(index) then
    return self.ItemDataList[index]
  end
  
  return nil
end

function ListView:ListSizeChanged()

	local extra = #self.ItemDataList-self.MaxVisibleItems

  if(self.SelectedItem and self.SelectedItem > #self.ItemDataList) then
    self:ResetSelection()
  end

	if(extra <= 0) then
		self.NonVisibleCount = 0
		
		if(self.ScrollHiddenUntilNeeded) then
		  self.ScrollBar:Hide()
		end
		
		if(not self.ScrollBar.Disabled) then
		  self.ScrollBar:DisableScrolling()
		  self:SetListToIndex(1)
		else
		  if(#self.ItemDataList <= self.MaxVisibleItems) then
		    self:RefreshItems()
		  end
	  end
		//self.ScrollBar:SetValue(1)
	 return
	end

  if(self.ScrollHiddenUntilNeeded and self.ScrollBar.Hidden) then
    self.ScrollBar:Show()
	end

	self.NonVisibleCount = extra
	self.ScrollBar:SetMinMax(1, extra+1)

  if(self.ScrollBar.Disabled) then
    self.ScrollBar:EnableScrolling()
    self.ScrollBar:SetValue(1)

    if(not self.AutoScrol) then
      self:SetListToIndex(1)
    end
  end
  
  if(self.AutoScrol) then
    self:SetListToIndex(extra+1)
  end
end

function ListView:SetDataList(list)
	self.ItemDataList = list
	
	self:ResetSelection()
	self:SetListToIndex(1)
	self:ListSizeChanged()
end

function ListView:ListDataModifed()
  self:ResetSelection()
  self:RefreshItems()
end

function ListView:RefreshItems()
  local TotalCount = #self.ItemDataList

  local SelectedIndex = -1

  if(self.SelectedItem) then
    local index = self.SelectedItem
    
    if(index < self.ViewStart or index > self.ViewStart+self.MaxVisibleItems) then
      //self.SelectedItem = nil
      self.SelectBG:SetIsVisible(false)
    else
      SelectedIndex = (index-self.ViewStart)+1
      self.SelectBG:SetIsVisible(true)
      self.SelectBG:SetPosition(Vector(0, (SelectedIndex-1)*self.ItemDistance, 0))
    end
  end

	for i=1,self.MaxVisibleItems do
	  if(i <= TotalCount) then
      self.Items[i]:SetData(self.ItemDataList[i+self.ViewStart-1], SelectedIndex == i)
    else
      self.Items[i]:OnHide()
      self.Items[i].Hidden = true
    end
  end
end

function ListView:SetListToIndex(index, fromScrollBar)
	
	local maxindex = 1+#self.ItemDataList-self.MaxVisibleItems

  if(maxindex <= 0) then
    index = 1
	elseif(index > maxindex) then
		index = maxindex
	end
	
	self.ViewStart = index
	
	if(not fromScrollBar) then
    self.ScrollBar:SetValue(index)
  end
 
	self:RefreshItems()
end

function ListView:OnScrollChanged(value)
	self:SetListToIndex(math.floor(value), true)
end

function ListView:SetYScroll(y)
	self.AnchorPosition.y = y
	self.ItemsAnchor:SetPosition(self.AnchorPosition)
end

function ListView:CreateItems()
  local x = 5

  local width = self.ItemWidth

  for i=1,self.MaxVisibleItems do
    local item = self.CreateItem(self)
     self.ItemsAnchor:AddChild(item:GetRoot())
     item:SetPos(x, (self.ItemHeight+self.ItemSpacing)*(i-1))
     item:SetWidth(width)

		self.Items[i] = item
  end
end

function ListView:ResetPositions()
	local x = 5

	for i=1,self.MaxVisibleItems do
    self.Items[i]:SetPos(x, (self.ItemHeight+self.ItemSpacing)*i)
  end
end

class 'BaseButton' (BaseControl)

local NormalColor = Color(66/255, 66/255, 66/255, .9)
local MouseOverColor = Color(0.8666, 0.3843, 0, 1)

local Green = Color(0, 1, 0, 1)

function BaseButton:__init(width, height)
	BaseControl.Initialize(self, width, height)
	//self.RootFrame:SetBlendTechnique(GUIItem.Add)
	self:EnableClicks()

  self.RootFrame:SetColor(NormalColor)

  local overlay = GUIManager:CreateGraphicItem()
	  overlay:SetColor(NormalColor)
	  overlay:SetBlendTechnique(GUIItem.Add)
	self.RootFrame:AddChild(overlay)
	self.Overlay = self.RootFrame

	self:SetSize(Vector(width, height, 0))
	//self.RootFrame:SetColor(NormalColor)

	self.IsDown = false
end

function BaseButton:SetSize(width, height)
  BaseControl.SetSize(self, width, height)
  self.Overlay:SetSize(self.Size)
end

function BaseButton:OnEnter()
		self.MouseOver = true
		self.Overlay:SetColor(MouseOverColor)
  return self
end

function BaseButton:OnLeave()
  self.MouseOver = false
  self.Overlay:SetColor(NormalColor)
end

function BaseButton:OnClick(button, down)
	
	if(button == InputKey.MouseButton0) then
		if(down) then			
			self.IsDown = true
			
			if(self.OnClicked) then
				self.OnClicked[2](self.OnClicked[1], true)
			end 

			self.Overlay:SetColor(Green)
		else
			self.IsDown = false

			if(self.MouseOver) then
			  self.Overlay:SetColor(MouseOverColor)
			else
			  self.Overlay:SetColor(NormalColor)
			end
			
			if(self.OnClicked) then
				self.OnClicked[2](self.OnClicked[1], false)
			end 
		end
	end
	
	return self
end






