//
//   Created by:   fsfod
//
if(not PageFactory) then
  PageFactory = {}
end

function PageFactory:Initialize()
  self.Pages = {}
end

function PageFactory:GetActivePages()

  local list = {}

  for name,page in pairs(self.Pages) do
    if(page:IsShown()) then
      list[#list+1] = name
    end
  end
  
  return list
end

function PageFactory:_internalCreatePage(name)

  local info = GUIMenuManager:GetPageInfo(name)
  
  if(not info) then
    RawPrint("PageFactory:CreatePage unknown page " .. (name or "nil"))
   return nil
  end

  if(not _G[info.ClassName]) then
    RawPrint("PageFactory:CreatePage page class " .. (name or "nil").." does not exist")
   return nil
  end

  GUIMenuManager.Callbacks:Fire("PrePageCreated", name)

  local success,pageOrError = pcall(CreateControl, info.ClassName)

  if(success) then

    local success2, errorMessage = pcall(pageOrError.Initialize, pageOrError, self)

    if(not success) then
      //try to clear up any frames that got created during the failed Initialize call
      pcall(GUI.DestroyItem, pageOrError)

      pageOrError = errorMessage
      success = success2
    end
  end

  if(not success) then
    GUIMenuManager:ShowMessage("Error while creating page "..name, pageOrError)
   return nil
  end
   
  GUIMenuManager.Callbacks:Fire("PageCreated", name, pageOrError)
   
  return pageOrError
end

function PageFactory:GetOrCreatePage(name)

  if(self.Pages[name]) then
    return self.Pages[name]
  end

  local page = self:_internalCreatePage(name)

  if(not page) then
    return
  end

  self.Pages[name] = page

  if(self.OnPageCreated) then
    self:OnPageCreated(name, page)
  end
  
  return page
end

function PageFactory:RecreatePage(pageName)
  local oldPage = self.Pages[pageName]
  
  if(oldPage) then
		RawPrint("RecreatingPage "..pageName)
		
    pcall(function()
      SafeCallOptional(self, "OnPageDestroy", pageName, oldPage)
      
      oldPage:Hide()
      oldPage:Uninitialize()
    end)

    local newPage = self:_internalCreatePage(pageName)

    self.Pages[pageName] = newPage

    if(self.OnPageCreated) then
      self:OnPageCreated(name, newPage, oldPage)
    end
	else

	  if(GUIMenuManager:GetPageInfo(name)) then
      RawPrint("RecreatePage Could not find a pageinfo for page"..pageName)
    end
  end
end

function PageFactory:Mixin(target)

  assert(type(target) == "table")

  target.GetOrCreatePage = self.GetOrCreatePage

  target._internalCreatePage = self._internalCreatePage

  if(not target.ShowPage) then
    target.ShowPage = self.GetOrCreatePage
  end
  
  target.RecreatePage = self.RecreatePage
  target.GetActivePages= self.GetActivePages
end