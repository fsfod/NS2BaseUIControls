//
//   Created by:   fsfod
//

local GUIItem = GUIItem
local SetPosition = GUIItem.SetPosition
local SetSize = GUIItem.SetSize

local UIScale, UIScaleMult = 1,1

if(not _G.UIScale) then
  _G.UIScale = 1
  UIFontScale = 1
  _G.UIScaleMult = 1
else
  UIScale = _G.UIScale
  UIScaleMult = _G.UIScaleMult
end

local function SetUIScale(newScale)
  UIScaleMult = newScale/UIScale
  _G.UIScaleMult = UIScaleMult
  UIScale = newScale
  _G.UIScale = newScale
  
  UIFontScale = newScale
end

function ChangeUIScale(newScale)
  SetUIScale(newScale)
  
  GUIMenuManager:UpdateScale()
  GameGUIManager:UpdateScale()
end


Event.Hook("Console_setuiscale", function(scale)
  local sucess, value = pcall(tonumber, scale)
  
  if(not sucess) then
    RawPrint("setuiscale: %s was not a number", scale)
   return
  end
  
  value = math.max(0.1, value)
 
  RawPrint("setting uiscale to %f", value)

  ChangeUIScale(value)
end)

local ThresholdHeight = 800


function SetupUIScale()
  local screenHeight = Client.GetScreenHeight()

  if(screenHeight < 800) then
    //clamp to 0.7 because fonts tend to look horrible any lower
    local amount = math.max(0.7, screenHeight/800)
  
    RawPrint("UIScale %f", amount)
  
    SetUIScale(amount)
  end
end

Event.Hook("ResolutionChanged", function(oldWidth, oldHeight, width, height)

  if(height == oldHeight or (oldHeight > ThresholdHeight and height > ThresholdHeight)) then
    UIScaleMult = 1
   return
  end

  if(height > ThresholdHeight) then
    SetUIScale(1)
  else
    SetUIScale(math.max(0.7, height/800))
  end
end)

function ScaledSetPosition(self, pos)
  SetPosition(self, pos*UIScale)
end
GUIItemTable.SetPosition = ScaledSetPosition

function ScaledSetSize(self, pos)
  SetSize(self, pos*UIScale)
end
GUIItemTable.SetSize = ScaledSetSize


local GetPosition = GUIItem.GetPosition

function ScaledGetPosition(self)
  return GetPosition(self)/UIScale
end
GUIItemTable.GetPosition = ScaledGetPosition

local GetSize = GUIItem.GetSize

function ScaledGetSize(self)
  return GetSize(self)/UIScale
end
GUIItemTable.GetSize = ScaledGetSize

ChangePositionSizeFunctions(ScaledSetPosition, ScaledSetSize, ScaledGetPosition, ScaledGetSize)


local ScaledGetTextWidth = function(self, text)
  return GUIItem.GetTextWidth(self, text)/UIScale
end

GUIItemTable.GetTextWidth = ScaledGetTextWidth
BaseControl.GetTextWidth = ScaledGetTextWidth

local function ScaledGetTextHeight(self, text)
  return GUIItem.GetTextHeight(self, text)/UIScale
end

GUIItemTable.GetTextHeight = ScaledGetTextHeight
BaseControl.GetTextHeight = ScaledGetTextHeight

GUIItemTable.GetTextHeight = function(self, text)
  return GUIItem.GetTextHeight(self, text)/UIScale
end

local function MakeCreateGUIItem()

  local CreateItem = GUI.CreateItem
  local vec = Vector()

  BaseControl.CreateGUIItem = function(self, xOrVec, y)
  
    local item = CreateItem()
    
    setmetatable(debug.getfenv(item), GUIItemTable)
    
    self:AddGUIItemChild(item)
    
    if(xOrVec) then
      
      if(y) then
        vec.x = x
        vec.y = y
        
        xOrVec = vec
      end

      ScaledSetPosition(item, xOrVec)
    end
    
    return item
  end


end

MakeCreateGUIItem()

function BaseControl:Rescale()
  SetSize(self, self.Size*UIScale)
  SetPosition(self, self.Position*UIScale)
 
  for i,frame in ipairs(debug.getfenv(self)) do
    SetPosition(frame, GetPosition(frame)*UIScaleMult)

    if(not frame._FontSize) then
      SetSize(frame, GetSize(frame)*UIScaleMult)
    else
      frame:SetFontSize(frame._FontSize)
    end
  end

  if(self.ChildControls) then
    for i,frame in ipairs(self.ChildControls) do
      frame:Rescale()
    end
  end
