class'LVTextItem'

local white = Color(1, 1, 1, 1)
local black = Color(0, 0, 0, 1)

function LVTextItem:__init()

  local font = GUIManager:CreateTextItem()
	 font:SetFontSize(17)
	 font:SetColor(white)
	 font:SetPosition(Vector(4,0,0))
	self.Text = font
	
	self.PositionVector = Vector(0,0,0)
end

function LVTextItem:SetData(msg)
  if(self.Hidden) then
    self.Text:SetIsVisible(true)
    self.Hidden = nil
  end
  
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

function LVTextItem:SetPosition(x, y)
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
	self.ScrollBarWidth = 20
	
	if(self.ItemsSelectble == nil) then
	  self.ItemsSelectble = true
	end

	self.CurrentItemIndex = 1
	
	local bg = GUIManager:CreateGraphicItem()
	  bg:SetColor(Color(0.5,0.5,0.5,0.5))
	
	self:SetRootFrame(bg)
	self:SetupHitRec()

  local selectBG = GUIManager:CreateGraphicItem()
    selectBG:SetIsVisible(false)
    selectBG:SetColor(self.SelectedItemColor)
    bg:AddChild(selectBG)
  self.SelectBG = selectBG

	self.ItemsAnchor = GUIManager:CreateGraphicItem()
	self.ItemsAnchor:SetColor(Color(0,0,0,0))
	bg:AddChild(self.ItemsAnchor)
	
	self.CreateItem = itemCreator or self.CreateItem or CreateTextItem
	
	local scrollbar = ScrollBar()
	 scrollbar:SetPoint("TopRight", 0, 0, "TopRight")
	 scrollbar.ValueChanged = {self.OnScrollChanged, self}
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

