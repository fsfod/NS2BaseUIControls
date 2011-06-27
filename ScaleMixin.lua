ScaleMixin = {}

function ScaleMixin:SetSize(VecOrX, y, SkipHitRecUpdate)

	local scale = GUIMananger.Scale

	if(y) then
	  self.OrignalHeight = VecOrX
	  self.OrignalWidth = y

		self:BaseSetSetize(VecOrX*scale, y*scale)
	else
    self.OrignalHeight = VecOrX.x
	  self.OrignalWidth = VecOrX.y
	  
	  self:BaseSetSetize(VecOrX*scale, SkipHitRecUpdate)
	end

end

function ScaleMixin:CustomSetHeight(height)
  self:SetSize(self.OrignalWidth, height)
end

function ScaleMixin:SetHeight(height)
  self:SetSize(self.OrignalWidth, height)
end

function ScaleMixin:SetWidth(width)
  self:SetSize(width, self.OrignalHeight)
end

function ScaleMixin:SetPoint(point, x, y, reltivePoint)
	
	local root = self.RootFrame
	
	if(reltivePoint) then
		self.SpecialAnchor = {point, x, y, reltivePoint}
	end
	
	if(x) then
	  local scale = GUIMananger.Scale
	  
	  x = x*scale
	  y = y*scale
	end
	
	local point = PointToAnchor[point]
	root:SetAnchor(point[1], point[2])

	--the point a controls position is based off is TopLeft in the ns2 gui system
	if(reltivePoint) then
		local relpoint = PointToAnchor[reltivePoint]
		local Size = self.Size
		
		if(relpoint[1] == GUIItem.Right) then
			x = (-Size.x)+x
		elseif(relpoint[1] == GUIItem.Middle) then
			x = x-(Size.x/2)
		end
		
		if(relpoint[2] == GUIItem.Bottom) then
			y = (-Size.y)+y
		elseif(relpoint[2] == GUIItem.Center) then
			y = y-(Size.y/2)
		end
	end

	self:SetPosition(x, y)
end

function ScaleMixin:SetPosition(VecOrX, y)

  local scale = GUIMananger.Scale

  if(y) then
	  self.OrignalX = VecOrX
	  self.OrignalY = y

		self:BasePosition(VecOrX*scale, y*scale)
	else
    self.OrignalX = VecOrX.x
	  self.OrignalY = VecOrX.y
	  
	  self:BasePosition(VecOrX.x*scale, VecOrX.y*scale)
	end
end

function ScaleMixin:MixIn(class)

  class.BaseSetPosition =  class.SetPosition
  class.SetPosition = self.SetPosition

  class.BaseSetSize =  class.SetSize
  class.SetSize =  self.SetSize
  
  if(class.SetHeight ~= BaseControl.SetHeight) then
    
  end
end

class 'ScaledBaseControl'(BaseControl)

ScaleMixin:MixIn(ScaledBaseControl)
