
/*
  A frame that gets sent an button down OnClick event will always get sent the up event even if the mouse moved off the frame before releasing the button
  
  While a drag is active(a frame notifies of this with DragStarted) no OnEnter events are triggered
  
  We traverse frame lists backwards in case there are overlaping frames 
  
  A frame is required to have there HitRec in the same positon as the value returned by there GetScreenPosition function almost all frames will be using
  the default BaseControl:GetScreenPosition function but frames can override it
*/

local band = bit.band
local bor = bit.bor
local lshift = bit.lshift
local rshift = bit.rshift

if(not GUIManager.ClearFocus) then
  Event.Hook("Console_clearfocus", function() 
    RawPrint("Clearing ui focus")
    GetGUIManager():ClearFocus() 
  end)
end

function GUIManager:_SharedCreate(scriptName)
  
	local creationFunction = _G[scriptName]
		
	if(not creationFunction) then
		Script.Load("lua/" .. scriptName .. ".lua")
		creationFunction = _G[scriptName]
  end

	local newScript 

	if creationFunction == nil then
		Shared.Message("Error: Failed to load GUI script named " .. scriptName)
	 return nil
	end
	
  local success, newScript = SafeCall(creationFunction)
	  
	if(not success) then
	  return nil
	end 
	
	newScript._scriptName = scriptName
	newScript:Initialize()

  if(newScript.HitRec or newScript.OnClick or newScript.OnEnter) then
    self:AddFrame(newScript)
  end
  
 return newScript
end

function GUIManager:AddFrame(frame)

	if(not frame.HitRec) then
		error("frame needs to contain a HitRec")
	end

	self.AddedFrames[frame] = true
	frame.Parent = UIParent
	

	frame:UpdateHitRec()

  if(frame.OnParentSet) then
    self:OnParentSet()
  end

	table.insert(self.TopLevelFrames, frame)
end

function GUIManager:RemoveFrame(frame, destroyFrame)  
  assert(frame.Parent == UIParent)

  local removed = self:CheckRemoveFrame(frame)

  if(destroyFrame and frame.Uninitialize) then
    SafeCall(frame.Uninitialize, frame)
  end

  if(not removed) then
    RawPrint("GUIManager:RemoveFrame could not find frame to remove")
   return
  end

  return removed
end

function GUIManager:CheckRemoveFrame(frame)
  
  if(self.FocusedFrame == frame) then
    self.FocusedFrame = nil
  end
  
  if(self.CurrentMouseOver == frame) then
    self:ClearMouseOver()
  end

	if(frame.RootFrame or frame.HitRec) then
		
		for index, frm in ipairs(self.TopLevelFrames) do
			if(frame == frm ) then
				table.remove(self.TopLevelFrames, index)
			 return true
			end
		end
	end
	
	return false
end

function GUIManager:SendKeyEvent(key, down, isRepeat)

    for index, script in ipairs(self.scripts) do
        if script:SendKeyEvent(key, down, isRepeat) then
            return true
        end
    end
    for index, script in ipairs(self.scriptsSingle) do
        if script[1]:SendKeyEvent(key, down, isRepeat) then
            return true
        end
    end
    return false
    
end

function GUIManager:SetMainMenu(menuFrame)
  self.MainMenu = menuFrame
end

function GUIManager:ParentToMainMenu(frame)
  assert(not frame.Parent or frame.Parent ~= self.MainMenu)
  self.MainMenu:AddChild(frame)
  
  frame.RootFrame:SetLayer(GUIMainMenu.MenuLayer+1)
end

function GUIManager:UnparentFromMainMenu(frame)
  assert(frame.Parent == self.MainMenu)
  self.MainMenu:RemoveChild(frame)
  
  frame.RootFrame:SetLayer(0)
end

function GUIManager:IsMainMenuChild(frame)
  local curr = frame
  
  while curr do
    if(curr == self.MainMenu) then
      return true
    end
    
    curr = curr.Parent
  end
  
  return false
end

function GUIManager:MouseShown()
  
end

function GUIManager:MouseHidden()

  self:ClearMouseOver()

	if(self.ClickedFrame) then
		self.ClickedFrame:OnClick(self.ClickedButton, false)
		self.ClickedFrame = nil
	end
	
	self:ClearFocus()
