class 'TextBox'(BorderedSquare)

local Space = string.byte(" ", 1)

function TextBox:__init(width, height, fontsize, fontname)
  BorderedSquare.__init(self, width, height, 2)
  
  self.CarretPos = 0
  
  self:SetBackgroundColor(Color(0.06,0.06,0.06, 0.8))
  
  local carret = GUIManager:CreateGraphicItem()
   carret:SetIsVisible(false)
   carret:SetSize(Vector(1, height-4, 0))
   carret:SetPosition(Vector(5, 2, 0))
   carret:SetColor(Color(1,0,0, 1))
   self.RootFrame:AddChild(carret)
  self.Carret = carret
  
  self.FontSize = fontsize or 20
  
  local text = self:CreateFontString(self.FontSize)
   text:SetPosition(Vector(5, 1, 0))
   text:SetTextAlignmentX(GUIItem.Align_Min)
   text:SetTextAlignmentY(GUIItem.Align_Center)
   text:SetAnchor(GUIItem.Left, GUIItem.Center)
   
   if(fontname) then
    text:SetFontName(fontname)
   end
   
  self.Text = text
  
  local w1 = text:GetTextWidth("oo")
  local w2 = text:GetTextWidth("o o")
  
  self.SpaceSize = w2-w1 
end

function TextBox:OnClick()
end

function TextBox:SetFont(fontname)
  self.Text:SetFontName(fontname)
  
  local w1 = self.Text:GetTextWidth("oo")
  local w2 = self.Text:GetTextWidth("o o")
  
  self.SpaceSize = w2-w1 
  
  self:UpdateCarret()
end

function TextBox:OnFocusGained()
  self.Carret:SetIsVisible(true)
end

function TextBox:SetFocus()
  GetGUIManager():SetFocus(self)
end

function TextBox:OnFocusLost()
  self.Carret:SetIsVisible(false)
  
  if(self.ConfigBinding) then
    self.ConfigBinding:SetValue(self.Text:GetText())
  end
  
  self:FireEvent(self.FocusLost)
end

function TextBox:SetValueFromConfig()
  self:SetText(self.ConfigBinding:GetValue())
end

function TextBox:ConfigValueChanged(text)
  self:SetText(text)
end

function TextBox:GetText()
  return self.Text:GetText()
end

function TextBox:ClearText()
  self.Text:SetText("")
  self.CarretPos = 0
  self:UpdateCarret()
end

function TextBox:SetText(text)
  self.Text:SetText(text)
  
  self.CarretPos = self.Text:GetWideText():length()
  
  self:UpdateCarret()
end

function TextBox:GetTextWidth(endIndex)
  
  local text = self.Text:GetWideText()
  
  if(endIndex) then
    text = text:sub(1, text:length()-endIndex)
  end
  
  return self.Text:GetTextWidth(text)
end

function TextBox:SendCharacterEvent(character)
  self:InsertChar(character)
  self:FireEvent(self.TextChanged)
 return true
end

function TextBox:UpdateCarret()
  local text = self.Text:GetText()
  local currentText = self.Text:GetWideText()
  local currentTextLength = currentText:length()
  local offset
  
  if(self.CarretPos ~= currentTextLength) then
     local tempText = currentText:sub(1, self.CarretPos)
     self.Text:SetWideText(tempText)
     
     offset = self.Text:GetTextWidth(text)
     
     self.Text:SetWideText(currentText)
  else
    
    offset = self.Text:GetTextWidth(text)
    
    if(string.byte(text, #text) == Space) then
      for i = #text,1,-1 do
        if(string.byte(text, i) == Space) then
          offset = offset+self.SpaceSize
        else
          break
        end
      end
    end
  end
  
  
  self.Carret:SetPosition(Vector(offset+5, 2, 0))
end

function TextBox:InsertChar(char)
	local currentText = self.Text:GetWideText()
  local currentTextLength = currentText:length()
  
  if(self.CarretPos == currentTextLength) then
    currentText = currentText..char
  elseif(self.CarretPos == 0) then
    currentText = char..currentText
  else
   local front = currentText:sub(1, self.CarretPos)
   local back = currentText:sub(self.CarretPos+1, currentTextLength)
       
    currentText = front..char..back
  end
   
  self.Text:SetWideText(currentText)
  
  self.CarretPos = self.CarretPos+1
  
  self:UpdateCarret()
end

function TextBox:DeleteChar(index)
	local currentText = self.Text:GetWideText()
  local currentTextLength = currentText:length()
  
  if(index == currentTextLength) then
    currentText = currentText:sub(1, currentTextLength - 1)
  elseif(index == 1) then
    currentText = currentText:sub(2, currentTextLength)
  else
   local front = currentText:sub(1, index-1)
   local back = currentText:sub(index+1, currentTextLength)
        
   currentText = front..back
  end
   
  self.Text:SetWideText(currentText)
end

function TextBox:SendKeyEvent(key, down)
  
  if(key == InputKey.MouseX or key == InputKey.MouseY) then
    return false
  end

  if down then
    local CharCount = self.Text:GetWideText():length()
    
    if key == InputKey.Back then
      if CharCount > 0 and self.CarretPos ~= 0 then
        self:DeleteChar(self.CarretPos)
        
        self.CarretPos = self.CarretPos-1
         
        self:UpdateCarret()
        
        self:FireEvent(self.TextChanged)
      end
    elseif(key == InputKey.Delete) then
      if CharCount > 0 and self.CarretPos ~= CharCount then
        self:DeleteChar(self.CarretPos+1)
        
        self:FireEvent(self.TextChanged)
      end
		elseif(key == InputKey.Left) then
			if(self.CarretPos > 0) then
				self.CarretPos = self.CarretPos-1
			end
			self:UpdateCarret()
    elseif key == InputKey.Right then
			if(self.CarretPos < CharCount) then
				self.CarretPos = self.CarretPos+1
			end
			self:UpdateCarret()
    elseif(key == InputKey.Return and not self.IgnoreReturn) then
      if(self.Focused) then
        GetGUIManager():ClearFocus()
      end
    elseif key == InputKey.Escape then
      if(self.Focused) then
        GetGUIManager():ClearFocus()
      end
    else
      return false
    end
    
    return true
  end

  return false
end