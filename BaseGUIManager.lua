
if(not BaseGUIManager) then
  
BaseGUIManager = {
  DblClickSpeed = 0.5,
}
end


local band = bit.band
local bor = bit.bor

function BaseGUIManager:Initialize()
  Event.Hook("UpdateClient", function() self:Update() end)

  Event.Hook("ResolutionChanged", function(...) self:OnResolutionChanged(...) end)

  self.Callbacks = CallbackHandler:New(self)
  
  self.ClickedFrames = {}
  
  self:ClearFrameLists()

  self.ClickFlags = bor(bor(ControlFlags.OnClick, ControlFlags.Draggable), ControlFlags.IsWindow)
end

function BaseGUIManager:ClearFrameLists()
  self.WindowList = {}
  self.NonWindowList = {}
  
  self.AllFrames = {}
end

function BaseGUIManager:RecreateAnchorAndUpdateFrames(width, height, layer, ...)

  local oldAnchor = self.AnchorFrame

  self:CreateAnchorFrame(width, height, layer)

  local anchorFrame = self.AnchorFrame

  for _,frame in ipairs(self.AllFrames) do
    oldAnchor:RemoveChild(frame.RootFrame)
    anchorFrame:AddChild(frame.RootFrame)
  end
  
  --handle any extra frames the caller has passed
  for _,frame in ipairs({...}) do
    if(frame) then
      oldAnchor:RemoveChild(frame.RootFrame)
      anchorFrame:AddChild(frame.RootFrame)
    end
  end
  
  GUI.DestroyItem(oldAnchor)
end

function BaseGUIManager:DestroyAllFrames()

  self:ClearStateData()

  for _,frame in ipairs(self.AllFrames) do
    if(frame.Uninitialize) then
      SafeCall(frame.Uninitialize, frame)
    end
  end

  --failsafe incase any frames errored during there Uninitialize
  if(self.AnchorFrame) then
    GUI.DestroyItem(self.AnchorFrame)

    self.AnchorFrame = nil
  end

  self:ClearFrameLists()
end

function BaseGUIManager:CreateAnchorFrame(width, height, layer)
  self.AnchorSize = Vector(width, height, 0)

  local anchorFrame = GUI.CreateItem()
    anchorFrame:SetColor(Color(0, 0, 0, 0))
    anchorFrame:SetSize(self.AnchorSize)
    anchorFrame:SetLayer(layer or 0)

  self.AnchorFrame = anchorFrame

  if(self.TopLevelUIParent) then
    self.TopLevelUIParent.RootFrame = anchorFrame
    self.TopLevelUIParent.Size = self.AnchorSize
  end
end

function BaseGUIManager:OnResolutionChanged(oldX, oldY, width, height)

  if(self.AnchorSize) then
    self.AnchorSize.x = width
    self.AnchorSize.y = height
  end

  if(self.AnchorFrame) then
    self.AnchorFrame:SetSize(self.AnchorSize)
  end
  
  for _,frame in pairs(self.AllFrames) do
    frame:UpdatePosition()
    frame:OnResolutionChanged(oldX, oldY, width, height)
  end
end

function BaseGUIManager:SendKeyEvent(key, down, IsRepeat, wheelDirection)

  if(not self:IsActive()) then
    return false
  end

  if(key == InputKey.MouseX or key == InputKey.MouseY) then    
    
    if(not self.DoneMouseMove) then
      self:OnMouseMove()
      self.DoneMouseMove = true
    end

   return false
  end

  if(key == InputKey.MouseButton0 or key == InputKey.MouseButton1 or key == InputKey.MouseButton3) then
    return self:MouseClick(key, down)
  end

  local focus = self.FocusedFrame

  if(focus and focus.SendKeyEvent and focus:SendKeyEvent(key, down, IsRepeat)) then
    return true
  end

  if(wheelDirection and self:OnMouseWheel(wheelDirection)) then
    return true
  end

  for _,frame in ipairs(self.AllFrames) do
    if(frame:SendKeyEvent(key, down, IsRepeat)) then
      return true
    end
  end

  return false
end

function BaseGUIManager:SendCharacterEvent(...)

  if(not self:IsActive()) then
    return false
  end

  local focus = self.FocusedFrame

  if(focus and focus.SendCharacterEvent) then
    return focus:SendCharacterEvent(...)
  end

  return false
