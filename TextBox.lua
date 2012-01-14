//
//   Created by:   fsfod
//

ControlClass('TextBox', BorderedSquare)

TextBoxMixin:MixIn(TextBox)

TextBox.TextOffset = Vector(4, 0, 0)

function TextBox:Initialize(width, height, fontsize, fontname)
  BorderedSquare.Initialize(self, width, height, 2) 
  
  if(not fontsize) then
    fontsize = height-4
  end
  
  TextBoxMixin.Initialize(self, fontsize, fontname)

end