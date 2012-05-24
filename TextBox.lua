//
//   Created by:   fsfod
//

ControlClass('TextBox', BorderedSquare)

TextBoxMixin:MixIn(TextBox)

TextBox.TextOffset = Vector(4, 0, 0)

TextBox:SetDefaultOptions{
  Width = 80,
  Height = 20,
}

function TextBox:InitFromTable(options)
  
  self.Height = options.Height
  
  BorderedSquare.Initialize(self, options.Width, self.Height, 2) 
  
  self.FontSize = options.FontSize or (self.Height-4)  
  self.FontName = options.FontName
  
  TextBoxMixin.Initialize(self, self.FontSize, self.FontName)
end

function TextBox:Initialize(width, height, fontsize, fontname)
  BorderedSquare.Initialize(self, width, height, 2) 
  
  if(not fontsize) then
    fontsize = height-4
  end
  
  TextBoxMixin.Initialize(self, fontsize, fontname)

end