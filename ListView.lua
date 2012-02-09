//
//   Created by:   fsfod
//

ControlClass('LVTextItem', BaseControl)

local white = Color(1, 1, 1, 1)
local black = Color(0, 0, 0, 1)
LVTextItem.TextOffset = 4
LVTextItem.FontSize = 17

function LVTextItem:Initialize(owner, width, fontsize)

  BaseControl.Initialize(self)

  //we have set this here since we were not created by GUIManager function and Text GUIItems need it set
  self:SetOptionFlag(GUIItem.ManageRender)

  self:SetFontSize(self.FontSize*UIScale)
  self:SetTextClipped(true, width-self.TextOffset, self.FontSize)
  
  self:SetColor(white)
end

function LVTextItem:SetData(msg)
  self:Show()
  self:SetText(msg)
end

function LVTextItem:SetWidth(width)
  self:SetTextClipped(true, width-self.TextOffset, self.FontSize)
end

function LVTextItem:SetPosition(x, y)
  BaseControl.SetPosition(self, x+self.TextOffset, y)
end

function LVTextItem:Rescale()
  self:SetFontSize(self.FontSize*UIFontScale)
  GUIItem.SetPosition(self, self.Position*UIScale)
end

function LVTextItem:GetRoot()
  return self
end


ControlClass('ListView', BaseControl)

ListView.DefaultHeight = 120
ListView.DefaultWidth = 300
ListView.SelectedItemColor = Color(0, 0, 0.3, 1)


function ListView:Rescale()
  BaseControl.Rescale(self)

  self.ItemsAnchor:Rescale()
end

function ListView:Initialize(width, height, itemCreator, itemHeight, itemSpacing)
  
  height = height or ListView.DefaultHeight
  width = width or ListView.DefaultWidth
  
  self.ItemSpacing = itemSpacing or self.ItemSpacing or 1
  self.ItemHeight = itemHeight or self.ItemHeight or 16  
  self.ItemDistance = self.ItemHeight + self.ItemSpacing
  self.ScrollBarWidth = 20
  
  self.TraverseChildFirst = true
  
  if(self.ItemsSelectable == nil) then
    self.ItemsSelectable = true
  end
  
  BaseControl.Initialize(self, width, height)
  
  self:SetColor(Color(0.5,0.5,0.5,0.5))

  local selectBG = self:CreateGUIItem()
    selectBG:SetIsVisible(false)
    selectBG:SetColor(self.SelectedItemColor)
  self.SelectBG = selectBG

  self.ItemsAnchor = self:CreateControl("BaseControl")
  self.ItemsAnchor:SetColor(Color(0,0,0,0))
  self.ItemsAnchor.Size = Vector(0, 0, 0)
  self.ItemsAnchor:SetPosition(0, 0, 0)
  self:AddGUIItemChild(self.ItemsAnchor)

  assert(not itemCreator or type(itemCreator) == "string")
  self.ItemClass = itemCreator or self.ItemClass or "LVTextItem"
  
  local scrollbar = self:CreateControl("ScrollBar")
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

  self.ItemDataList = {}
end

function ListView:Uninitialize()
  BaseControl.Uninitialize(self)
end

function ListView:SetScrollBarWidth(width)
  
  self.ScrollBarWidth = width
  self.ScrollBar:SetSize(width, self:GetHeight())
end

