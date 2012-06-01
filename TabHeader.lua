//
//   Created by:   fsfod
//


ControlClass("TabHeader", BorderedSquare)

TabHeader:SetDefaultOptions{
  ResizerWidth = 12,
  TabSpacing = 2,
  MinTabWidth = 50,
  DefaultTabWidth = 80,
  ExpandTabsToFit = false,
  Height = 20,
  DraggableTabs = true,
  ResizableTabs = true,
  Mode = "ListHeader",
  TabColor = ControlGrey2,
  ActiveTabColor = ControlGrey2,
  NonActiveTabColor = Color(ControlGrey2.r*0.3, ControlGrey2.g*0.3, ControlGrey2.b*0.3, 1)
}

TabHeader.TabOptionFields = {
  Clicked = EventOption,
  Ascending = false,
  MinWidth = OptionalValue,
  Label = OptionalValue,
  Width = OptionalValue,
}

function TabHeader:InitFromTable(options)
  self.Height = options.Height  
  self.Width = options.Width
  BorderedSquare.Initialize(self, options.Width, self.Height, 1)

  self:SetBackgroundColor(self.BackgroundColor)

  self.FontSize = options.FontSize or self.Height-2

  self.TabPressed = ResolveToEventReceiver(options.TabPressed, self)
  self.TabsSwapped = ResolveToEventReceiver(options.TabsSwapped, self)
  
  self.TabResized = ResolveToEventReceiver(options.TabResized, self)

  self.Tabs = {}
  self.Dividers = {}
  
  local offset = 0

  self.Mode = options.Mode
  
  self.TabColor = options.TabColor
  
  if(self.Mode == "Tab") then
    if(not options.TabColor) then
      self.TabColor = self.NonActiveTabColor
    end
    
    self.ResizableTabs = false
    self.DraggableTabs = false
  end
  
  if(options.ResizableTabs ~= nil) then
    self.ResizableTabs = options.ResizableTabs
  end
  
  //allow the auto value of DraggableTabs tobe overidden by the options table
  if(options.DraggableTabs ~= nil) then
    self.DraggableTabs = options.DraggableTabs
  end
  
  self.TabSpacing = options.TabSpacing
  self.ExpandTabsToFit = options.ExpandTabsToFit
  
  if(self.ExpandTabsToFit) then
    assert(not options.DefaultTabWidth)
    self.DefaultTabWidth = ((self.Width+self.TabSpacing)/#options.TabList)-self.TabSpacing
  end

  for i,info in ipairs(options.TabList) do
    self:CreateTab(info)
  end
  
  if(self.Mode == "Tab" and #self.Tabs ~= 0) then
    self:SetActiveTab(options.ActiveTab or 1)
  end

  if(options.GetSavedLayout) then
    local order, widths = ResolveAndCallFunction(options.GetSavedLayout, self)
   
    if(order and next(order)) then
      self:RestoreTabOrder(order, true)
    else
      order = nil
    end
    
    if(widths and next(widths)) then
      self:RestoreTabWidths(widths, order, true)
    end
  end
 
  //have tobe created after the tabs since the hit detection  systeme searchs a controls ChildControls list in reverse
  if(self.ResizableTabs) then
    self:CreateDividers(#options.TabList)
  end
  
  //allow the auto value of DraggableTabs tobe overidden by the options table
  if(options.DraggableTabs ~= nil) then
    self.DraggableTabs = options.DraggableTabs
  end
  
  self:UpdateTabPositions()
end

function TabHeader:RestoreTabWidths(widths, nameToIndex, supressLayout)
  
  nameToIndex = nameToIndex or self:GetTabOrder()
  
  for name,index in pairs(nameToIndex) do
    
    local width = widths[name]
    local tab = self.Tabs[index]
    
    if(tab and width and width > 0) then
      tab:SetWidth(width)
    end
  end

  if(not supressLayout) then
    self:UpdateTabPositions()
  end
end

function TabHeader:RestoreTabOrder(order, supressLayout)

  local newList = {}
  
  local count = #self.Tabs
  
  for i=1,count do
    newList[i] = false
  end
  
  for i,tab in ipairs(self.Tabs) do
   
    local index = order[tab.NameTag]
   
    if(index) then
      assert(newList[index] == false)
      
      newList[index] = tab
      count = count-1
    end
  end
  
  assert(count == 0)
  
  self.Tabs = newList
  
  if(not supressLayout) then
    self:UpdateTabPositions()
  end
end

function TabHeader:CreateDividers(count)

  count = count or #self.Tabs

  if(#self.Dividers > count) then
    //TODO clear up the extras
    return
  end

  for index=#self.Dividers+1,count do
    
    local divider = self:CreateControl("TabDivider", self, index)
    
    self.Dividers[index] = divider
    self:AddChild(divider)
  end
end

function TabHeader:DestroyDividers()
  
  for i,divider in ipairs(self.Dividers) do
    self:DestoryChild(divider)
  end
  
  self.Dividers = {}
end

function TabHeader:SetResizableTabs(enable)
  
  if(enable) then
    if(self.Dividers and #self.Dividers ~= 0) then
      return
    end

    self:CreateDividers()
    self:UpdateTabPositions()
  else
    if(not self.Dividers) then
      return
    end
    
    self:DestroyDividers()
  end
  
  self.ResizableTabs = enable
end

function TabHeader:SetDraggableTabs(enable)
  
  self.DraggableTabs = enable
  
  for i,tab in ipairs(self.Tabs) do
    tab.DragEnabled = enable
  end
end

function TabHeader:CreateTab(tabInfo)
  
  local index = #self.Tabs+1
  
  local width =  tabInfo.Width or self.DefaultTabWidth
  
  local tab = self:CreateControl("TabHeaderButton", self, index, tabInfo.Label or "somelabel", width)
  self:AddChild(tab)
  
  for k,v in pairs(self.TabOptionFields) do
    tab[k] = tabInfo[k]
  end

  if(width < self.MinTabWidth and not tabInfo.MinWidth) then
    tab.MinWidth = width
  end

  tab.NameTag = tabInfo.NameTag or tabInfo.Label
  
  self.Tabs[index] = tab  
  
  return tab
end

function TabHeader:RemoveTab(tab)
  table.removevalue(self.Tabs, tab)
  self:UpdateTabPositions()
end

function TabHeader:UpdateTabPositions()
  
  local offset = 0
  local dividerCenter = self.ResizerWidth/2
  
  local dividers = self.Dividers
  
  for i,tab in ipairs(self.Tabs) do
    tab:SetPosition(offset, 0)
    tab.TabIndex = i
    
    local baseOffset = offset+tab:GetWidth()
    
    if(dividers[i]) then
      dividers[i]:SetPosition(baseOffset-dividerCenter, 0)
    end
    
    offset = baseOffset+self.TabSpacing
  end
end

function TabHeader:GetTabWidth(index)
  
  local tab = self.Tabs[index]
  assert(tab)
  
  return tab:GetWidth()
end

function TabHeader:GetTabWidths(widths)
  
  widths = widths or {}

  for i,tab in ipairs(self.Tabs) do
    widths[tab.NameTag or i] = tab:GetWidth()
  end
  
  return widths
end

function TabHeader:GetTabOrder(order)

  order = order or {}
  
  for i,tab in ipairs(self.Tabs) do
    order[tab.NameTag or i] = tab.TabIndex
  end
  
  return order
end

function TabHeader:GetTabOffsets(offsets)
  
  offsets = offsets or {}

  for i,tab in ipairs(self.Tabs) do
    offsets[tab.NameTag or i] = tab:GetLeft()
  end
  
  return offsets
end

function TabHeader:GetTabCount()
  return #self.Tabs
end

function TabHeader:OnTabPressed(tab)

  if(self.Mode == "Tab") then
    self:SetActiveTab(tab)
    
    if(self.ActiveTab) then
      self.ActiveTab:ClearActiveState()
    end
    
    self.ActiveTab = tab 
    tab:SetActiveState()
  end

  if(tab.Clicked) then
    tab:FireEvent(tab.Clicked, tab)
  end
  
  self:FireEvent(self.TabPressed, tab)
end

function TabHeader:CheckTabSwap(tab, offset, isForwardDrag)
  
  local pastTab, newindex
  
  if(isForwardDrag) then
    if(tab.TabIndex == #self.Tabs) then
      return false
    end
    
    local offset = tab:GetRight()
  
    for i=tab.TabIndex+1,#self.Tabs,1 do
      local tabI = self.Tabs[i] 
      
      if(offset >= tabI:GetRight()) then
        pastTab = tabI
      end
    end
    
  else
    if(tab.TabIndex == 1) then
      return false
    end
    
    local offset = tab:GetLeft()
  
    for i=tab.TabIndex-1,1,-1 do
      local tabI = self.Tabs[i] 
      
      if(offset <= tabI:GetLeft()) then
        pastTab = tabI
      end
    end
  end
  
  if(not pastTab) then
    return false
  end


  table.remove(self.Tabs, tab.TabIndex)

  //effectivly this index is really pastTab.TabIndex+1 if the tab was dragged forward because when we remove the dragged tab from the table the indexs are shifted back 1
  table.insert(self.Tabs, pastTab.TabIndex, tab)

  self:UpdateTabPositions()
  
  self:FireEvent(self.TabsSwapped)
  
  return true
end

function TabHeader:SetDragButton(button)
  
end

function TabHeader:ResizerMoved(resizer, offset)
  local Tabs = self.Tabs
  local index = resizer.TabIndex
    
  Tabs[index]:SetWidth(resizer.LeftWidth+offset)
    
  if(index < #Tabs and self.ShiftTabs) then
    Tabs[index+1]:SetWidth(resizer.RightWidth-offset)
  end

  self:UpdateTabPositions()
  
  self:FireEvent(self.TabResized, Tabs[index], index)
end

function TabHeader:ResolveToTab(nameOrIndex)
  
  local argType = type(nameOrIndex) 
  
  if(argType == "userdata") then
     assert(nameOrIndex.TabIndex)
    return nameOrIndex
  elseif(argType == "string") then
  
    for i,tab in ipairs(self.Tabs) do
      if(tab.NameTag == nameOrIndex) then
        return tab
      end
    end
    
    error("there was no tab with the NameTag "..nameOrIndex)
  elseif(argType == "number") then
  
    assert(nameOrIndex > 0 and nameOrIndex <= #self.Tabs)
    
    return self.Tabs[nameOrIndex]
  else
    error("Tab identifter was not a index or a tagname")
  end
  
end

function TabHeader:SetTabSortDirection(tabKey, ascending)
  
  local tab = self:ResolveToTab(tabKey)
  
  tab:SetSortDirection(ascending)
end

function TabHeader:ClearSortDirection()
  for i,tab in ipairs(self.Tabs) do
    tab:ClearSortDirection()
  end
end

function TabHeader:SetActiveTab(tab)

  tab = self:ResolveToTab(tab)

  if(self.ActiveTab) then
    self.ActiveTab:ClearActiveState()
  end

  self.ActiveTab = tab 
  tab:SetActiveState()
end


ControlClass("TabDivider", BaseControl)

function TabDivider:Initialize(parent, tabIndex)
  BaseControl.Initialize(self, parent.ResizerWidth, parent.Height)
  
  self:SetColor(Color(0,0,0,0))
  
  self:SetLayer(1)
  
  self.TabIndex = tabIndex
  self:SetDraggable()
  
  self:SetupHitRec()
end

function TabDivider:OnDragStart()
  
  self.DragStartOffset = self:GetPosition().x
 
  self.StartPosition = self.Position.x
  
  self.LeftWidth = self.Parent:GetTabWidth(self.TabIndex)
  self.LeftTab = self.Parent.Tabs[self.TabIndex]
  
  if(self.TabIndex < self.Parent:GetTabCount() ) then
    self.RightTab = self.Parent.Tabs[self.TabIndex+1]
    self.RightWidth = self.RightTab:GetWidth()
  end
end

function TabDivider:OnDragMove(pos)

  local min = (-self.LeftWidth)+(self.LeftTab.MinWidth or self.Parent.MinTabWidth)
  
  local max = 0


  if(self.RightTab and self.Parent.ShiftTabs) then
    max = self.RightWidth-(self.RightTab.MinWidth or self.Parent.MinTabWidth)
  else
    max = self.Parent:GetWidth()-(self.StartPosition+(self.Parent.ResizerWidth/2))
  end

  local offset = Clamp(pos.x, min, max)

  if(offset ~= self.CurrentPosition) then
    self.CurrentPosition = offset
    
    self:SetPosition(self.StartPosition+offset, 0, true)
   
    self.Parent:ResizerMoved(self, offset)
  end
end

function TabDivider:OnDragStop()
  
  //self:SetPosition(self.StartPosition, 0,  true)
end


function TabDivider:OnEnter()
  self:GetGUIManager():SetCursor(self, "ui/resize.png", 64, 32)
end

function TabDivider:OnLeave()
  self:GetGUIManager():SetCursor(self, "ui/Cursor_MenuDefault.dds", 0,0)
end


ControlClass("TabHeaderButton", BaseControl)

TabHeaderButton.LabelOffset = Vector(2, 0, 0)

function TabHeaderButton:Initialize(parent, tabIndex, labelString, width, color)
  BaseControl.Initialize(self, width, parent.Height)

  local label = self:CreateFontString(parent.FontSize)
    label:SetPosition(self.LabelOffset)
    label:SetTextAlignmentX(GUIItem.Align_Min)
    label:SetTextAlignmentY(GUIItem.Align_Min)
  label:SetText(labelString)
  
  self.Label = label
  
  self.TabIndex = tabIndex
  self.Active = false
  
  self:SetLayer(0)
  
  self.Color = color 
  
  self:SetColor(color or parent.TabColor)

  self:SetDraggable()
  self.DragEnabled = parent.DraggableTabs
  
  self.StartPosition = 0
  
  //self:SetAscending()
end

function TabHeaderButton:ClearSortDirection()
  if(self.SortDirection) then
    self.SortDirection:Hide()
  end
end

function TabHeaderButton:SetSortDirection(ascending)

  if(not self.SortDirection) then
    
    local size = self:GetHeight()*0.5
    
    local sortDirection = self:CreateControl("BaseControl", size, size)
      sortDirection:SetPoint("Right", -2, 0)
      sortDirection:SetTexture("ui/ButtonArrows.dds")
      self:AddChild(sortDirection)
    self.SortDirection = sortDirection
  end
  
  self.Ascending = ascending
  
  self.Parent:ClearSortDirection()
  
  self.SortDirection:Show()
  
  local direction = (ascending and "Down") or "Up"
  
  self.SortDirection:SetTexturePixelCoordinates(unpack(ArrowButton.ArrowTextures[direction]))
end

function TabHeaderButton:SetPosition(x, y, DragSetPosiiton)
  BaseControl.SetPosition(self, x, y)

  if(not DragSetPosiiton) then
    self.StartPosition = self.Position.x
  end
end

function TabHeaderButton:OnEnter()
  self:SetColor(ControlHighlightColor)
end

function TabHeaderButton:OnLeave()

  local color
  
  if(self.Active) then
    color = self.Parent.ActiveTabColor
  else
    color = self.Color or self.Parent.TabColor
  end
  
  self:SetColor(color)
end

function TabHeaderButton:OnDragStart()
  self.DragStartOffset = self:GetPosition().x
 
  self.CurrentPosition = nil
 
  self.StartPosition = self.Position.x
  
  self:SetLayer(1)
end

function TabHeaderButton:OnDragMove(pos)

  local offset = Clamp(self.DragStartOffset+pos.x, 0, self.Parent:GetWidth()-self:GetWidth())

  if(offset ~= self.CurrentPosition) then
    self.CurrentPosition = offset
    
    self:SetPosition(offset, 0, true)
  end
end

function TabHeaderButton:OnDragStop()

  self:SetLayer(0)

  if(not self.CurrentPosition or not self.Parent:CheckTabSwap(self, self.CurrentPosition, self.CurrentPosition > self.StartPosition)) then
    self:SetPosition(self.StartPosition, 0,  true)
  end
end

function TabHeaderButton:SetActiveState()
  
  self.Active = true
  
  if(not self.Entered) then
    self:SetColor(self.Parent.ActiveTabColor)
  end
end

function TabHeaderButton:ClearActiveState()

  self.Active = false
  
  if(not self.Entered) then
    self:SetColor(self.Color or self.Parent.TabColor)
  end
end

function TabHeaderButton:OnClick(button, down)

  if(down and button == InputKey.MouseButton0) then
    PlayerUI_PlayButtonClickSound()
    self.Parent:OnTabPressed(self)
  end
end