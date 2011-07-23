class'MessageBox'(BorderedSquare)

function MessageBox:__init()
  BorderedSquare.__init(self, 600, 100, 4)

  local msgString = self:CreateFontString(19, "Top", 0, 20)
    msgString:SetTextAlignmentX(GUIItem.Align_Center)
    msgString:SetText("some long really long error message no longer and longer still not long enough")
  self.MsgString = msgString
  
  self.CloseAction = {self.Close, self}
  
  local okButton = UIButton("OK")
   okButton:SetPoint("Bottom", 0, -10, "Bottom")
   okButton.ClickAction = self.CloseAction
  self:AddChild(okButton)
  self.OKButton = okButton
  
  local cancelButton = UIButton("Cancel")
   cancelButton:SetPoint("Bottom", -100, -10, "Bottom")
   cancelButton.ClickAction = self.CloseAction
   cancelButton:Hide()
  self:AddChild(cancelButton)
  self.CancelBtn = cancelButton
  
  
  local textBox = TextBox(150, 20, 19)
    textBox:SetPoint("Right", -30, 0, "Right")
    textBox:Hide()
  self:AddChild(textBox)
  self.TextBox = textBox
  
  
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

function MessageBox:Close()
  if(not self.Hidden) then
    self:Hide()
    GUIMenuManager:MesssageBoxClosed(self)
  end
end