end

function BaseControl:GetScreenPosition()
  return  GUIItem.GetScreenPosition(self.RootFrame, Client.GetScreenWidth(), Client.GetScreenHeight())/UIScale
end

/*
function BaseControl:UpdateHitRec(rec)
  
  local xAnchor = self.RootFrame:GetXAnchor()
  local yAnchor = self.RootFrame:GetYAnchor()
  
  local Pos = self.Position
  local x,y
  
  if(not self.Parent and xAnchor == GUIItem.Left and yAnchor == GUIItem.Top) then
    x,y = Pos.x,Pos.y
  else
    local Size = (self.Parent or UIParent).Size
  
    if(xAnchor == GUIItem.Left) then
      x = Pos.x
    elseif(xAnchor == GUIItem.Right) then
      x = Size.x+Pos.x
    else
      x = Pos.x+(Size.x/2)
    end

    if(yAnchor == GUIItem.Top) then
      y = Pos.y
    elseif(yAnchor == GUIItem.Bottom) then
      y = Size.y+Pos.y
    else
      y = Pos.y+(Size.y/2)
    end
  end
 
  rec = rec or self.HitRec
   rec[1] = x*UIScale
   rec[2] = y*UIScale
   rec[3] = x+(self.Size.x*UIScale)
   rec[4] = y+(self.Size.y*UIScale)
end
*/

function BaseControl:CreateFontString(fontSizeOrTemplate, anchorPoint, x, y, clipText)
  local font

  if(type(fontSizeOrTemplate) == "number") then
    
    font = GUIManager:CreateTextItem()
    setmetatable(debug.getfenv(font), GUIItemTable)
    
    font:SetFontName("arial")
    font:SetFontSize(fontSizeOrTemplate)
  else
    font = fontSizeOrTemplate:CreateFontString()
    fontSizeOrTemplate = fontSizeOrTemplate.FontSize
  end

  local point

  if(anchorPoint) then
    point = PointToAnchor[anchorPoint]
    font:SetAnchor(point[1], point[2])
  end

  if(x) then
    font:SetPosition(Vector(x, y, 0))
   
    if(clipText) then
      
      if(type(clipText) == "number") then
        font:SetTextClipped(true, clipText, fontSizeOrTemplate)
      else
        local width = self:GetWidth()
        
        if(anchorPoint) then
          if(point[1] == GUIItem.Right) then
            x = (width)+x
          elseif(point[1] == GUIItem.Middle) then
            x = x-(width/2)
          end
        end
      
        font:SetTextClipped(true, width-x, fontSizeOrTemplate)
      end
    end
  end
  
  self:AddGUIItemChild(font)
  
  return font
end

function GUIItemTable:SetFontSize(fontSize)
  self._FontSize = fontSize
  
  GUIItem.SetFontSize(self, fontSize*UIFontScale)
  
  if(self.AnchorPoint1) then
    self:SetPoint(unpack(self.AnchorPoint1))
  end
end

function GUIItemTable:SetText(text)

  GUIItem.SetText(self, text)

  if(self.AnchorPoint1) then
    self:SetPoint(unpack(self.AnchorPoint1))
  end
end

function GUIItemTable:SetPoint(point, x, y, reltivePoint)
  
  
  if(not reltivePoint) then
    reltivePoint = point
  end
  
  if(not x) then
    x,y = 0,0
  end
 
  self.AnchorPoint1 = {point, x, y, reltivePoint}

  
  local point = PointToAnchor[point]
  self:SetAnchor(point[1], point[2])

  --the point a controls position is based off is TopLeft in the ns2 gui system
  if(reltivePoint) then
    local relpoint = PointToAnchor[reltivePoint]
    local width, height
    
    assert(self._FontSize)
    
    //FIXME handle custom sized font strings
    local text = self:GetText()
    
    if(not text or text == "") then 
      width = 1
      height = ScaledGetTextHeight(self, "g")
    else
      width = ScaledGetTextWidth(self, text)
      height = ScaledGetTextHeight(self, text)
    end
    
    if(relpoint[1] == GUIItem.Right) then
      x = (-width)+x
    elseif(relpoint[1] == GUIItem.Middle) then
      x = x-(width/2)
    end
    
    if(relpoint[2] == GUIItem.Bottom) then
      y = (-height)+y
    elseif(relpoint[2] == GUIItem.Center) then
      y = y-(height/2)
    end
  end

  SetPosition(self, Vector(x*UIScale, y*UIScale, 0))
end