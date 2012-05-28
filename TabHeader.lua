//
//   Created by:   fsfod
//


ControlClass("TabHeader", BorderedSquare)

TabHeader:SetDefaultOptions{
  DividerWidth = 2,
  DefaultTabWidth = 20,
  Height = 20,
  DraggableTabs = true,
}

function TabHeader:InitFromTable(options)
  self.Height = options.Height  
  BorderedSquare.Initialize(self, options.Width, self.Height, 1)

  self:SetBackgroundColor(self.BackgroundColor)

  self.FontSize = options.FontSize or self.Height-2

  self.Tabs = {}
  
  local offset = 0
  
  for i,info in ipairs(options.TabList) do
    local tab = self:CreateTab(info)
    tab:SetPosition(offset, 0)

    offset = offset+tab:GetWidth()+self.DividerWidth
  end
end

function TabHeader:GetColumnOffsets()
  
  local offsets = {}

  for i,tab in ipairs(self.Tabs) do
    offsets[tab.NameTag or i] = tab:GetLeft()
  end
  
  return offsets
end

function TabHeader:CreateTab(tabInfo)
  
  local index = #self.Tabs+1
  
  local tab = self:CreateControl("TabHeaderButton", self, index, tabInfo.Label or "somelabel", tabInfo.Width or self.DefaultTabWidth)
  self:AddChild(tab)
  
  tab.Clicked = tabInfo.Clicked
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
  
  for i,tab in ipairs(self.Tabs) do
    tab:SetPosition(offset, 0)
    tab.TabIndex = i
    
    offset = offset+tab:GetWidth()+self.DividerWidth
  end
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