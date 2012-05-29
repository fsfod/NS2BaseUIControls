//
//   Created by:   fsfod
//


ControlClass("TabHeader", BorderedSquare)

TabHeader:SetDefaultOptions{
  ResizerWidth = 16,
  TabSpacing = 2,
  MinTabWidth = 50,
  DefaultTabWidth = 80,
  Height = 20,
  DraggableTabs = true,
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
  BorderedSquare.Initialize(self, options.Width, self.Height, 1)

  self:SetBackgroundColor(self.BackgroundColor)

  self.FontSize = options.FontSize or self.Height-2

  self.TabPressed = ResolveToEventReceiver(options.TabPressed, self)
  self.TabsSwapped = ResolveToEventReceiver(options.TabsSwapped, self)
  self.TabResized = ResolveToEventReceiver(options.TabResized, self)

  self.Tabs = {}
  self.Dividers = {}
  
  local offset = 0
  
  for i,info in ipairs(options.TabList) do
    self:CreateTab(info)
  end
  
  self:CreateDividers(#options.TabList)
  
  self:UpdateTabPositions()
end

function TabHeader:CreateDividers(count)

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

function TabHeader:GetColumnWidths(widths)
  
  widths = widths or {}

  for i,tab in ipairs(self.Tabs) do
    widths[tab.NameTag or i] = tab:GetWidth()
  end
  
  return widths
end

function TabHeader:GetColumnOffsets(offsets)
  
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
    
  if(index < #Tabs) then
    Tabs[index+1]:SetWidth(resizer.RightWidth-offset)
  end

  self:UpdateTabPositions()
  
  self:FireEvent(self.TabResized, Tabs[index], index)
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


  if(self.RightTab) then
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
  
  self:SetColor(color or ControlGrey2)
  
  if(parent.DraggableTabs) then
    self:SetDraggable()
  end
  
  self.StartPosition = 0
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
  self:SetColor(ControlGrey2)
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

function TabHeaderButton:OnClick(button, down)

  if(down and button == InputKey.MouseButton0) then
    PlayerUI_PlayButtonClickSound()
    self.Parent:OnTabPressed(self)
  end
end