end

function BaseGUIManager:IsActive()
  return self.Active == true
end

function BaseGUIManager:Activate()
  self.Active = true
end

function BaseGUIManager:Deactivate()
  self.Active = false

  self:ClearStateData()
end

function BaseGUIManager:ClearStateData()
  
  self:ClearMouseOver()

  self:SendMouseUps()

	self:ClearFocus()

  self:CancelDrag()
  
  self.DoneMouseMove = false
end

function BaseGUIManager:Update(force)
  
  if(not force and not self:IsActive()) then
    return
  end

  if(self.FocusedFrame and not self.FocusedFrame:IsShown()) then
    self:ClearFocus()
  end

  self.DoneMouseMove = false
  
  self:UpdateFrames()
end

function BaseGUIManager:UpdateFrames()

  for _,frame in ipairs(self.AllFrames) do
    frame:Update()
  end
end

function BaseGUIManager:BringWindowToFront(windowFrame)
  assert(type(windowFrame.WindowZ) == "number")
    
  if(windowFrame.WindowZ ~= self.CurrentWindowLayer) then

    local newLayer = self.CurrentWindowLayer+1
    
    windowFrame.WindowZ = newLayer
    windowFrame.RootFrame:SetLayer(newLayer)
    
    self.CurrentWindowLayer = newLayer
    
    table.sort(self.WindowList, function(win1, win2) return win1.WindowZ < win2.WindowZ end)
  end
end

function BaseGUIManager:AddFrame(frame)
  assert(frame.RootFrame)

	if(not frame.HitRec) then
		error("frame needs to contain a HitRec")
	end

	frame.Parent = self.TopLevelUIParent

  if(self.AnchorFrame) then
    self.AnchorFrame:AddChild(frame.RootFrame)
  end

  if(band(frame.Flags, ControlFlags.IsWindow) ~= 0) then
    table.insert(self.WindowList, frame)

    local layer = self.CurrentWindowLayer+1
    
    frame.WindowZ = layer
    frame.RootFrame:SetLayer(layer)
    
    self.CurrentWindowLayer = layer
  else
    table.insert(self.NonWindowList, frame)
  end

  //frame.RootFrame:SetLayer(self.MenuLayer+1)

	frame:UpdateHitRec()

  if(frame.OnParentSet) then
    frame:OnParentSet()
  end

	table.insert(self.AllFrames, frame)
end

function BaseGUIManager:RemoveFrame(frame, destroyFrame)  
  assert(frame.Parent == self.TopLevelUIParent)

  self:ClearStatesSetToFrame(frame)

  local removed = table.removevalue(self.AllFrames, frame)

  if(band(frame.Flags, ControlFlags.IsWindow)) then
    table.removevalue(self.WindowList, frame)
  else
    table.removevalue(self.NonWindowList, frame)
  end

  if(self.AnchorFrame) then
    self.AnchorFrame:RemoveChild(frame.RootFrame)
  end

  if(destroyFrame and frame.Uninitialize) then
    SafeCall(frame.Uninitialize, frame)
  else
    frame.Parent = nil
    frame:GUIManagerChanged(nil)
  end

  if(not removed) then
    RawPrint("BaseGUIManager:RemoveFrame could not find frame to remove")
  end
end

function BaseGUIManager:ClearStatesSetToFrame(frame)
  
  assert(frame)
  
  if(frame == self.CurrentMouseOver) then
    self:ClearMouseOver()
  end

  if(frame == self.FocusedFrame) then
    self:ClearFocus()
  end

  
  for button, clickedFrame in pairs(self.ClickedFrames) do
    if(clickedFrame == frame) then
      self:SendMouseUpClick(button)
    end
  end

  if(frame == self.ActiveDrag) then
    self:CancelDrag()
  end
end

function BaseGUIManager:SendMouseUps()
  
  for button, frame in pairs(self.ClickedFrames) do
    self:SendMouseUpClick(button)
  end
end

function BaseGUIManager:SendMouseUpClick(button)

  if((self.ActiveDrag or self.DragPreStartFrame) and self.DragButton == button) then
    self:DragStop()
  end

  local clicked = self.ClickedFrames[button]

	if(clicked) then
	  self.ClickedFrames[button] = nil
	  
	  if(clicked.OnClick) then
	    SafeCall(clicked.OnClick, clicked, button, false)
	  end
	end
