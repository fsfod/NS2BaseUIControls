BaseGUIManager = {
  DblClickSpeed = 0.5,
}


local band = bit.band
local bor = bit.bor

function BaseGUIManager:Initialize()
  Event.Hook("UpdateClient", function() self:Update() end)

  self.Callbacks = CallbackHandler:New(self)  
  self.TopLevelFrames = {}
end

function BaseGUIManager:SendKeyEvent(key, down, IsRepeat, wheelDirection)

  if(not self:IsActive()) then
    return false
  end

  if(key == InputKey.MouseX or key == InputKey.MouseY) then
    self.MouseMoved = true
   return false
  end

  if(key == InputKey.MouseButton0 or key == InputKey.MouseButton1 or key == InputKey.MouseButton3) then
    self:MouseClick(key, down)
   return true
  end

  local focus = self.FocusedFrame

  if(focus and focus.SendKeyEvent and focus:SendKeyEvent(key, down, IsRepeat)) then
    return true
  end

  if(wheelDirection and self:OnMouseWheel(wheelDirection)) then
    return true
  end

  for _,frame in ipairs(self.TopLevelFrames) do
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

  local clicked =self.ClickedFrame 

  if(clicked) then
    SafeCall(clicked.OnClick, clicked, self.ClickedButton, false)
		self.ClickedFrame = nil
	end

	self:ClearFocus()
  
  self:ClearMouseOver()
end

function BaseGUIManager:Update()
  
  if(not self:IsActive()) then
    return
  end

  if(self.FocusedFrame and not self.FocusedFrame:IsShown()) then
    self:ClearFocus()
  end

  if(self.MouseMoved) then
    self:OnMouseMove()
    self.MouseMoved = false
  end
  
  self:UpdateFrames()
end

function BaseGUIManager:UpdateFrames()

  for _,frame in ipairs(self.TopLevelFrames) do
    frame:Update()
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

  //frame.RootFrame:SetLayer(self.MenuLayer+1)

	frame:UpdateHitRec()

  if(frame.OnParentSet) then
    frame:OnParentSet()
  end

	table.insert(self.TopLevelFrames, frame)
end

function BaseGUIManager:RemoveFrame(frame, destroyFrame)  
  assert(frame.Parent == self.TopLevelUIParent)

  local removed = table.removevalue(self.TopLevelFrames, frame)

  if(self.AnchorFrame) then
    self.AnchorFrame:RemoveChild(frame.RootFrame)
  end

  if(destroyFrame and frame.Uninitialize) then
    SafeCall(frame.Uninitialize, frame)
  end

  if(not removed) then
    RawPrint("BaseGUIManager:RemoveFrame could not find frame to remove")
  end
end

function BaseGUIManager:DoOnClick(frame, x, y)

  local success, result = SafeCall(frame.OnClick, frame, self.ClickedButton, true, x, y)
  
  if(not success) then
    return false
  end
 
  --if the frames OnClick function didn't return anything we treat that as they accepted the click
  if(result == nil or result == true) then
    self.ClickedFrame = frame
    
    return true
  end

  return result
end

function BaseGUIManager:MouseClick(button, down)
	PROFILE("MouseTracker:MouseClick")

  --even trigger a mouseup if the click is a from a diffent button
	if(self.ClickedFrame) then
		self.ClickedFrame:OnClick(self.ClickedButton, false)
		self.ClickedFrame = nil
	end

  if(not down) then
    return
  end

  self.ClickedButton = button

  local FrameList = self.TopLevelFrames

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
  local prevClicked = self.ClickedFrame

  self:TraverseFrames(self:GetFrameList(), MouseX, MouseY, 1, self.DoOnClick)

  if(self.ClickedFrame and self.ClickedFrame ~= prevClicked) then
    ClickInFrame = true
  end

  local clicked = self.ClickedFrame
  
  if(clicked) then
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
  
  return ClickInFrame
end

function BaseGUIManager:ClearFocusIfFrame(frame)
  if(self.FocusedFrame and self.FocusedFrame == frame) then
    self:ClearFocus()
  end
end

function BaseGUIManager:ClearMouseOver()

  local current = self.CurrentMouseOver

  if(current) then
    if(current.OnLeave) then
	    SafeCall(current.OnLeave, current)
	  end
	  
	  current.Entered = false
	end

  self.CurrentMouseOver = nil
end

function BaseGUIManager:ClearFocus(newFocus)
  
  local focus = self.FocusedFrame
  
  if(focus) then
    focus.Focused = false
    
    if(focus.OnFocusLost) then
      SafeCall(focus.OnFocusLost, focus, newFocus)
    end
  end
 
  self.FocusedFrame = nil
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


function BaseGUIManager:TraverseFrames(frameList, x, y, filter, callback)
  assert(frameList)
  
  for i=#frameList,1,-1 do
   local childFrame = frameList[i]
   local rec = childFrame.HitRec
    
    if(not childFrame.Hidden and rec and x > rec[1] and y > rec[2] and x < rec[3] and y < rec[4]) then 
        local result
        local childFlags = band(filter, childFrame.ChildFlags)

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

  --fire mouse move after we've done OnLeave but before OnEnter so OnEnter/OnLeave frame code is more sane 
	self.Callbacks:Fire("MouseMove", x, y)

	if(not self.CurrentMouseOver and not self.ActiveDrag) then
	  self:TraverseFrames(self:GetFrameList(), x, y, 2, self.DoOnEnter)
	end
end

function BaseGUIManager:GetFrameList() 
  //TODO Handle message boxs
  return self.TopLevelFrames
end

function BaseGUIManager:DragStarted(frame, button)
  
  if(self.ActiveDrag) then
		error("DragStarted: There is another drag already active")
	else
	  self.ActiveDrag = frame
	end
end

function BaseGUIManager:DragStopped()
  self.ActiveDrag = nil
end

function BaseGUIManager:GetCursorPos()
  return Client.GetCursorPosScreen()
end

function BaseGUIManager.GetSpaceToScreenEdges(xOrVec, y)
  
  local xResult,yResult
  
  if(not y) then
    xResult,yResult = Client.GetScreenWidth()-xOrVec.x,Client.GetScreenHeight()-xOrVec.y
  else
    xResult,yResult = Client.GetScreenWidth()-xOrVec,Client.GetScreenHeight()-y
  end
  
  assert(xResult >= 0 and yResult >= 0, "GUIManager.GetSpaceLeftToScreenEdges error point is outside screen")
  
  return xResult,yResult
end