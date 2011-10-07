local IsALookUp = {}
local ClassBase = {}

local ClassMetaTable = {}
local InstanceMT = {}
local ClassTable = {}


local GUIItemTable, BaseMT

local CreateItem = GUI.CreateItem

function ExtractGUIItemTables()
  
  GUIItemTable = {__init = function() end}

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
end

ExtractGUIItemTables()

local function SetupInstanceMetaTable(className)
  
  local mt = {__tostring = function() return className end, Class = className}
  
  for k,v in pairs(BaseMT) do
    mt[k] = v
  end

  InstanceMT[className] = mt
end

function CreateControl(name)

  local item = GUI.CreateItem()

  setmetatable(debug.getfenv(item), _G[name])

  //setmetatable(debug.getfenv(item), nil)
  //debug.setmetatable(item, ClassMetaTable[name])
  
  return item
end

function CallMeta(self, ...)
  
  local item = GUI.CreateItem()

  setmetatable(debug.getfenv(item), self)

  item:__init(...)

  return item
end

function ControlClass(className, base)

  local baseName

  if(base) then
    baseName = ClassTable[base]
    
    assert(base, "ControlClass: Base class does not exist")
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
  

  if(not base) then
    for funcname,func in pairs(GUIItemTable) do
      indexTable[funcname] = func
    end
    
    indexTable.isa = function(self, name) return name == className end
   
   return
  end
  
  local baseBaseTbl = ClassBase[base]

  //merge our base table with its base table so a table lookup don't need 2+ __index calls  
  if(baseBaseTbl) then

    for funcname,func in pairs(baseBaseTbl) do
      indexTable[funcname] = func
    end
  end
    
  --copy in our base class table
  for k,v in pairs(base) do
    indexTable[k] = v
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

local c = TestControl()

c.test = true

local g = GUI.CreateItem()
g.Parent = c

c:AddChild(g)

assert(g.Parent == g:GetParent())

