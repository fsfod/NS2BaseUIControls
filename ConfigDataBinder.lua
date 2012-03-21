//
//   Created by:   fsfod
//

local TypeToTypeNum = {
  ["string"] = 1,
  number = 2,
  boolean = 3,
  integer = 4,
}

local StringDataType = 1
local FloatDataType = 2
local BoolDataType = 3
local NumberDataType = 4

local GetString, GetFloat, GetBool, GetNumber

local ConfigSetter, ConfigGetter

ConfigDataBind = {}

function ConfigDataBind.OnClientLoadComplete()

  ConfigGetter = {
    Client.GetOptionString,
    Client.GetOptionFloat,
    Client.GetOptionBoolean,
    Client.GetOptionInteger,
  }
  
  ConfigSetter = {
    Client.SetOptionString,
    Client.SetOptionFloat,
    Client.SetOptionBoolean,
    Client.SetOptionInteger,
  }
  
  GetString = Client.GetOptionString
  GetFloat = Client.GetOptionFloat
  GetBool = Client.GetOptionBoolean
  GetNumber = Client.GetOptionInteger
end

if(StartupLoader.ReloadInprogress) then
  ConfigDataBind.OnClientLoadComplete()
end

local TypeDefaults = {
  "",
  0,
  false,
  0,
}



local IndexMT = {
  __index = ConfigDataBind
}

setmetatable(ConfigDataBind, {
  __call = function(self, ...)
    local tbl = setmetatable({}, IndexMT)
      tbl:__init(...)
    return tbl
  end
})

function ConfigDataBind:InitFunction(getter, setter)
  self.GetValue = function() return getter() end
  self.SetValue = function(selfArg, ...) setter(...) end
end

function ConfigDataBind:MulitValueInit(bindingList, converter)

  self.ValueConverter = converter

  local paths, typeNums, defaults = {}, {}, {}
    
  for i,binding in ipairs(bindingList) do
    paths[i] = binding[1]
    defaults[i] = binding[2]
    
    local typeName = binding[3] or type(binding[2])
    
    if(typeName == nil) then
      error(string.format("ConfigDataBind: unable to deduce type for %s because no default or typename were provided", binding[1]))
    end

    local typeNum = TypeToTypeNum[typeName]

    if(typeNum == nil) then  
       
    end

    typeNums[i] = typeNum
  end

  self.Default = defaults
  self.DataType = typeNums
  self.Path = paths
  
  self.MultiValue = true
  self.GetValue = self.MultiGetValue
  self.SetValue = self.MultiSetValue
end

function ConfigDataBind:__init(binding, ...)
    
  if(type(binding) == "function") then
    self:InitFunction(binding, ...)
   return
  end
    
  if(type(binding) == "table" and type(binding[1]) == "table") then
    self:MulitValueInit(binding, ...)
   return
  end
  
  local default, typeName 
  
  if(select('#', ...) == 0) then
    self.Path = binding[1]
    default = binding[2]
    typeName = binding[3] or type(default)
    self.ValueConverter = binding[4]
  else
    self.Path = binding
    default, typeName, self.ValueConverter = ...

    typeName = typeName or type(default)
  end

  if(typeName == nil) then
    error(string.format("ConfigDataBind: unable to deduce type for %s because no default or typename were provided", self.Path))
  end
 
  local typeNum = TypeToTypeNum[typeName]
  
  if(typeNum == nil) then
    error(string.format("ConfigDataBind: %s is an invalid or unsupported type name", typeName))
  end
  
  self.DataType = typeNum  
  self.Default = default or TypeDefaults[typeNum]
end

function ConfigDataBind:SetConverter(converter)
  self.ValueConverter = converter
  
  return self
end

function ConfigDataBind:SetDelaySave(enable)
  self.DelaySave = enable
 return self
end

function ConfigDataBind:GetValue()
  
  local getter = ConfigGetter[self.DataType]
  local value = getter(self.Path, self.Default)
  
  local converter = self.ValueConverter
  
  if(converter) then
    return converter(value)
  else
    return value
  end
end

function ConfigDataBind:ResetToDefault()

  local default = self.Default

  self.DelayValue = nil
  self:InternalSetValue(default)

  if(self.Owner) then
    if(converter) then
      self.Owner:ConfigValueChanged(converter(default))
    else
      self.Owner:ConfigValueChanged(default)
    end
  end
end

function ConfigDataBind:SetValidator(validator)
  assert(type(validator) == "function")
  
  self.Validator = validator
  
  return self
end

function ConfigDataBind:SetValue(...)

  if(self.Validator and not self.Validator(...)) then
    return
  end
  
  local converter = self.ValueConverter
  local value
  
  if(converter) then
    value = converter(...)
  else
    value = ...
  end
 
  assert(value ~= nil)

  if(self.DelaySave) then
    self.DelayValue = value
  else
    self:InternalSetValue(value)
  end  
end

function ConfigDataBind:InternalSetValue(value)

  local setter

  if(type(value) == "string") then
    setter = Client.SetOptionString
  elseif(type(value) == "number") then
    setter = Client.SetOptionFloat
  elseif(type(value) == "boolean") then
    setter = Client.SetOptionBoolean 
  else
    error("invalid type for config binding")
  end

  setter(self.Path, value)
end



function ConfigDataBind:MultiGetValue()

  local values = {}

  for i,path in ipairs(self.Path) do
    values[i] = ConfigGetter[self.DataType[i]](path, self.Default[i])
  end

  if(self.ValueConverter) then
    return self.ValueConverter(unpack(values))
  else
    return unpack(values)
  end
end

function ConfigDataBind:MultiSetValue(...)

  if(self.Validator and not self.Validator(...)) then
    return
  end

  if(self.ValueConverter) then
    if(self.DelaySave) then
      self.DelayValue = {self.ValueConverter(...)}
    else
      self:InternalMultiSetValue(self.ValueConverter(...))
    end
  else
    if(self.DelaySave) then
      self.DelayValue = {...}
    else
      self:InternalMultiSetValue(...)
    end
  end
end

function ConfigDataBind:SaveStoredValue()

  if(self.DelayValue ~= nil) then
    if(self.MultiValue) then
      self:InternalMultiSetValue(unpack(self.DelayValue))
    else
      self:InternalSetValue(self.DelayValue)
    end
    self.DelayValue = nil
  end
end

function ConfigDataBind:InternalMultiSetValue(...)

  for i,path in ipairs(self.Path) do
    ConfigSetter[self.DataType[i]](path, (select(i, ...)))
  end
end