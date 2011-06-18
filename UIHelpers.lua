--Virtual Screen Size

ScreenMaxX = Client.GetScreenWidth()
ScreenMaxY = Client.GetScreenHeight()

ScreenCenterX = ScreenMaxX/2
ScreenCenterY = ScreenMaxY/2

--Dummy Control to help make position calculations simple
UIParent = {
	Position = Vector(0, 0, 0),
	Size = Vector(ScreenMaxX, ScreenMaxY, 0),
	GetXAnchor = function() return GUIItem.Left end,
	GetYAnchor = function() return GUIItem.Top end,
	IsShown = function() return true end,
}

function CheckUpdateScreenRes()
  
  local width,height = Client.GetScreenWidth(),Client.GetScreenHeight()
  
  if(ScreenMaxX ~= width or ScreenMaxY ~= height) then
    ScreenMaxX = width
    ScreenMaxY = height
    UIParent.Size.x = width
    UIParent.Size.y = height
    
   return true
  end
  
  return false
end

function UpdateHitRec(control, rec)
	local x,y = ConvertToScreenCoords(control)
	 rec[1] = x
	 rec[2] = y
	
	local size = control:GetSize()
	 rec[3] = x+size.x
	 rec[4] = y+size.y
end

function ConvertToScreenCoords(control)
	local x, y
	local Pos = control:GetPosition()
	
	local xAnchor = control:GetXAnchor()
	
	if(xAnchor == GUIItem.Left) then
		x = Pos.x
	elseif(xAnchor == GUIItem.Right) then
		x = ScreenMaxX+Pos.x
	else
		x = ScreenCenterX+Pos.x
	end

	local yAnchor = control:GetYAnchor()

	if(yAnchor == GUIItem.Top) then
		y = Pos.y
	elseif(yAnchor == GUIItem.Bottom) then
		y = ScreenMaxY+Pos.y
	else
		y = ScreenCenterY+Pos.y
	end
	
	return x, y
end