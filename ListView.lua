//
//   Created by:   fsfod
//

ControlClass('LVTextItem', BaseControl)

local white = Color(1, 1, 1, 1)
local black = Color(0, 0, 0, 1)
LVTextItem.TextOffset = 4
LVTextItem.FontSize = 17

function LVTextItem:Initialize(owner, width, height, fontsize)

  BaseControl.Initialize(self)

  //we have set this here since we were not created by GUIManager function and Text GUIItems need it set
  self:SetOptionFlag(GUIItem.ManageRender)

  self.FontSize = fontsize

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

//defaults
ListView:SetDefaultOptions{
  Height = 120,
  Width = 300,
  ItemHeight = 16,
  ItemSpacing = 1,
  ItemClass = "LVTextItem",
  SelectedItemColor = Color(0, 0, 0.3, 1),
  ScrollBarWidth = 20,
  ItemsSelectable = true,
  AutoScroll = false,
  ScrollHiddenUntilNeeded = true,
  TreatItemSpacingAsHit = false,
  DelayCreateItems = false,
}

function ListView:Rescale()
  BaseControl.Rescale(self)

  self.ItemsAnchor:Rescale()
end

function ListView:InitFromTable(options)  
  ListView.Initialize(self, options)
  
  self.ItemSelected = ResolveToEventReceiver(options.ItemSelected, self)
  self.ItemDblClicked = ResolveToEventReceiver(options.ItemDblClicked, self)
end

function ListView:Initialize(options)

  assert(type(options) == "table", "ListView:Initialize expected a table as the first arg")
 
  //if a option value is nil our indexer will read the default from our static table
  self.ItemSpacing = options.ItemSpacing
  self.ItemHeight = options.ItemHeight
  self.ItemDistance = self.ItemHeight + self.ItemSpacing

  self.FontSize = options.FontSize or self.ItemHeight

  if(options.MaxVisibleItems) then
    assert(not options.Height, "can't specify both the height and MaxVisibleItems for a listview")
    self.Height = (options.MaxVisibleItems*self.ItemDistance)+1
  else
    self.Height = options.Height
  end

  self.Width = options.Width

  self.TraverseChildFirst = true

  BaseControl.Initialize(self, self.Width, self.Height)
  
  self:SetColor(Color(0.5,0.5,0.5,0.5))

  local selectBG = self:CreateGUIItem()
    selectBG:SetIsVisible(false)
    selectBG:SetColor(options.SelectedItemColor or self.SelectedItemColor)
  self.SelectBG = selectBG

  self:CreateItemsAnchor()

  assert(not options.ItemCreator or type(options.ItemCreator) == "string")
  //TODO decide how we treat a ItemCreator entry and ItemClass entry diffently
  self.ItemClass = options.ItemCreator or options.ItemClass or self.ItemClass
  
  self.ScrollBarWidth = options.ScrollBarWidth
  self.ScrollHiddenUntilNeeded = options.ScrollHiddenUntilNeeded
  self.AutoScroll = options.AutoScroll
  
  self.ItemsSelectable = options.ItemsSelectable
  self.TreatItemSpacingAsHit = options.TreatItemSpacingAsHit
    
  
  local scrollbar = self:CreateControl("ScrollBar")
   scrollbar:SetPoint("TopRight", 0, 0, "TopRight")
   scrollbar.ValueChanged = {self.OnScrollChanged, self}
   scrollbar:SetStepSize(1)
   scrollbar:DisableScrolling()
   scrollbar:Hide()
  self.ScrollBar = scrollbar
  self:AddChild(scrollbar)

  self.Items = {}
  
  self:SetSize(self.Width, self.Height)


  if(not options.DelayCreateItems) then
    self:CreateItems()
    self.ItemsCreated = true
  else
    self.ItemsCreated = false
  end
  
  self.AnchorPosition = Vector(0,0,0)

  if(options.ItemDataList) then
    self:SetDataList(ResolveToTable(options.ItemDataList))
  else
    self.ItemDataList = {}
  end  
end

function ListView:Uninitialize()
  BaseControl.Uninitialize(self)
end

function ListView:CreateItemsAnchor()

  assert(not self.ItemsAnchor)

  local anchor = self:CreateControl("BaseControl")
    anchor:SetColor(Color(0,0,0,0))
    anchor.Size = Vector(0, 0, 0)
    anchor:SetPosition(0, 0, 0)
    self:AddGUIItemChild(anchor)
  self.ItemsAnchor = anchor
end

function ListView:EnableStencilDrawClipper()

  if(self.BackgroundStencil) then
    return
  end

  local backgroundStencil = self:CreateGUIItem()
    backgroundStencil:SetIsStencil(true)
    backgroundStencil:SetInheritsParentStencilSettings(false)
    backgroundStencil:SetClearsStencilBuffer(true)
    backgroundStencil:SetSize(self.Size)
   self:AddGUIItemChild(self.backgroundStencil)
  self.BackgroundStencil = backgroundStencil

  if(true) then
    self:RemoveGUIItemChild(self.ItemsAnchor)
    backgroundStencil:AddGUIItemChild(self.ItemsAnchor)
  end
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
    //reset to the start the view to the start of the list if list size is less than MaxVisibleItems
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
   
  if(not self.ItemsCreated) then
    return
  end
   
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
  
  if(self.BackgroundStencil) then
    self.BackgroundStencil:SetSize(self.Size)
  end
  
  self.ItemWidth = width-15

  self:OnMaxVisibleChanged(math.floor(height/self.ItemDistance))
  
  if(self.ItemsCreated) then

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
  
  local yOffset = (y%self.ItemDistance)
  
  if(yOffset > self.ItemHeight and not self.TreatItemSpacingAsHit) then
    return nil
  end
  
  local index = ((y-yOffset)/self.ItemDistance)+1

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
  
  if(not self.ItemsCreated) then
    self:CreateItems()
    self.ItemsCreated = true
  end
  
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

function ListView:ChangeItemClass(itemClassName)
  
  self:RemoveGUIItemChild(self.ItemsAnchor)
  self.ItemsAnchor:Uninitialize()
  self.ItemsAnchor = nil

  self:CreateItemsAnchor()
 
  self.Items = {}

  self.ItemClass = itemClassName

  self:CreateItems()
  
  self:ListDataModifed()
end

function ListView:SetFontSize(size)
  self.FontSize = size
  
  
end

function ListView:SetItemLayout(positionsList)
  
  self.ItemLayout = positionsList
  
  if(not self.Items) then
    return
  end
  
  for i,item in ipairs(self.Items) do
    
    if(item.UpdateLayout) then
      item:UpdateLayout(positionsList)
    else
      
      for name,position in pairs(positionsList) do
      
        local control = item[name]
      
        if(control) then
          control:SetPosition(position)
        end
      end
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
    local item = self.ItemsAnchor:CreateControl(self.ItemClass, self, width, height, self.FontSize, self.ItemLayout)

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



