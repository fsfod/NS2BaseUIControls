--Virtual Screen Size
local MouseX,MouseY = 0,0
local Instance

local MT = {__call = function() return MouseTracker end}


if(not MouseTracker) then

  MouseTracker = {
	  TopLevelFrames = {},
	  AddedFrames = {},
  }
  
  MouseTracker.Callbacks = CallbackHandler:New(MouseTracker)
end

MouseTracker.DblClickSpeed = 0.5

local HotReload = ClassHooker:Mixin("MouseTracker")

function MouseTracker:OnLoad()
	self:SetHooks()
end

function MouseTracker:SetHooks()
  ClassHooker:SetClassCreatedIn("GUIManager", "lua/GUIManager.lua")
  self:HookClassFunction("GUIManager","SendKeyEvent"):SetPassHandle(true)
  self:ReplaceClassFunction("GUIManager", "_SharedCreate")
  self:HookClassFunction("GUIManager", "DestroyGUIScript", "CheckRemoveFrame")
  
  self:HookClassFunction("GUIManager", "Update")

  self:HookLibraryFunction(HookType.Post, "Client", "ReloadGraphicsOptions", "CheckGraphicsOptions")
  //self:HookLibraryFunction(HookType.Post, "Client", "SetCursor", function(cursor) Shared.Message(tostring(cursor or "nil")) end)
end

function MouseTracker:CheckGraphicsOptions()
  if(CheckUpdateScreenRes()) then
    local width,height = Client.GetScreenWidth(),Client.GetScreenHeight()
    
    for i,frame in ipairs(self.TopLevelFrames) do
      frame:OnScreenSizeChanged(width,height)
    end
  end
end

function MouseTracker:Update()
  
  self:CheckGraphicsOptions()
  
  local MouseVisible = Client.GetMouseVisible()
  
  if(MouseVisible) then
    if(not self.MouseIsVisible) then
      self:MouseShown()
      self.MouseIsVisible = true
    end
    
    if(self.MouseMoved) then
      self:OnMouseMove()
      self.MouseMoved = false
    end
  else
    if(self.MouseIsVisible) then
      self:MouseHidden()
      self.MouseIsVisible = false
    end
  end
end

function MouseTracker:MouseShown()
  
end

function MouseTracker:MouseHidden()

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

function MouseTracker:OnClientLuaFinished()
  
  Event.RemoveHook("SetupCamera", OnSetupCamera)
  
  Event.Hook("SetupCamera", function(...) 
    
    if(not Client.GetIsConnected()) then
      GetGUIManager():Update(Client.GetTime())
    end
    
    return OnSetupCamera(...) 
  end)
end

function MouseTracker:_SharedCreate(GUIManagerSelf,scriptName)
  
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
	
	local newScript = creationFunction()
	 newScript._scriptName = scriptName
	 newScript:Initialize()

  if(newScript.HitRec or newScript.OnClick) then
    self:AddFrame(newScript)
  end
  
  return newScript
end

function MouseTracker:AddFrame(frame)

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

function MouseTracker:CheckRemoveFrame(frame)
	if(self.AddedFrames[frame]) then
		self.AddedFrames[frame] = nil
		
		for index, frm in ipairs(self.TopLevelFrames) do
			if(frame == frm ) then
				table.remove(self.TopLevelFrames, index)
			end
		end
	end
end

function MouseTracker:SettingKeybindHook(callback, selfarg)
  self.SettingKeybind = {callback, selfarg}
end

function MouseTracker:SendKeyEvent(handle, _, key, down, a1)
	PROFILE("MouseTracker:SendKeyEvent")

  if(not Client.GetMouseVisible()) then
    return false
  end

	if(key == InputKey.MouseX or key == InputKey.MouseY) then
	  //self:OnMouseMove()
	  self.MouseMoved = true
	else
	  local block = false
	  
	  if(self.SettingKeybind and down) then
	    self.SettingKeybind[1](self.SettingKeybind[2], key)
	    self.SettingKeybind = nil
	    self.EatKeyUp = key
	    
	    block = true
		elseif(self.EatKeyUp == key) then
		  self.EatKeyUp = nil
		  block = true
	  end
	  
	  if(block) then
	    handle:BlockOrignalCall()
		  handle:SetReturn(true)
		end
	end

	if(key == InputKey.MouseButton0 or key == InputKey.MouseButton1 or key == InputKey.MouseButton3) then
		if(self:MouseClick(key, down)) then
		  handle:BlockOrignalCall()
		  handle:SetReturn(true)
		end
	else
		if(key ~= InputKey.MouseX and key ~= InputKey.MouseY) then
			return false
		end
	end
end

function MouseTracker:UpdateMousePositon()
	local x,y = Client.GetCursorPos()
		x = x*ScreenMaxX
		y = y*ScreenMaxY
		MouseX = x
		MouseY = y
end

function MouseTracker:DragStarted(frame, button)
  
  if(self.ActiveDrag) then
		error("there is another drag already active")
	else
	  self.ActiveDrag = frame
	end
end

function MouseTracker:DragStopped()
  self.ActiveDrag = nil
end

