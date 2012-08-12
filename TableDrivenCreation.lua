
local EventOption, Optional

if(not _G.EventOption) then
  EventOption = {}
  _G.EventOption = EventOption
  
end

if(not _G.OptionalValue) then
  _G.OptionalValue = {}
end

function ResolveToEventReceiver(value, object)
  
  if(not value or type(value) == "function") then
    return value
  end
  
  if(type(value) == "table") then
    if(#value == 2) then
      
      return value
    end
    
    error("only a table with 2 values is supported for a event atm")
  end
  
  local name = value

//TODO Decide if it even makes sense to have this option
/* 
  value = object[name]

  if(value) then
    //treated as a self call function
    return {value, object}
  end 
*/

  value = object.Parent[name]

  if(value) then
    //treated as a self call function
    return {value, object.Parent}
  end
    
  error("invalid event receiver "..name)
end

function ResolveToFunction(value, object)
  
  if(not value or type(value) == "function") then
    return value
  end
  
  if(type(value) ~= "string") then
    error("ResolveToFunction: expected a function or string that resolved to a function")
  end
    
  return ResolveNameToFunction(value, object)
end

function ResolveToNumber(value, object)
  
  local valueType = type(value)
  
  if(not value or valueType == "number") then
    return value
  end
  
  if(valueType == "string") then
    local result = _G[value]
  
    if(result and type(result) == "number") then
      return result
    end
  end
    
  if(valueType ~= "string" and valueType ~= "function") then
    error("ResolveToNumber: expected a function or string that resolved to a number")
  end

  return ResolveAndCallFunction(value, object)
end

local function TryGetMemberFunction(object, key)

  local func = object[key]
  
  if(func) then
    if(type(func) ~= "function") then
      error("TryGetMemberFunction: Expected member "..key.." tobe a function")
    end
    
    return function(...)
      local f = object[key]
      
      return f(object, ...)
    end
  end
  
  return nil
end

function ResolveNameToFunction(name, object)
  
  assert(name)
  assert(type(name) == "string", "d")
  
  local func = TryGetMemberFunction(object, name) or TryGetMemberFunction(object.Parent, name) 
  
  if(func) then
    return func  
  end
  
  funct = _G[name]
  
  if(not funct or type(funct) ~= "function") then
    
  end
  
end

local function GetTableFromFunction(func, name, ...)
  
  //TODO decide if we should pcall this and return nil or an empty table if it trigged an error
  local result = func(...)
    
  if(type(result) ~= "table") then
    error(string.format("expected a table tobe returned from %s but got a %s ", name, type(result)))
  end
    
  return result
end

function ResolveAndCallFunction(value, object, ...)

  if(type(value) == "function") then
    return value(...)
  end
  
  local name = value

  if(type(name) ~= "string") then
    error("expected a function or string that resolved to a function")
  end

//TODO Decide if it even makes sense to have this option
/* 
  value = object[name]

  if(value) then
    //treated as a self call function
    return {value, object}
  end 
*/

  value = object.Parent[name]

  if(value) then
    if(type(value) ~= "function") then
      error(string.format("expected a member varible %s tobe a function ", name))
    end
    
    //treated as a self call function
    return value(object.Parent, ...)
  end

  if(type(value) ~= "string") then
    error("expected a function or string that resolved to a function")
  end
    
  error("NYI or invalid event receiver")
end

function ResolveToTable(value, object)
  
  assert(value)
 
  if(type(value) == "table") then
    return value
  end  
  
  if(type(value) == "function") then
    return GetTableFromFunction(value)
  end
  
  if(type(value) ~= "string") then
    error("expected a table or string/function that resolved to a table")
  end
  
  local name = value

  value = object[name]
  
  if(value) then
    
    if(type(value) == "table") then
      return value
    end
    
    if(type(value) ~= "function") then
      error(string.format("expected a function but found a %s for field %s", type(value), name))
    end
    
    //assume that the function is self call style
    return GetTableFromFunction(value, name, object)
  end
  
  //try fetching the table or s function(that returns a table) from the global table
  value = _G[name]
  
  if(type(value) == "table") then
    return value
  end
  
  if(type(value) ~= "function") then
    error(string.format("expected a function or table but found a %s for global %s", type(value), name))
  end
  
  return GetTableFromFunction(value, name)
end

function CreatControlFromTable(parentFrame, options)

  local control = parentFrame:CreateControlFromTable(options)

  CreatChildControlsFromTable(control, options)
    
  return control
end

function CreatChildControlsFromTable(parentFrame, options)

    //this frame has no child controls to create so just return
  if(not options.ChildControls) then
    return
  end
  
  //TODO check if unnamed controls are created before named ones
  for name,subControlOptions in pairs(options.ChildControls) do
    
    local subControl = CreatControlFromTable(parentFrame, subControlOptions)
    
    if(type(name) == "string") then
      parentFrame[name] = subControl
      subControl.Name = name
    end  
  end
end

function GetSizeForTableOptions(options, parent, control)

  if(options.Point2) then
    local width, height
    
    local anchor1 = options.Position
    local anchor2 = options.Point2
    
    local point1 = PointToAnchor[anchor1[1]]
    local point2 = PointToAnchor[anchor2[1]]
    
    if(not WidthUnchangedPoint[point1]) then
      width = CalcSizeFromPoints(point1[1], point2[1], anchor1[2] or 0, anchor2[2] or 0, parent.Size.x)
    end
  
    if(not HeightUnchangedPoint[point2]) then
      height = CalcSizeFromPoints(point1[2], point2[2], anchor1[3] or 0, anchor2[3] or 0, parent.Size.y)
    end
    
    return width or options.Width, height or options.Height
  else
    return options.Width, options.Height
  end
  
end

function ApplySharedControlOptions(frame, options)

  if(not frame.InitFromTable and options.Width) then
    frame:SetSize(options.Width, options.Height)
  end

  local position = options.Position

  if(position) then
   
    if(type(position) == "table") then
      frame:SetPoint(unpack(position))
    else
      //assert(type(position) == "userdata")
       
      frame:SetPosition(position)
    end
  end
  
  if(options.Point2) then
    frame:SetPoint2(unpack(options.Point2))
  end
  
  local label = options.Label

  //TODO unify setlabel of checkbox
  if(label and not frame:isa("CheckBox")) then
    if(type(label) == "string") then
      frame:SetLabel(label)
    else
      frame:SetLabel(unpack(label))
    end
  end
  
  local color = options.Color

  if(color) then
    frame:SetColor(color)
  end
  
  local databind = options.ConfigDataBind
  
  if(databind) then
    
    if(not databind.TriggerChange) then
      frame:SetConfigBinding(databind)
    else
      frame:SetConfigBindingAndTriggerChange(databind)
    end
    
  end
end

function RestoreSavedOptions(control, optionTable, restoreFunction)
  
  restoreFunction = restoreFunction or optionTable.RestoreSavedOptions
  
  assert(restoreFunction)
  
  local savedOptions, nameList = ResolveAndCallFunction(restoreFunction, control)
  
  if(nameList) then
    
    for i,name in ipairs(nameList) do
      optionTable[name] = savedOptions[name]
    end
  else
    
    for name,value in pairs(savedOptions) do
      optionTable[name] = value
    end
  end
end

function MergControlSetupList(existingOptions, extraOptions)
  
  for name,entry in pairs(extraOptions) do
    
    local existingEntry = existingOptions[name]
    
    if(existingEntry) then
      
      if(type(existingEntry) ~= "table") then
        existingEntry[name] = entry
      else
        MergControlSetupList(existingEntry, entry)
      end
    else
      //the key was not in the existing table so add this entry even if its a table
      existingEntry[k] = entry
    end
  end
  
end