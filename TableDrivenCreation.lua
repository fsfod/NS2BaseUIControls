
local EventOption, Optional

if(not _G.EventOption) then
  EventOption = {}
  _G.EventOption = EventOption
  
end

local function ResolveToEventReciver(value, object)
  
  if(type(value) == "function") then
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
  
  return value
end

local function ResolveNameToFunction(name, object)
  
  assert(name)
  assert(type(name) == "string", "d")
  
  local funct = object[name]
  
  if(funct) then
    if(type(funct) ~= "function") then
      error("")
    end
    
    return function(...)
      local f = object[name]
      
      return f(object, ...)
    end
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

function ResolveToFunction(value, object)

  if(type(value) == "function") then
    return value
  end
  
  if(type(value) ~= "string") then
    error("expected a function or string that resolved to a function")
  end
  
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
    end  
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
      assert(type(position) == "userdata")
       
      frame:SetPosition(position)
    end
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
  
  local databind = options.ConfigDatabind
  
  if(databind) then
    frame:SetConfigBinding(databind.ConfigPath, databind.DefaultValue, databind.ValueType, databind.ValueConverter)
  end
end