end

function BaseGUIManager:DoOnClick(frame, x, y)

  local success, result

  if(frame.OnClick) then
    success, result = SafeCall(frame.OnClick, frame, self.ClickedButton, true, x, y)
    
    if(not success) then
     return false
    end
  end

  local parentWindow = frame:GetTopLevelParentWindow()

  if(parentWindow) then
    self:BringWindowToFront(parentWindow)
  end
  
  local dragStart = false
    
  if(band(frame.Flags, ControlFlags.Draggable) ~= 0 and frame.DragButton == self.ClickedButton and frame.DragEnabled) then
    self:DragPreStart(frame, self.ClickedButton, self:GetCursorPos())
    dragStart = true
  end
  
  --if the frames OnClick function didn't return anything we treat that as they accepted the click
  if(result == nil or result == true or dragStart) then
    self.ClickedFrames[self.ClickedButton] = frame
    
    self.ClickedButton = nil
    
    return true
  end

  return result
end

function BaseGUIManager:PassOnClickEvent(button, down)
  return false
end

function BaseGUIManager:MouseClick(button, down)
	PROFILE("MouseTracker:MouseClick")

  --even trigger a mouseup if the click is a from a diffent button
	if(self.ClickedFrames[button]) then
		self:SendMouseUpClick(button)
	end

  if(not down) then
    return not self:PassOnClickEvent(button, down)
  end

  self.ClickedButton = button

  local FrameList = self.AllFrames

  local focus = self.FocusedFrame
  local clearFocus = false

  local MouseX, MouseY = self:GetCursorPos()

  if(focus) then
    local vec = focus:GetScreenPosition()
    local rec = focus.HitRec

    if(MouseX < vec.x or MouseY < vec.y or MouseX > vec.x+(rec[3]-rec[1]) or MouseY > vec.y+(rec[4]-rec[2])) then
      clearFocus = true
    end
  end

  local ClickInFrame = false
  local prevClicked = self.ClickedFrames

  local foundmatch, ClickInFrame = self:StartTraverseFrames(self.WindowList, MouseX, MouseY, self.ClickFlags, self.DoOnClick)

	if(not ClickInFrame) then
    self:TraverseFrames(self:GetFrameList(), MouseX, MouseY, self.ClickFlags, self.DoOnClick)
  end

  if(self.ClickedButton == nil) then
    ClickInFrame = true
  end

  local clicked = self.ClickedFrames
  
  if(ClickInFrame) then
		if(clicked.OnFocusGained) then
			self:SetFocus(clicked)
		else
			if(clearFocus) then
				self:ClearFocus()
			end
		end
	else
	  self:ClearFocus()
  end
  
  return not self:PassOnClickEvent(button, down, ClickInFrame)
end

function BaseGUIManager:ClearFocusIfFrame(frame)
  if(self.FocusedFrame and self.FocusedFrame == frame) then
    self:ClearFocus()
  end
end

function BaseGUIManager:ClearMouseOver()

  local current = self.CurrentMouseOver

  self.CurrentMouseOver = nil
  
  if(current) then
    if(current.OnLeave) then
	    SafeCall(current.OnLeave, current)
	  end
	  
	  current.Entered = false
	end
end

function BaseGUIManager:ClearFocus(newFocus)
  
  local focus = self.FocusedFrame
  
  if(focus) then
    self.FocusedFrame = nil
     
    focus.Focused = false
    
    if(focus.OnFocusLost) then
      SafeCall(focus.OnFocusLost, focus, newFocus)
    end
  end
end

function BaseGUIManager:SetFocus(frame)

  local old = self.FocusedFrame

  self:ClearFocus(frame)

  self.FocusedFrame = frame
    
  if(frame.OnFocusGained) then
    SafeCall(frame.OnFocusGained, frame, old)
  end
  
  frame.Focused = true
end

function BaseGUIManager:IsFocusedSet()
  return self.FocusedFrame ~= nil
end

local Features = {
  OnClick = 1,
  OnEnter = 2,
  OnMouseWheel = 4,
}

function BaseGUIManager:StartTraverseFrames(frameList, x, y, filter, callback)
  self.FirstTraversedFrame = nil

  return self:TraverseFrames(frameList, x, y, filter, callback), self.FirstTraversedFrame ~= nil
