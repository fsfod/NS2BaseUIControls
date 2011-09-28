

PageFactory = {}

function PageFactory:__init()
  self.Pages = {}
end

function PageFactory:_internalCreatePage(name)

  local info = GUIMenuManager:GetPageInfo(name)
  
  if(not info) then
    RawPrint("PageFactory:CreatePage unknown page " .. (name or "nil"))
   return nil
  end

  local creator = _G[info.ClassName]

  if(not creator) then
    RawPrint("PageFactory:CreatePage could not get page creator for " .. (name or "nil"))
   return nil
  end

  local success,pageOrError = pcall(creator)

  if(not success) then
    GUIMenuManager:ShowMessage("Error while creating page "..name, pageOrError)
   return nil
  end
   
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
end