function ListView:ClampViewStart()
  
  if(not self.ItemDataList or #self.ItemDataList == 0) then
    self.ViewStart = 1
   return
  end
  
	local extra = #self.ItemDataList-self.MaxVisibleItems
	
	if(extra < 0) then
	  self.ViewStart = 1
  elseif(self.ViewStart > extra+1) then
	  self.ViewStart = extra+1
	  self.ScrollBar:SetValue(self.ViewStart)
	end
end
 
function ListView:UpdateScrollbarRange()
	local extra = (self.ItemDataList and #self.ItemDataList-self.MaxVisibleItems) or 0

  local ScrollBar = self.ScrollBar

  if(extra > 0) then
    if(self.ScrollHiddenUntilNeeded and ScrollBar.Hidden) then
      ScrollBar:Show()
	  end
    
    if(ScrollBar.Disabled) then
      ScrollBar:EnableScrolling()
      ScrollBar:SetValue(1)
    end
    
    ScrollBar:SetMinMax(1, extra+1)
  else
    if(self.ScrollHiddenUntilNeeded) then
		  ScrollBar:Hide()
		end
		
		if(not ScrollBar.Disabled) then
		  ScrollBar:DisableScrolling()
		end
  end
end
 
function ListView:OnMaxVisibleChanged(maxVisible)

  local doAutoScroll = self.AutoScroll and self:IsAtAutoScrollPos()
  
  local oldVisibleCount = self.MaxVisibleItems
  self.MaxVisibleItems = maxVisible
   
  if(oldVisibleCount) then
    if(oldVisibleCount < maxVisible and #self.Items < maxVisible) then
      self:CreateItems(#self.Items+1)
    elseif(maxVisible < oldVisibleCount) then
    --just hide our extra items
      for i=self.MaxVisibleItems+1,oldVisibleCount do
        self.Items[i]:OnHide()
        self.Items[i].Hidden = true
      end
    end
    
    self:UpdateScrollbarRange()
	else
    self:CreateItems()
  end
  
  if(doAutoScroll) then
    self:JumpToListEnd(true)
  else
    self:ClampViewStart()
    self:RefreshItems()
  end
end
 
function ListView:GetHeightForLineCount(count)
  return (self.ItemDistance*count)+1 
end

function ListView:SetItemHeight(height, adjustFrameHeight)
  self.ItemHeight = height
	self.ItemDistance = height + self.ItemSpacing
	
	self:ResetPositions()
	
	if(adjustFrameHeight) then
	  self:SetSize(self:GetWidth(), self:GetHeightForLineCount(self.MaxVisibleItems))
	else
	  self:OnMaxVisibleChanged(math.floor(self:GetHeight()/self.ItemDistance))
	end
end

function ListView:SetSize(width, height)
  BaseControl.SetSize(self, width, height)
  self.ScrollBar:SetSize(self.ScrollBarWidth, height)
 
  self.SelectBG:SetSize(Vector(width, self.ItemHeight, 0))
  
  self.ItemWidth = width-15
  self:OnMaxVisibleChanged(math.floor(height/self.ItemDistance))
end

ListView.SetSize2 = ListView.SetSize

assert(ListView.SetSize ~= BaseControl.SetSize)

function ListView:GetItemAtCoords(x, y)
  
  local ScrollBar = self.ScrollBar
  
  --check to see if the point is within the scrollbar
  if(not ScrollBar.Hidden and x > (self:GetWidth()-ScrollBar:GetWidth()) ) then
    return nil
  end
  
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

function ListView:OnEnter(x,y)

  local ret = self:ContainerOnEnter(x,y)
  
  --the scrollbar was entered
  if(ret) then
    return ret
  end

  local index = self:GetItemAtCoords(x,y)

  if(index) then
    local item = self.Items[index]

    if(not item.Hidden and (item.OnEnter or item.ChildHasOnEnter)) then
      local hitrec = item.HitRec
      
      local enterFunc = item.OnEnter or BaseControl.ContainerOnEnter
      
      ret = enterFunc(item, x-hitrec[1],y-hitrec[2])
      
      if(ret) then
        self.EnteredEntry = item
      end

     return ret
    end
  end
  
  return false
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
        (Client.GetTime()-self.LastClickTime) < GUIManager.DblClickSpeed) then

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

function ListView:IsAtAutoScrollPos()
  local prevSize = self.PrevListSize  

  return (not prevSize or prevSize <= self.MaxVisibleItems or (prevSize-self.MaxVisibleItems)+1 == self.ViewStart)
end

function ListView:ListSizeChanged()

  local ListSize = #self.ItemDataList
	local extra = ListSize-self.MaxVisibleItems

  if(self.SelectedItem and self.SelectedItem > ListSize) then
    self:ResetSelection()
  end
  
  local DoAutoScroll = self.AutoScroll and self:IsAtAutoScrollPos()
  
  local prevSize = self.PrevListSize
  self.PrevListSize = ListSize

  self:UpdateScrollbarRange()

	if(extra <= 0) then
		self:RefreshItems()
	 return
	end

  --dont autoscroll if were not at the end of the list except if our list has just been set
  if(DoAutoScroll) then
    self:SetListToIndex(extra+1)
	else
	  if(prevSize and prevSize > ListSize) then
	    self:ClampViewStart()
	  end
	  
		--do a refresh if the list has just been set and there more items than MaxVisibleItems so just do a refresh since were no auto scrolling
		if(not prevSize or prevSize <= self.MaxVisibleItems) then
      self:RefreshItems()
    end
  end
end

function ListView:SetDataList(list)
	self.ItemDataList = list
	
	self:ResetSelection()
	self.ViewStart = 1
	self.PrevListSize = nil
	self:ListSizeChanged()
end

function ListView:ListDataModifed()
  self:ResetSelection()
  self:RefreshItems()
end

function ListView:RefreshItems()
  local TotalCount = (self.ItemDataList and #self.ItemDataList) or 0

  local SelectedIndex = -1

  if(self.SelectedItem) then
    local index = self.SelectedItem
    
    if(index < self.ViewStart or index > TotalCount or index > self.ViewStart+self.MaxVisibleItems) then
      //self.SelectedItem = nil
      self.SelectBG:SetIsVisible(false)
    else
      SelectedIndex = (index-self.ViewStart)+1
      self.SelectBG:SetIsVisible(true)
      self.SelectBG:SetPosition(Vector(0, (SelectedIndex-1)*self.ItemDistance, 0))
    end
  end

  if(self.EnteredEntry) then
    --todo handle clearing the entered state of an entry
  end

  self.EnteredEntry = nil

	for i=1,self.MaxVisibleItems do
	  if(i <= TotalCount) then
      self.Items[i]:SetData(self.ItemDataList[i+self.ViewStart-1], SelectedIndex == i)
    else
      self.Items[i]:OnHide()
      self.Items[i].Hidden = true
    end
  end
end

function ListView:JumpToListEnd(forceRefresh)
  
  local index = 1+#self.ItemDataList-self.MaxVisibleItems
  
  --don't do anything if theres not enough items yet or were already scrolled to the end of the list
  if(index <= 0 or (not forceRefresh and index == self.ViewStart)) then
    return
  end
  
  //Print("Jumping to End %i(%i)", index, #self.ItemDataList)
  
  self:SetListToIndex(index)
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

function ListView:CreateItems(startIndex)
  local x = 0

  local width = self.ItemWidth
  local height = self.ItemHeight

  startIndex = startIndex or 1

  for i=startIndex,self.MaxVisibleItems do
    local item = self.CreateItem(self, width, height)
     self.ItemsAnchor:AddChild(item:GetRoot())
     item:SetPosition(x, (height+self.ItemSpacing)*(i-1))
     //item:SetWidth(width)

		self.Items[i] = item
  end
end

function ListView:ResetPositions()
	local x = 0

	for i=1,#self.Items do
    self.Items[i]:SetPosition(x, self.ItemDistance*(i-1))
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






