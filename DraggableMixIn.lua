class 'Draggable'

function Draggable:__init(width, height)
  self.DragStartPoint = false
  self.DragStartClickedPos = false
  self.DragEnabled = true
  self.IsDragging = false
  self.DragButton = InputKey.MouseButton0

  self.DragPos = Vector(0,0,0)

  if(height and width) then
    self:CreateRootFrame(width, height)
    
    self:SetupHitRec()
  end
end

function Draggable:SetRootFrame(frame)
  BaseControl.SetRootFrame(self, frame)
  self.DragRoot = frame
end

function Draggable:OnClick(button, down)

  if(button == self.DragButton) then
    if(down) then
      if(self.DragEnabled) then
        --this shouldn't happen normaly but if someone mouse button is dieing
        if(self.IsDragging) then
          self:OnDragStop(true)
         return true
        end

        self:DragStartUp()
      end
    else
      if(self.IsDragging) then
        self:OnDragStop()
      end
      self.DragStage = -1
    end
    
    return true
  end
  
  return false
end

function Draggable:DragStartUp()
  self.DragStartPos = {Client.GetCursorPosScreen()}
  self.DragStage = 0
  
  self:RegisterForMouseMove("DragMouseMove")
end

function Draggable:OnDragStart()
  self.DragStage = 1
  self.IsDragging = true
  
  local vec = self.RootFrame:GetPosition()
  self.FrameStartPos = {vec.x, vec.y}
  
  self:GetGUIManager():DragStarted(self, self.DragButton)
end

function Draggable:DragMouseMove(x,y)

  --maybe have a min move amount check here
  if(self.DragStage == 0) then
    self:OnDragStart()
  end

  if(self.IsDragging) then
    self.DragPos.x = self.FrameStartPos[1]+(x-self.DragStartPos[1])
    self.DragPos.y = self.FrameStartPos[2]+(y-self.DragStartPos[2])

    self.DragRoot:SetPosition(self.DragPos)
  else
    self:UnregisterForMouseMove()
  end
end

function Draggable:OnDragStop(dontSetPositon)
  
  local x,y = Client.GetCursorPosScreen()
  
  self:GetGUIManager():DragStopped(self)
  self.IsDragging = false
  
  self:UnregisterForMouseMove()

  if(not dontSetPositon and (self.DragStartPos[1] ~= x or self.DragStartPos[2] ~= y)) then
    self:SetPosition(self.DragPos)
  end
end

function Draggable:CancelDrag()
  if(self.IsDragging) then
    self:OnDragStop()
    self.DragStage = -1
  end
end

function Draggable:Mixin(tbl)
  tbl.OnDragStart = self.OnDragStart
  tbl.DragStartUp = self.DragStartUp
  tbl.OnDragStop = self.OnDragStop
  
  tbl.DragMouseMove = self.DragMouseMove
  
  tbl.CancelDrag = self.CancelDrag
  
  tbl.SetRootFrame = self.SetRootFrame
  tbl.OnClick = self.OnClick  
end