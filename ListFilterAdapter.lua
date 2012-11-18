
ListFilterAdapter = {}

local mt = {
  __index = ListFilterAdapter
}


function ListFilterAdapter.Create(filterList)
  local instance = {
    RegistedFilters = {},
    ActiveFilters = {},
    SingleFilters = {},
    SingleExcludeFilters = {},
  }
  
  if(filterList) then
    for name,filterGenerator in pairs(filterList) do
      instance.RegistedFilters[name] = filterGenerator
    end
  end
  
  setmetatable(instance, mt)
  
  return instance
end

function ListFilterAdapter:GetFilteredList()
  assert(self.UnfilteredList and self.FilteredList) 
  return self.FilteredList
end

function ListFilterAdapter:SetList(list)

  self.UnfilteredList = list

  //its much faster to just throw away the old list instead of clearing it  
  self.FilteredList = self:FilterList(self.UnfilteredList)
  self:FilteredListChanged()
end

function ListFilterAdapter:RegisterFilter(name, filterCreator) 
  self.RegistedFilters[name] = filterCreator
end

function ListFilterAdapter:SetFilterAndFilterExisting(filterName, ...)
  self:_SetFilter(filterName, ...)
  
  self.FilteredList = self:FilterList(self.FilteredList)
  
  if(self.ListChangedCallback) then
    self.ListChangedCallback(self.FilteredList)
  end
end
  
function ListFilterAdapter:SetSingleFilter(filterName, ...)
  
  self.SingleFilters[filterName] = self:CreateFilter(filterName, ...)
  
  self:FiltersChanged()
end

function ListFilterAdapter:SetFilterNoListUpdate(filterName, ...)
  self:_SetFilter(filterName, ...)
end

function ListFilterAdapter:_SetFilter(filterName, ...)
  
end

function ListFilterAdapter:CreateFilter(filterName, ...)
  local filterCreator = self.RegistedFilters[filterName]
  
  assert(filterCreator, "No filter named "..filterName.." registered")
  
  local filter = filterCreator(...)
  
  assert(type(filter) == "function", "CreateFilter: Error filter creator function did not return a function")
  
  return filter
end

function ListFilterAdapter:RemoveSingleFilter(filterName)
  
  local filter = self.SingleFilters[filterName]
  
  if(not filter) then
    return
  end
  
  self.SingleFilters[filterName] = nil
  
  self:FiltersChanged()
end

function ListFilterAdapter:ListSizeChanged()
  assert(self.UnfilteredList, "ListSizeChanged called with a unfiltered input list not set")

  //its much faster to just throw away the old list instead of clearing it  
  self.FilteredList = self:FilterList()
  self:FilteredListChanged(true)

  self.PreviousListSize = #self.UnfilteredList
end

function ListFilterAdapter:ClearFilters()
  
  if(not next(self.ActiveFilters)) then
    return
  end
  
  self.ActiveFilters = {}
  
  self:FiltersChanged()
end

function ListFilterAdapter:RefilterList()
  self.PreviousListSize = nil
  self.FilteredList = self:FilterList(self.UnfilteredList)

  self:FilteredListChanged()
end

function ListFilterAdapter:FiltersChanged()
  
  //clear incremental search state since we have to refilter the list
  self.PreviousListSize = nil

  if(not self.UnfilteredList) then
    return
  end

  local filters

  if(next(self.SingleFilters)) then
    filters = filters or {}
    
    for _,filter in pairs(self.SingleFilters) do
      filters[#filters+1] = filter
    end
  end

  if(filters) then 
    self.FilterFunction = self:BuildFilterFunction(filters)
    
    //its much faster to just throw away the old list instead of clearing it  
    self.FilteredList = self:FilterList(self.UnfilteredList)
  else
    self.FilterFunction = nil
    self.FilteredList = self.UnfilteredList
  end
  
  self:FilteredListChanged()
end

function ListFilterAdapter:FilteredListChanged(sizeOnly)
  
  if(self.ListSorter) then
    self:SortList(true)
  end
  	
  if(self.ListControl) then
	  --delay setting the new list 
	  if(sizeOnly and self.PreviousListSize and not self.ListSorter) then
	    self.ListControl:SetDataList(self.FilteredList, true)//self.ListControl:ListSizeChanged()
	  else
	    self.ListControl:SetDataList(self.FilteredList, true)
	  end
  end
 
  if(self.ListChangedCallback) then
    self.ListChangedCallback(self.FilteredList, sizeOnly == true)
  end
end

local filterFunctionBase = [[
  local %s = unpack(select(1 , ...))
  return function(item)
    return %s
  end
]]

local filterFunctionBase2 = [[
  local %s = unpack(select(1, ...))
  local %s = unpack(select(2, ...))
  return function(item)
    return %s
  end
]]

local function MakeCallChainString(startingIndex, count)

  local first = string.format("f%i(item)", startingIndex)

  if count == 1 then
    return first
  end
  
  local parts = {"(", first}
  
  for i=startingIndex+1,count do
    parts[#parts+1] = string.format(" and f%i(item)", i)
  end
  
  parts[#parts+1] = ")"
  
  return table.concat(parts)
end

local function MakeUpValueList(startingIndex, count)

  local first = string.format("f%i", startingIndex)

  if count == 1 then
    return first
  end
  
  local parts = {first}
  
  for i=startingIndex+1,count do
    parts[#parts+1] = string.format(",f%i", i)
  end
  
  return table.concat(parts)
end

function ListFilterAdapter:BuildFilterFunction(matchFilterList, negativeFilters)

  local upvalueString

  local parts = {"f1"}

  local filterCount = (matchFilterList and #matchFilterList) or 0
  filterCount = filterCount + ((negativeFilters and #negativeFilters) or 0)

  assert(filterCount ~= 0)

  upvalueString = MakeUpValueList(1, filterCount)
  
  local bodyString = ""
  local startFuncI = 1
  
  if(negativeFilters) then
    bodyString = "not "..MakeCallChainString(1, #negativeFilters)
    startFuncI = #negativeFilters
  end
  
  if(matchFilterList) then
    if(startFuncI ~= 1) then
      bodyString = bodyString.." and "
    end
    bodyString = bodyString..MakeCallChainString(startFuncI, #matchFilterList)
  end
  
  local functionString = string.format(filterFunctionBase, upvalueString, bodyString)
  
  return loadstring(functionString)(matchFilterList or negativeFilters, negativeFilters)
end

function ListFilterAdapter:FilterList(list)

  if(not self.FilterFunction) then
    return list or self.UnfilteredList
  end

  local filtered
  local startingIndex = 1
  
  if(list) then
    filtered = {}
  else
    list = self.UnfilteredList
    filtered = self.FilteredList
    
    if(self.PreviousListSize) then
      if(self.PreviousListSize ~= 0) then
        startingIndex = self.PreviousListSize
      end
    else
      filtered = {}
    end
  end

  for i=startingIndex,#list do
    local item = list[i]    
    
    if(self.FilterFunction(item)) then
      filtered[#filtered+1] = item
    end
  end
  
  return filtered
end