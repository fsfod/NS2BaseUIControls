
if(not GUIManager.ClearFocus) then
  Event.Hook("Console_clearfocus", function() 
    Print("Clearing ui focus")
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
    Print("GUIManager:RemoveFrame could not find frame to remove")
   return
  end

  return removed
end

function GUIManager:CheckRemoveFrame(frame)
  
  if(self.FocusedFrame == frame) then
    self.FocusedFrame = nil
  end
  
	if(self.AddedFrames[frame]) then
		self.AddedFrames[frame] = nil
		
		for index, frm in ipairs(self.TopLevelFrames) do
			if(frame == frm ) then
				table.remove(self.TopLevelFrames, index)
			 return true
			end
		end
	end
	
	return false
end

function GUIManager:ScreenSizeChanged()

  local width,height = Client.GetScreenWidth(),Client.GetScreenHeight()

  for i,frame in ipairs(self.TopLevelFrames) do
    frame:OnScreenSizeChanged(width,height)
  end
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

  if(self.CurrentMouseOver) then
    if(self.CurrentMouseOver.OnLeave) then
	    self.CurrentMouseOver:OnLeave()
	  end
    self.CurrentMouseOver = nil
  end
  

	if(self.ClickedFrame) then
		self.ClickedFrame:OnClick(self.ClickedButton, false)
		self.ClickedFrame = nil
	end
	
	self:ClearFocus()
end

function GUIManager:CheckChildOnClick(frame, button, x, y)
   
  for i=#frame.ChildControls,1,-1 do
    local childFrame = frame.ChildControls[i]
    local rec = childFrame.HitRec
    
    if((childFrame.ChildHasOnClick or childFrame.OnClick) and not childFrame.Hidden and x > rec[1] and y > rec[2] and x < rec[3] and y < rec[4]) then
      if(not childFrame.OnClick) then
        self:CheckChildOnClick(childFrame, button, x-rec[1], y-rec[2])
      else
        self:DoFrameOnClick(childFrame, button, x-rec[1], y-rec[2])
      end
    end
  end
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

  if(self.MainMenu and not self.MainMenu.Hidden) then
    local prevClicked = self.ClickedFrame
     self:DoFrameOnClick(self.MainMenu, button, MouseX, MouseY) 
    
    if(self.ClickedFrame and self.ClickedFrame ~= prevClicked) then
      ClickInFrame = true
    end
  else
    for i=#FrameList,1,-1 do
      local frame = FrameList[i]
      local rec = frame.HitRec
      
      if((frame.ChildHasOnClick or frame.OnClick) and not frame.Hidden and MouseX > rec[1] and MouseY > rec[2] and MouseX < rec[3] and MouseY < rec[4]) then
       //assume that on a valid hit test we always go down to a child or a OnClick function
       local x,y = MouseX-frame.HitRec[1], MouseY-frame.HitRec[2]
      
        if(not frame.OnClick) then
          self:CheckChildOnClick(frame, button, x, y)
        else
          self:DoFrameOnClick(frame, button, x, y)
        end
        
        ClickInFrame = true
       break
      end
    end
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

function GUIManager:DoFrameOnClick(frame, button, x,y)
	--the frame might have a ChildControls table but we assume it will do its own hit testing because it has a OnClick function
  local clickedFrame = frame:OnClick(button, true, x,y)
	
	if(clickedFrame and type(clickedFrame) ~= "boolean") then
	  self.ClickedFrame = clickedFrame
	else
	  self.ClickedFrame = frame
	end
end

function GUIManager:ClearFocusIfFrame(frame)
  if(self.FocusedFrame and self.FocusedFrame == frame) then
    self:ClearFocus()
  end
end

function GUIManager:ClearMouseOver()
  
  local current = self.CurrentMouseOver
  
  if(current and current.OnLeave) then
	  safecall(current.OnLeave, current)
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

function GUIManager:CheckChildOnEnter(frame, x, y)
            
  for i=#frame.ChildControls,1,-1 do
   local childFrame = frame.ChildControls[i]
   
    local rec = childFrame.HitRec
    
    if((childFrame.ChildHasOnEnter or childFrame.OnEnter) and not childFrame.Hidden and x > rec[1] and y > rec[2] and x < rec[3] and y < rec[4]) then
      if(not childFrame.OnEnter) then
        self:CheckChildOnEnter(childFrame, x-rec[1], y-rec[2])
      else
        self:DoFrameOnEnter(childFrame, x-rec[1], y-rec[2])
      end
    end
  end
end

function GUIManager:IsMouseStillInFrame(frame)
  return frame == self.CurrentMouseOver
end

function GUIManager:DoFrameOnEnter(frame, x, y)
  
  if(self.CurrentMouseOver) then
    error("GUIManager:DoFrameOnEnter found CurrentMouseOver still set")
  end
  
  local enteredFrame = frame:OnEnter(x, y)
  
  if(enteredFrame ~= false) then
    self.CurrentMouseOver = enteredFrame or frame
    self.CurrentMouseOver.Entered = true
  end
end

function GUIManager:OnMouseMove()
	PROFILE("MouseTracker:OnMouseMove")

  local x,y = Client.GetCursorPosScreen()
	
	  local MouseX, MouseY = Client.GetCursorPosScreen()
	
	if(self.CurrentMouseOver and not self.ActiveDrag) then
	  local Current = self.CurrentMouseOver
	  
	  --a frame is required to have there HitRec in the same positon as the topleft corner of there RootFrame
	  local position = Current.RootFrame:GetScreenPosition(Client.GetScreenWidth(), Client.GetScreenHeight())
	  local hitRec = Current.HitRec

    --use the hit rectangle to get the size of the frame
	  local right = position.x+(hitRec[3]-hitRec[1]) 
	  local bottom = position.y+(hitRec[4]-hitRec[2])

	  if(not Current:IsShown() or x < position.x or y < position.y or x > right or y > bottom) then
	    if(Current.OnLeave) then
	      Current:OnLeave()
	    end
	    Current.Entered = false
	    self.CurrentMouseOver = nil
	  end
	end

  --fire mouse move after we've done OnLeave but before OnEnter so OnEnter/OnLeave frame code is more sane 
	self.Callbacks:Fire("MouseMove", MouseX, MouseY)

	if(not self.CurrentMouseOver and not self.ActiveDrag) then
	  if(self.MainMenu and not self.MainMenu.Hidden) then
       self:DoFrameOnEnter(self.MainMenu, MouseX, MouseY) 
    else
	  
	    for i=#self.TopLevelFrames,1,-1 do
       local frame = self.TopLevelFrames[i]
       local rec = frame.HitRec
       
		     if((frame.OnEnter or frame.ChildHasOnEnter) and not frame.Hidden and x > rec[1] and y > rec[2] and x < rec[3] and y < rec[4]) then
      
           if(not frame.OnEnter) then
             self:CheckChildOnEnter(frame, x-frame.HitRec[1], y-frame.HitRec[2])
           else
             self:DoFrameOnEnter(frame, x-frame.HitRec[1], y-frame.HitRec[2])
           end
          break
		     end
	   end
	 end
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