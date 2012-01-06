//
//   Created by:   fsfod
//

if(not GUIManagerEx) then
  GUIManagerEx = {}
end


local HotReload = ClassHooker:Mixin("GUIManagerEx")

function GUIManagerEx:OnClientLuaFinished()

end

function GUIManagerEx:OnLoad()
  self:SetHooks()

  self:HookFileLoadFinished("lua/Skulk_Client.lua", "SetSkulkViewTilt")
  
  
  if(StartupLoader) then
    StartupLoader:AddReducedLuaScript("lua/GUIManager.lua")
    StartupLoader:AddReducedLuaScript("lua/Main.lua")
  end
  
  MouseStateTracker:Init()
  
  GUIMenuManager:Initialize()
  GameGUIManager:Initialize()
end

function GUIManagerEx:SetSkulkViewTilt()
  OnCommandSkulkViewTilt(Client.GetOptionBoolean("DisableSkulkViewTilt", false) and "false")
end

local function CheckLoadedAndType(scriptName)
 local frameClass = _G[scriptName]

  if(not frameClass) then
    Script.Load("lua/" .. scriptName .. ".lua")
    frameClass = _G[scriptName]
  end

  return frameClass and frameClass:isa("BaseControl")
end

function GUIManagerEx:SetHooks()
  ClassHooker:SetClassCreatedIn("GUIManager", "lua/GUIManager.lua")

  self:RawHookClassFunction("GUIManager", "SendKeyEvent", self.SendKeyEvent):SetPassHandle(true)
  self:HookClassFunction("GUIManager", "SendCharacterEvent", self.SendCharacterEvent):SetPassHandle(true)

  self:HookClassFunction("GUIManager", "CreateGUIScript"):SetPassHandle(true)
  self:HookClassFunction("GUIManager", "CreateGUIScriptSingle"):SetPassHandle(true)
  
  self:HookClassFunction("GUIManager", "GetGUIScriptSingle", function(handle, self, scriptName) 

    if(CheckLoadedAndType(scriptName)) then
      handle:BlockOrignalCall()
      handle:SetReturn(GameGUIManager.SingleInstance[scriptName])
    end
  end):SetPassHandle(true)

  self:HookClassFunction("GUIManager", "DestroyGUIScript", function(self, frame)
    
    if(frame and frame:isa("BaseControl")) then
      GameGUIManager:RemoveFrame(frame)
    end
  end)
  
  self:HookClassFunction("GUIManager", "DestroyGUIScriptSingle"):SetPassHandle(true)
end

function GUIManagerEx:CreateGUIScript(handle, self, scriptName)

  if(CheckLoadedAndType(scriptName)) then
    handle:BlockOrignalCall()

    handle:SetReturn(GameGUIManager:CreateFrame(scriptName))
  end
end

function GUIManagerEx:CreateGUIScriptSingle(handle, self, scriptName)

  if(CheckLoadedAndType(scriptName)) then
    handle:BlockOrignalCall()
    handle:SetReturn(GameGUIManager:GetSingleInstanceControl(scriptName))
  end
end

function GUIManagerEx:DestroyGUIScriptSingle(handle, self, scriptName)

  if(CheckLoadedAndType(scriptName)) then
    GameGUIManager:DestroySingleInstance(scriptName)

    handle:BlockOrignalCall()
    handle:SetReturn(true)
  end
end

function GUIManagerEx.SendKeyEvent(handle, self, key, down)
  PROFILE("MouseTracker:SendKeyEvent")

  local eventHandled, IsRepeat = InputKeyHelper:PreProcessKeyEvent(key, down)

  eventHandled = eventHandled or GUIMenuManager:SendKeyEvent(key, down, IsRepeat) or GameGUIManager:SendKeyEvent(key, down, IsRepeat)

  if(eventHandled) then
    handle:BlockOrignalCall()
    handle:SetReturn(true)
  end
  
  return key, down, IsRepeat
end

function GUIManagerEx.SendCharacterEvent(handle, self, ...)

  if(GUIMenuManager:SendCharacterEvent(...) or GameGUIManager:SendCharacterEvent(...)) then
    handle:BlockOrignalCall()
    handle:SetReturn(true)
  end
end

if(HotReload) then
  GUIManagerEx:SetHooks()
end