local function CheckChildOnEnter(frame, x, y)
            
  for i=#frame.ChildControls,1,-1 do
   local childFrame = frame.ChildControls[i]
   
    local rec = childFrame.HitRec
    
    if((childFrame.ChildHasOnEnter or childFrame.OnEnter) and not childFrame.Hidden and x > rec[1] and y > rec[2] and x < rec[3] and y < rec[4]) then
      if(not childFrame.OnEnter) then
        CheckChildOnEnter(childFrame, x-rec[1], y-rec[2])
      else
        MouseTracker:DoFrameOnEnter(childFrame, x-rec[1], y-rec[2])
      end
    end
  end
end

function MouseTracker:DoFrameOnEnter(frame, x, y)
  
  if(self.CurrentMouseOver) then
    error("MouseTracker:DoFrameOnEnter found CurrentMouseOver still set")
  end
  
  local enteredFrame = frame:OnEnter(x, y)
  
  if(enteredFrame ~= false) then
    self.CurrentMouseOver = enteredFrame or frame
  end
end

function MouseTracker:IsMouseStillInFrame(frame)
  return frame == self.CurrentMouseOver
end

function MouseTracker:OnMouseMove()
	PROFILE("MouseTracker:OnMouseMove")
	
	self:UpdateMousePositon()

  local x,y = MouseX, MouseY
	
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
	    
	    self.CurrentMouseOver = nil
	  end
	end

  --fire mouse move after we've done OnLeave but before OnEnter so OnEnter/OnLeave frame code is more sane 
	self.Callbacks:Fire("MouseMove", MouseX, MouseY)

	if(not self.CurrentMouseOver and not self.ActiveDrag) then
	 for i=#self.TopLevelFrames,1,-1 do
    local frame = self.TopLevelFrames[i]
    
		  if((frame.OnEnter or frame.ChildHasOnEnter) and not frame.Hidden and self.MouseWithinRec(frame.HitRec)) then

        if(not frame.OnEnter) then
          CheckChildOnEnter(frame, x-frame.HitRec[1], y-frame.HitRec[2])
        else
          self:DoFrameOnEnter(frame, x-frame.HitRec[1], y-frame.HitRec[2])
        end
        break
		  end
	  end
	end
end

function MouseTracker:GetMousePostition()
	return MouseX,MouseY
end

local function CheckChildOnClick(frame, button, x, y)
  
     
  for i=#frame.ChildControls,1,-1 do
    local childFrame = frame.ChildControls[i]
    local rec = childFrame.HitRec
    
    if((childFrame.ChildHasOnClick or childFrame.OnClick) and not childFrame.Hidden and x > rec[1] and y > rec[2] and x < rec[3] and y < rec[4]) then
      if(not childFrame.OnClick) then
        MouseTracker.ContainerOnClick(childFrame, button, x-rec[1], y-rec[2])
      else
        MouseTracker:DoFrameOnClick(childFrame, button, x-rec[1], y-rec[2])
      end
    end
  end
end

MouseTracker.ContainerOnClick = CheckChildOnClick
  
function MouseTracker:ClearFocus(newFocus)
  
  local focus = self.FocusedFrame
  
  if(focus) then
    focus.Focused = false
    
    if(focus.OnFocusLost) then
      focus:OnFocusLost(newFocus)
    end
  end
 
  self.FocusedFrame = nil
end
  
function MouseTracker:SetFocus(frame)

  local old = self.FocusedFrame

  self:ClearFocus(frame)

  self.FocusedFrame = frame
    
  if(frame.OnFocusGained) then
    frame:OnFocusGained(old)
  end
  
   frame.Focused = true
end

function MouseTracker:MouseClick(button, down)
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

  if(focus) then
    local vec = focus:GetScreenPosition()
    local rec = focus.HitRec
    
    if(MouseX < vec.x or MouseY < vec.y or vec.x > (rec[3]-rec[1]) or vec.y > (rec[4]-rec[2])) then
      clearFocus = true
    end
  end

  if(self.ActiveMenu) then
   return
  end

  local ClickInFrame = false

	for i=#FrameList,1,-1 do
    local frame = FrameList[i]
   
    if((frame.ChildHasOnClick or frame.OnClick) and not frame.Hidden and self.MouseWithinRec(frame.HitRec)) then
     //assume that on a valid hit test we always go down to a child or a OnClick function
     local x,y = MouseX-frame.HitRec[1], MouseY-frame.HitRec[2]
    
      if(not frame.OnClick) then
        CheckChildOnClick(frame, button, x, y)
      else
        self:DoFrameOnClick(frame, button, x, y)
      end
      ClickInFrame = true
      break
    end
  end
  
  local clicked = self.ClickedFrame
  
  if(clicked and clicked.OnFocusGained) then
    self:SetFocus(clicked)
  else
    if(clearFocus) then
      self:ClearFocus()
    end
  end
  
  return ClickInFrame
end

function MouseTracker:DoFrameOnClick(frame, button, x,y)
	--the frame might have a ChildControls table but we assume it will do its own hit testing because it has a OnClick function
  local clickedFrame = frame:OnClick(button, true, x,y)
	
	if(clickedFrame and type(clickedFrame) ~= "boolean") then
	  self.ClickedFrame = clickedFrame
	else
	  self.ClickedFrame = frame
	end
end

function MouseTracker.MouseWithinRec(rec)
	return (MouseX > rec[1] and MouseY > rec[2] and MouseX < rec[3] and MouseY < rec[4])
end

if(HotReload) then
  MouseTracker:SetHooks()
end