//
//   Created by:   fsfod
//

ControlClass('TextBox', BorderedSquare)

TextBoxMixin = {}


local Space = string.byte(" ", 1)

function TextBox:Initialize(width, height, fontsize, fontname)
  BorderedSquare.Initialize(self, width, height, 2)
  
  TextBoxMixin.Initialize(self, fontsize, fontname)

end

function TextBoxMixin:MixIn(classTable)

  for k,v in pairs(self) do
    classTable[k] = v
  end
end

function TextBoxMixin:Initialize(fontsize, fontname)

  assert(self.TextOffset, "TextOffset needs tobe set before calling TextBoxMixin:Initialize")

  self:AddFlag(ControlFlags.Focusable)

  self.CarretPos = 0
  
  self:SetBackgroundColor(Color(0.06,0.06,0.06, 0.8))
    
  self.FontSize = fontsize or 20
  
  local text = self:CreateFontString(self.FontSize)
   text:SetPosition(self.TextOffset)
   text:SetTextAlignmentX(GUIItem.Align_Min)
   text:SetTextAlignmentY(GUIItem.Align_Center)
   text:SetAnchor(GUIItem.Left, GUIItem.Center)
   
   if(fontname) then
    text:SetFontName(fontname)
   end
  
  self.CarretOffset = self.TextOffset+Vector(0, 3, 0)
  
  local carret = self:CreateGUIItem()
   carret:SetIsVisible(false)
   carret:SetSize(Vector(2, self.FontSize-2, 0))
   carret:SetPosition(self.CarretOffset)
   carret:SetColor(Color(1,0,0, 1))
  self.Carret = carret
   
  self.Text = text
  
  local w1 = text:GetTextWidth("oo")
  local w2 = text:GetTextWidth("o o")
  
  self.SpaceSize = w2-w1 
end

function TextBoxMixin:SetFont(fontname)
  self.Text:SetFontName(fontname)
  
  local w1 = self.Text:GetTextWidth("oo")
  local w2 = self.Text:GetTextWidth("o o")
  
  self.SpaceSize = w2-w1 
  
  self:UpdateCarret()
end

function TextBoxMixin:CopyToClipboard()
  local text = self:GetText()

  if(text and text ~= "") then
    SetClipboardString(text)
  end
end

function TextBoxMixin:OnPaste(pastText)
  self:InsertText(pastText)

  self:FireEvent(self.TextChanged, self:GetText())
end

function TextBoxMixin:OnFocusGained()
  self.Carret:SetIsVisible(true)
end

function TextBoxMixin:SetFocus()
  self:GetGUIManager():SetFocus(self)
end

function TextBoxMixin:OnFocusLost()
  self.Carret:SetIsVisible(false)
  
  if(self.ConfigBinding) then
    self.ConfigBinding:SetValue(self.Text:GetText())
  end
  
  self:FireEvent(self.FocusLost)
end

function TextBoxMixin:SetValueFromConfig()
  self:SetText(self.ConfigBinding:GetValue())
end

function TextBoxMixin:ConfigValueChanged(text)
  self:SetText(text)
end

function TextBoxMixin:GetText()
  return self.Text:GetText()
end

function TextBoxMixin:GetWideText()
  return self.Text:GetWideText()
end
  
function TextBoxMixin:ClearText()
  self.Text:SetText("")
  self.CarretPos = 0
  self:UpdateCarret()
end

function TextBoxMixin:SetText(value)

  self.Text:SetText((value ~= nil and tostring(value)) or "")
  
  self.CarretPos = self.Text:GetWideText():length()
  
  self:UpdateCarret()
end

function TextBoxMixin:GetTextWidth(endIndex)
  
  local text = self.Text:GetWideText()
  
  if(endIndex) then
    text = text:sub(1, text:length()-endIndex)
  end
  
  return self.Text:GetTextWidth(text)
end

function TextBoxMixin:SendCharacterEvent(character)

  if(InputKeyHelper:ShouldIgnoreChar(character)) then
    return false
  end
  
  self:InsertChar(character)
  self:FireEvent(self.TextChanged, self:GetText())
  
 return true
end

function TextBoxMixin:UpdateCarret()
  local text = self.Text:GetText()
  local currentText = self.Text:GetWideText()
  local currentTextLength = currentText:length()
  local offset
  
  if(self.CarretPos ~= currentTextLength) then
     local tempText = text:sub(1, self.CarretPos)//currentText:sub(1, self.CarretPos) no way to get the width of wide text or convert a 
     offset = self.Text:GetTextWidth(tempText)
     
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

  self.Carret:SetPosition(self.CarretOffset+Vector(offset, 0, 0))
end

function TextBoxMixin:InsertText(insertText)
  local currentText = self.Text:GetText()
  local currentTextLength = #currentText
  
  if(self.CarretPos == currentTextLength) then
    currentText = currentText..insertText
  elseif(self.CarretPos == 0) then
    currentText = insertText..currentText
  else
   local front = currentText:sub(1, self.CarretPos)
   local back = currentText:sub(self.CarretPos+1, currentTextLength)
       
    currentText = front..insertText..back
  end
   
  self.Text:SetText(currentText)

  self.CarretPos = self.CarretPos+#insertText
  
  self:UpdateCarret()
end

function TextBoxMixin:InsertChar(char)
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

function TextBoxMixin:DeleteChar(index)
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

function TextBoxMixin:SendKeyEvent(key, down)
  
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
        
        self:FireEvent(self.TextChanged, self:GetText())
      end
    elseif(key == InputKey.Delete) then
      if CharCount > 0 and self.CarretPos ~= CharCount then
        self:DeleteChar(self.CarretPos+1)
        
        self:FireEvent(self.TextChanged, self:GetText())
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
    elseif((key == InputKey.Return or key == InputKey.NumPadEnter)and not self.IgnoreReturn) then
      if(self.Focused) then
        self:GetGUIManager():ClearFocus()
      end
    elseif key == InputKey.Escape then
      if(self.Focused) then
        self:GetGUIManager():ClearFocus()
      end
    else
      return false
    end
    
    return true
  end

  return false
end

function TextBoxMixin:TryParseNumber(oldValue, min, max)

  local sucess, result = pcall(tonumber, self:GetText())
  
  if(not sucess or not result or (min and result < min) or (max and result > max)) then

    sucess = false
    
    if(oldValue) then
      self:SetText(tostring(oldValue))
    end
  end
  
  return sucess and result
end