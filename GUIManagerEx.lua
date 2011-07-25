
if(not GUIManagerEx) then
  GUIManagerEx = {}
end


local HotReload = ClassHooker:Mixin("GUIManagerEx")

function GUIManagerEx:OnClientLuaFinished()

end

function GUIManagerEx:OnLoad()
  self:SetHooks()
  
  Event.Hook("UpdateClient", function() self:Update() end)
  
  self:HookFileLoadFinished("lua/Skulk_Client.lua", "SetSkulkViewTilt")
  
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

local WheelMessages = nil

local NoUpEvent = {
  [InputKey.MouseZ] = true,
  [InputKey.MouseX] = true,
  [InputKey.MouseY] = true,
}

local KeyDown = {}

--self is really GUIManager
function GUIManagerEx.SendKeyEvent(handle, self, key, down)
  PROFILE("MouseTracker:SendKeyEvent")

  local IsRepeat = false

  if(not NoUpEvent[key]) then
    IsRepeat = KeyDown[key] and down
    KeyDown[key] = down
  end

  local eventHandled, wheelDirection

  if(key == InputKey.MouseZ and GetWheelMessages) then
    if(WheelMessages == nil) then
      WheelMessages = GetWheelMessages() or false
    end
    
    if(WheelMessages and #WheelMessages ~= 0) then
      local direction = WheelMessages[1]
      table.remove(WheelMessages, 1)
      
      for i,dir in ipairs(WheelMessages) do
        if((dir < 0 and direction < 0) or (dir > 0 and direction > 0)) then
          direction = direction+dir
        end
      end
      
      wheelDirection = direction     
    else
      //just eat any extra wheel events this frame
      //even if windows is configured to 1 scroll for 1 wheel click we can still get more than 1 scroll for a single scroll event if the wheel is spinning fast enough
      eventHandled = true
    end
  end

  eventHandled = eventHandled or GUIMenuManager:SendKeyEvent(key, down, IsRepeat, wheelDirection) or GameGUIManager:SendKeyEvent(key, down, IsRepeat, wheelDirection) 

  if(eventHandled) then
    handle:BlockOrignalCall()
    handle:SetReturn(true)
  end
  
  return key, down, IsRepeat, wheelDirection
end

function GUIManagerEx.SendCharacterEvent(handle, self, ...)

  if(GUIMenuManager:SendCharacterEvent(...) or GameGUIManager:SendCharacterEvent(...)) then
    handle:BlockOrignalCall()
    handle:SetReturn(true)
  end
end

function GUIManagerEx:Update()
  WheelMessages = nil
end

if(HotReload) then
  GUIManagerEx:SetHooks()
end