end


function GUIManager:DoOnClick(frame, x, y)

  local result = frame:OnClick(self.ClickedButton, true, x, y)
  
  --if the frames OnClick function didn't return anything we treat that as they accepted the click
  if(result == nil or result == true) then
    self.ClickedFrame = frame
   return true
  end

  return false
end

function GUIManager:MouseClick(button, down)
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

  local MouseX, MouseY = Client.GetCursorPosScreen()

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
  
  //self:DoFrameOnClick(self.MainMenu, button, MouseX, MouseY) 
  
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

function GUIManager:ClearFocusIfFrame(frame)
  if(self.FocusedFrame and self.FocusedFrame == frame) then
    self:ClearFocus()
  end
end

function GUIManager:ClearMouseOver()

  local current = self.CurrentMouseOver

  if(current) then
    if(current.OnLeave) then
	    SafeCall(current.OnLeave, current)
	  end
	  
	  current.Entered = false
	end

  self.CurrentMouseOver = nil
end

function GUIManager:ClearFocus(newFocus)
  
  local focus = self.FocusedFrame
  
  if(focus) then
    focus.Focused = false
    
    if(focus.OnFocusLost) then
      xpcall2(focus.OnFocusLost, PrintStackTrace, focus, newFocus)
    end
  end
 
  self.FocusedFrame = nil
end
 
function GUIManager:SetFocus(frame)

  local old = self.FocusedFrame

  self:ClearFocus(frame)

  self.FocusedFrame = frame
    
  if(frame.OnFocusGained) then
    xpcall2(frame.OnFocusGained, PrintStackTrace, frame, old)
  end
  
   frame.Focused = true
end

function GUIManager:IsFocusedSet()
  return self.FocusedFrame ~= nil
end

local Features = {
  OnClick = 1,
  OnEnter = 2,
  OnMouseWheel = 4,
}


function GUIManager:TraverseFrames(frameList, x, y, filter, callback)
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

function GUIManager:IsMouseStillInFrame(frame)
  return frame == self.CurrentMouseOver
end


function GUIManager:DoOnMouseWheel(frame, x, y)

  local result = frame:OnMouseWheel(self.WheelDirection, x, y)
  
  --if the frames OnEnter function didn't return anything we treat that as they accepted the Enter event
  if(result == nil or result == true) then
    self.WheelDirection = nil
    
    return true
  end

  return false
end

function GUIManager:DoOnEnter(frame, x, y)

  if(self.CurrentMouseOver) then
    error("GUIManager:DoFrameOnEnter found CurrentMouseOver still set")
  end

  local result = frame:OnEnter(x, y)
  
  --if the frames OnEnter function didn't return anything we treat that as they accepted the Enter event
  if(result == nil or result == true) then
    self.CurrentMouseOver = frame
    frame.Entered = true
    
    return true
  end

  return false
end

function GUIManager:OnMouseMove()
	PROFILE("MouseTracker:OnMouseMove")

  local x,y = Client.GetCursorPosScreen()
	
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


function GUIManager:GetFrameList() 
  if(self.MainMenu and not self.MainMenu.Hidden) then
    return self.MainMenu:GetFrameList()
  else
    return self.TopLevelFrames
  end
end

function GUIManager:DragStarted(frame, button)
  
  if(self.ActiveDrag) then
		error("DragStarted: There is another drag already active")
	else
	  self.ActiveDrag = frame
	end
end

function GUIManager:DragStopped()
  self.ActiveDrag = nil
end

function GUIManager.GetSpaceToScreenEdges(xOrVec, y)
  
  local xResult,yResult
  
  if(not y) then
    xResult,yResult = Client.GetScreenWidth()-xOrVec.x,Client.GetScreenHeight()-xOrVec.y
  else
    xResult,yResult = Client.GetScreenWidth()-xOrVec,Client.GetScreenHeight()-y
  end
  
  assert(xResult >= 0 and yResult >= 0, "GUIManager.GetSpaceLeftToScreenEdges error point is outside screen")
  
  return xResult,yResult
end