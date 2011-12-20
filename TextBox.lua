//
//   Created by:   fsfod
//

ControlClass('TextBox', BorderedSquare)

TextBoxMixin:MixIn(TextBox)

TextBox.TextOffset = Vector(4, 2, 0)

function TextBox:Initialize(width, height, fontsize, fontname)
  BorderedSquare.Initialize(self, width, height, 2) 
  TextBoxMixin.Initialize(self, fontsize, fontname)

end