local IsALookUp = {}
local ClassBase = {}

local ClassMetaTable = {}
local InstanceMT = {}
local ClassTable = {}


local GUIItemTable, BaseMT

local CreateItem = GUI.CreateItem

function ExtractGUIItemTables()
  
  GUIItemTable = {}

  for name, v in pairs(GUIItem) do
    if(type(v) == "function") then
      GUIItemTable[name] = v
    end
  end

  local c = CreateItem()

  BaseMT = {}

  for k, v in pairs(debug.getmetatable(c)) do
    BaseMT[k] = v
  end
  
  BaseMT.__tostring = nil
  
  GUI.DestroyItem(c)
  
  _G.GUIItemTable = GUIItemTable
end

ExtractGUIItemTables()

local function SetupInstanceMetaTable(className)
  
  local mt = {
    Class = className,
  }
  
  for k,v in pairs(BaseMT) do
    mt[k] = v
  end

  /*
  if(true) then
    mt.__index = function(self, key) 
      local env = debug.getfenv(self)

      return env[key] or getmetatable(env)[key]
    end
  end
*/
  mt.__towatch = function(self) return debug.getfenv(self) end
  mt.__tostring = function() return className end

  InstanceMT[className] = mt  
end

function CreateControl(name)

  local item = GUI.CreateItem()

  setmetatable(debug.getfenv(item), _G[name])
  
  debug.setmetatable(item, InstanceMT[name])

  //setmetatable(debug.getfenv(item), nil)
  //debug.setmetatable(item, ClassMetaTable[name])
  
  return item
end

local function CallMeta(self, ...)
  assert(false, getmetatable(self).Class)
end

local function CopyInBaseFunctions(indexTable, baseName)
  
  if(baseName) then

    local baseBaseTbl = ClassBase[baseName]
    
    //merge our base table with its base table so a table lookup don't need 2+ __index calls  
    if(baseBaseTbl) then
    
      for funcname,func in pairs(baseBaseTbl) do
        indexTable[funcname] = func
      end
    end

    --copy in our base class table
    for k,v in pairs(_G[baseName]) do
      indexTable[k] = v
    end
  else

    for funcname,func in pairs(GUIItemTable) do
      indexTable[funcname] = func
    end
  end
end

local function RecreateClass(className, base)

  Shared.Message("Recreateing class "..className)

  local t = _G[className]

  assert(not base or ClassBase[t] == ClassTable[base])
  
  local isa = t.isa
  
  for k,v in pairs(t) do
    t[k] = nil
  end

  CopyInBaseFunctions(t, base)

  t.isa = isa
end

function ControlClass(className, base)

  local baseName

  if(base) then
    baseName = ClassTable[base]
    
    assert(base, "ControlClass: Base class does not exist")
  end

  //if class already exists treat this as a hot reload just clear and rebuild the index table
  //TODO propergating the changes to derived class's
  if(IsALookUp[className]) then
    RecreateClass(className, baseName)
   return
  end

  local indexTable = {}
  local mt = {__call = CallMeta, Class = className, Base = baseName}

  SetupInstanceMetaTable(className)

  setmetatable(indexTable, mt)

  ClassTable[indexTable] = className
  _G[className] = indexTable
 
  ClassBase[className] = base or false

  local isaTable = {}
  isaTable[className] = true

  IsALookUp[className] = isaTable

  CopyInBaseFunctions(indexTable, baseName)

  if(not base) then
    indexTable.isa = function(self, name) return name == className end
   
   return
  end

  local baseIsA = IsALookUp[baseName]

  for k,_ in pairs(baseIsA) do
    isaTable[k] = true
  end

  isaTable[baseName] = true

  indexTable.isa = function(self, name) return isaTable[name] ~= nil end
end

ControlClass("TestControl")

function TestControl:SetPosition(pos)
  assert(pos)

  GUIItem.SetPosition(self, pos)
end

local c = CreateControl("TestControl")

c.test = true

local g = GUI.CreateItem()
g.Parent = c

c:AddChild(g)

assert(g.Parent == g:GetParent())

local DestroyedIndex = {
  SetPosition = function() 
    RawPrint("SetPosition called on destroyed control")
  end,
  SetSize = function()
    RawPrint("SetSize called on destroyed control")
  end,
  SetIsVisible = function()
    RawPrint("SetIsVisible called on destroyed control")
  end,
  SetColor = function()
    RawPrint("SetColor called on destroyed control")
  end,

  GetPosition = function() return Vector(0, 0, 0) end,
  GetSize = function() return Vector(1, 1, 0) end,
  GetIsVisible = function() return false end,
  __Destroyed = true,
}

local destroyedMT = {

  __index = function(self, key) 
    local env = debug.getfenv(self)
    local result = DestroyedIndex[key] or env[key]
    
    if(result == nil) then
      return getmetatable(env)[key]
    end
    
    return result
  end,
  
  __newindex =  function(self, key, value)
    debug.getfenv(self)[key] = value
  end,

  __gc = BaseMT.__gc,
}

function SetControlDestroyed(control) 
  debug.setmetatable(control, destroyedMT)
end

function IsValidControl(control)
  return control and not control.__Destroyed
end