end

function BaseGUIManager:TraverseFrames(frameList, x, y, filter, callback)
  assert(frameList)
  
  for i=#frameList,1,-1 do
   local childFrame = frameList[i]
   local rec = childFrame.HitRec
    
    if(not childFrame.Hidden and rec and x > rec[1] and y > rec[2] and x < rec[3] and y < rec[4]) then 
      local result
      local childFlags = band(filter, childFrame.ChildFlags)

        if(not self.FirstTraversedFrame) then
          self.FirstTraversedFrame = childFrame
        end

        --the control has provided it own Traverse function so try that first before we check the controls flags
        if(childFrame.TraverseGetFrame) then
          local x1, x2

          result, x1, x2 = childFrame:TraverseGetFrame(x-rec[1], y-rec[2], filter)

          if(result) then
            if(band(filter, result.Flags) ~= 0) then
              result = callback(self, result, x1, x2)
            else
              assert(result.ChildControls, "TraverseGetFrame returned us a control with no valid filter flags set and it has no ChildControls")
              result = self:TraverseFrames(result.ChildControls, x1, x2, filter, callback)
            end
          end
        end
        
        if(not result and childFlags ~= 0 and childFrame.TraverseChildFirst and childFrame.ChildControls) then
          result = self:TraverseFrames(childFrame.ChildControls, x-rec[1], y-rec[2], filter, callback)
        end
        
        --Call the callback if this control has any of the same flags as the filter
        if(band(filter, childFrame.Flags) ~= 0 and not result) then
          result = callback(self, childFrame, x-rec[1], y-rec[2])
        end
        
        --if the callback returned false or the control didn't have the flags, we go on to try the child controls if any of them have the flags
        if(childFlags ~= 0 and not result and not childFrame.TraverseChildFirst) then
          result = self:TraverseFrames(childFrame.ChildControls, x-rec[1], y-rec[2], filter, callback)
        end
        
        --the callback returned true in this function or in one of our recursive calls so exit now
        if(result) then
          return true
        end
    end
  end
  
  return false
end

function BaseGUIManager:IsMouseStillInFrame(frame)
  return frame == self.CurrentMouseOver
end


function BaseGUIManager:DoOnMouseWheel(frame, x, y)

  local success, result = SafeCall(frame.OnMouseWheel, frame, self.WheelDirection, x, y)
  
  if(not success) then
    return false
  end

  --if the frames OnEnter function didn't return anything we treat that as they accepted the Enter event
  if(result == nil or result == true) then
    self.WheelDirection = nil
    
    return true
  end

  return false
end

function BaseGUIManager:OnMouseWheel(direction) 

  local x,y = self:GetCursorPos()
  
  self.WheelDirection = direction
  
  local ret = self:TraverseFrames(self:GetFrameList(), x, y, 4, self.DoOnMouseWheel)
  
  self.WheelDirection = nil
  
  return ret
end

function BaseGUIManager:DoOnEnter(frame, x, y)

  if(self.CurrentMouseOver) then
    error("BaseGUIManager:DoOnEnter found CurrentMouseOver still set")
  end

  local success, result = SafeCall(frame.OnEnter, frame, x, y)
  
  if(not success) then
    return false
  end
  
  --if the frames OnEnter function didn't return anything we treat that as they accepted the Enter event
  if(result == nil or result == true) then
    self.CurrentMouseOver = frame
    frame.Entered = true
    
    return true
  end

  return false
end

function BaseGUIManager:OnMouseMove()
  local x,y = self:GetCursorPos()
	
	if(self.CurrentMouseOver and not self.ActiveDrag) then
	  local Current = self.CurrentMouseOver
	  
	  --a frame is required to have there HitRec in the same positon as the value returned by there GetScreenPosition function
	  local position = Current:GetScreenPosition()
	  local hitRec = Current.HitRec

    --use the hit rectangle to get the size of the frame
	  local right = position.x+(hitRec[3]-hitRec[1]) 
	  local bottom = position.y+(hitRec[4]-hitRec[2])

	  if(not Current:IsShown() or x < position.x or y < position.y or x > right or y > bottom) then
	    self:ClearMouseOver()
	  end
	end

  if(self.ActiveDrag) then
    self:DragMouseMove(x, y)
  else
    self:CheckDragStart(x, y)
  end
  

  --fire mouse move after we've done OnLeave but before OnEnter so OnEnter/OnLeave frame code is more sane 
	self.Callbacks:Fire("MouseMove", x, y)

	if(not self.CurrentMouseOver and not self.ActiveDrag) then
	  local foundmatch, foundValidRoot = self:StartTraverseFrames(self.WindowList, x, y, 2, self.DoOnEnter)
	  
	  if(not foundValidRoot) then
	    self:TraverseFrames(self:GetFrameList(), x, y, 2, self.DoOnEnter)
	  end
	end
