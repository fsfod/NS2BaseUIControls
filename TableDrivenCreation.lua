
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