function ListView:ClampViewStart()
  
  local oldValue = self.ViewStart 
  
  if(not self.ItemDataList or #self.ItemDataList == 0 or self.ViewStart <= 0) then
    self.ViewStart = 1
   return oldValue ~= self.ViewStart
  end
  
  local extra = #self.ItemDataList-self.MaxVisibleItems
  
  if(extra < 0) then
    self.ViewStart = 1
  elseif(self.ViewStart > extra+1) then
    self.ViewStart = extra+1
    self.ScrollBar:SetValue(self.ViewStart)
  end
  
  return oldValue ~= self.ViewStart
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
        self.Items[i]:Hide()
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
  
  local itemsCreated = self.Items and #self.Items > 1
  
  self:OnMaxVisibleChanged(math.floor(height/self.ItemDistance))
  
  if(itemsCreated) then

    for i=1,self.MaxVisibleItems do
      self.Items[i]:SetWidth(self.ItemWidth)
    end
  end
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
  
  local yOffset = (y%ItemDistance)
  
  if(yOffset > self.ItemHeight and self.IgnoreItemSpacingHitRec) then
    return nil
  end
  
  local index = ((y-yOffset)/ItemDistance)+1

  if(index <= #self.Items and index <= #self.ItemDataList and index <= self.MaxVisibleItems) then
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

function ListView:TraverseGetFrame(x, y, filter)
  local index = self:GetItemAtCoords(x,y)

  if(index) then
    local item = self.Items[index]
    local hitrec = item.HitRec

    if(not item.Hidden and hitrec and (bit.band(item.ChildFlags or 0, filter) ~= 0 or bit.band(item.Flags or 0, filter) ~= 0)) then
      return item, x-hitrec[1],y-hitrec[2]
    end
  end
 
  return nil
end
/*
function ListView:OnEnter(x,y)

  local index = self:GetItemAtCoords(x,y)

  if(index) then
    local item = self.Items[index]

    if(not item.Hidden and (item.OnEnter or item.ChildControls)) then
      local hitrec = item.HitRec

      --let the GUIManager handle this
      return item, x-hitrec[1],y-hitrec[2]
    end
  end
end
*/

function ListView:OnMouseWheel(direction)
  self:SetListToIndex(self.ViewStart+(-direction))
end

function ListView:OnClick(button, down, x,y)

  if(not down) then
    if(self.ClickedItem) then
      self.ClickedItem:OnClick(button, false)
      self.ClickedItem = nil
    end
    
    return
  end
  
----start of item hit dection and selection code-------
  local index = self:GetItemAtCoords(x,y)
  
  if(index) then
    local item = self.Items[index]
    local DataIndex = self.ViewStart+index-1

    if(self.ItemsSelectable) then
      self:OnItemSelected(index)
    end

    if(not item.OnClick) then
      if(self.ItemDblClicked and self.LastClickTime and self.LastClickedIndex == DataIndex and 
        (Client.GetTime()-self.LastClickTime) < self:GetGUIManager().DblClickSpeed) then

        self:FireEvent(self.ItemDblClicked, self.ItemDataList[DataIndex], DataIndex)
      end
    
      self.LastClickedIndex = DataIndex
      self.LastClickTime = Client.GetTime()
    end
    
   // return item.isa and item:isa("BaseControl") and item)
   return true
  end
  
  return false
end

function ListView:ResetSelection()
  self.SelectedItem = nil
  self.ClickedItem = nil
  
  self.SelectBG:SetIsVisible(false)
end

function ListView:SetSelectedItem(item)

  for i,itemEntry in ipairs(self.Items) do
   
    if(itemEntry == item) then
      self:SetSelectedIndex(self.ViewStart+(i-1))
     return true
    end
  end

  return false
end

function ListView:SetSelectedListEntry(item)

  for i,itemEntry in ipairs(self.ItemDataList) do
   
    if(itemEntry == item) then
      self:SetSelectedIndex(i)
     return true
    end
  end

  return false
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
  assert(list)
  
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
    local item = self.Items[i]
    
    if(i <= TotalCount) then
      item:SetData(self.ItemDataList[i+self.ViewStart-1], SelectedIndex == i)
    else
      item:Hide()
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

  self.ViewStart = index
  self:ClampViewStart()

  if(not fromScrollBar) then
    self.ScrollBar:SetValue(self.ViewStart)
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
    local item = self.ItemsAnchor:CreateControl(self.ItemClass, self, width, height)

    //self.CreateItem(self, width, height)

     self.ItemsAnchor:AddChild(item)
     item:SetPosition(x, (height+self.ItemSpacing)*(i-1))

     if(item.UpdateHitRec) then
       item.Parent = self
       item:TryUpdateHitRec()
     end

    self.Items[i] = item
  end

  if(self.SetItemWidths) then
    
  end
end

function ListView:ResetPositions()
  local x = 0

  for i=1,#self.Items do
    self.Items[i]:SetPosition(x, self.ItemDistance*(i-1))
  end
end