end

function BaseGUIManager:GetFrameList() 
  //TODO Handle message boxs
  return self.NonWindowList
end

function BaseGUIManager:DragPreStart(frame, button, x, y)
  assert(not self.ActiveDrag, "DragPreStart: cannot start a new drag while one is still active")

  self.DragStartClickPos = {x, y}
  self.DragPreStartFrame = frame
  self.DragButton = button
end

function BaseGUIManager:CheckDragStart(x, y)
  
  if(self.ActiveDrag or not self.DragPreStartFrame or (self.DragStartClickPos[1] == x and self.DragStartClickPos[2] == y)) then
    return false
  end

  local draggedFrame = self.DragPreStartFrame
 
  if(draggedFrame.OnDragStart) then
    local sucess, result = SafeCall(draggedFrame.OnDragStart, draggedFrame, unpack(self.DragStartClickPos))
    
    --if OnDragStart triggered an error or returned false we stop the drag
    if(not sucess or result == false) then
      self.DragPreStartFrame = nil
     return false
    end
  end

  local dragRoot = draggedFrame.DragRoot or draggedFrame

  if(not draggedFrame.OnDragMove) then
    self.DragRootFrame = dragRoot
  end

  draggedFrame.DragPos = draggedFrame.DragPos or Vector()
  
  self.DragFrameStartPos = Vector(dragRoot:GetPosition())

  self.ActiveDrag = draggedFrame
  
  return true
end  

function BaseGUIManager:DragMouseMove(x,y)

  local activeDrag = self.ActiveDrag

  x = x-self.DragStartClickPos[1]
  y = y-self.DragStartClickPos[2]

  if(activeDrag.OnDragMove) then
    SafeCall(activeDrag.OnDragMove, activeDrag, x, y, self.DragFrameStartPos)
   return
  end

  local DragPos = activeDrag.DragPos

  DragPos.x = self.DragFrameStartPos.x+x
  DragPos.y = self.DragFrameStartPos.y+y

  self.DragRootFrame:SetPosition(DragPos)
end

function BaseGUIManager:DragStop(isCancel)

  local activeDrag = self.ActiveDrag
  
  if(activeDrag) then
    
    if(activeDrag.OnDragStop) then
     local sucess, result = SafeCall(activeDrag.OnDragStop, activeDrag, unpack(self.DragStartPos), self.DragFrameStartPos)
     
      --if the OnDragStart triggered an error or returned false we stop the drag
      if(not sucess or result == false) then
         self.DragPreStart = nil
        return false
      end
    end

  end

  self.DragPreStartFrame = nil
  self.DragRootFrame = nil
  self.DragButton = nil
  self.ActiveDrag = nil
end

function BaseGUIManager:CancelDrag()
  self:DragStop(true)
end

function BaseGUIManager:DragStarted(frame, button)

  assert(frame.CancelDrag)

  if(self.ActiveDrag) then
		error("DragStarted: There is another drag already active")
	else
	  self.ActiveDrag = frame
	  self.DragButton = button
	end
end

function BaseGUIManager:DragStopped()
  self.ActiveDrag = nil
end

function BaseGUIManager:GetCursorPos()
  return Client.GetCursorPosScreen()
end

function BaseGUIManager:GetSpaceToScreenEdges(xOrVec, y)
  
  local xResult,yResult
  
  if(not y) then
    xResult,yResult = Client.GetScreenWidth()-xOrVec.x,Client.GetScreenHeight()-xOrVec.y
  else
    xResult,yResult = Client.GetScreenWidth()-xOrVec,Client.GetScreenHeight()-y
  end
  
  assert(xResult >= 0 and yResult >= 0, "GUIManager.GetSpaceLeftToScreenEdges error point is outside screen")
  
  return xResult,yResult
end