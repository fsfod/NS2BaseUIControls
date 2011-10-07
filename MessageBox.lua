ControlClass('MessageBox', BaseWindow)

function MessageBox:__init(title, message)
  BaseWindow.__init(self, 600, 120, "")

  self.DestroyOnClose = true

  local titleText = self:CreateFontString(20, "Top", 0, 4)
    titleText:SetTextAlignmentX(GUIItem.Align_Center)
    titleText:SetText(title)
  self.Title = titleText

  local msgString = self:CreateFontString(17, "Top", 0, 30)
    msgString:SetTextAlignmentX(GUIItem.Align_Center)
    msgString:SetText(message or "some long really long error message no longer and longer still not long enough")
  self.MsgString = msgString
  
  self.CloseAction = {self.Close, self}
  
  local okButton = UIButton("OK")
   okButton:SetPoint("Bottom", 0, -10, "Bottom")
   okButton.ClickAction = self.CloseAction
  self:AddChild(okButton)
  self.OKButton = okButton
  
  if(false) then
    
    local cancelButton = UIButton("Cancel")
     cancelButton:SetPoint("Bottom", -100, -10, "Bottom")
     cancelButton.ClickAction = self.CloseAction
     cancelButton:Hide()
    self:AddChild(cancelButton)
    self.CancelBtn = cancelButton
  end
  
  if(false) then

    local textBox = TextBox(150, 20, 19)
      textBox:SetPoint("Right", -30, 0, "Right")
      textBox:Hide()
    self:AddChild(textBox)
    self.TextBox = textBox
  end
  
  
  self.Mode = "SimpleMsg"  
end

function MessageBox:Open(mode, modeData)
  self:SetMode(mode, modeData)
  self:Show()
end

function MessageBox:SetMode(mode, modeData)

  if(mode == "SimpleMsg") then
    self.MsgString:SetIsVisible(true)
    self.CancelBtn:Hide()
    self.TextBox:Hide()
    
    self.MsgString:SetText(modeData)
    
    self.OKButton.ClickAction = self.CloseAction
  else
    self.MsgString:SetIsVisible(false)
    self.CancelBtn:Show()
    self.TextBox:Show()
  end

end