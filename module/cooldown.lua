--[[
Copyright (c) 2014 Shaana <shaana@student.ethz.ch>
This file is part of sCore.

sCore is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

sCore is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with sCore.  If not, see <http://www.gnu.org/licenses/>.
--]]

local addon, namespace = ...

local cooldown = {__instance = "cooldown"}

--Note: id can be both a spell_id (integer) or a slot_id (string) 
function cooldown.new(self, unit, id, duration, reset_spell_id)
  local object = CreateFrame("Frame", nil, UIParent)
  
  --inherit functions from two objects (cooldown class and CreateFrame class)
  local parent = {self, getmetatable(object).__index}
  setmetatable(object, self)
  self.__index = function(t,k)
    for i=1, #parent do
      local v = parent[i][k]
      if v then
        return v
      end
    end
  end

  object.unit = unit
  object.id = id
  
  object.name, _, object.texture = GetSpellInfo(id)
  
  object.start, object.duration = 0, 0

  --the cooldown_button class can register buttons here, which will be updated On_event
  object._button = {}
  
  object:RegisterEvent("PLAYER_ENTERING_WORLD")
  
  object:SetScript("OnEvent", self.update)
  
  object:track()
  
  return object
end


--enable event listener to follow the cooldown
function cooldown.track(self)
  --self:RegisterEvent("SPELLS_CHANGED")
  self:RegisterEvent("SPELL_UPDATE_USABLE")
end


function cooldown.untrack(self)
  self:UnregisterEvent("SPELL_UPDATE_USABLE")
end


function cooldown.update(self, event, arg1)
  print("in update")
  start, duration = GetSpellCooldown(self.id)
  if start > 0 then
    print("updating cd")
    print((duration-(GetTime()-start))/60)
    for i=1, #self._button do
      self._button[i]:update()
    end
  end
end


function cooldown.reset(self)

end


local button = {__instance = "cooldown_button"}


function button.new(self, config, cooldown)
  local object = CreateFrame("Frame",nil, UIParent)
  
  local parent = {self, getmetatable(object).__index}
  setmetatable(object, self)
  self.__index = function(t,k)
    for i=1, #parent do
      local v = parent[i][k]
      if v then
        return v
      end
    end
  end
  
  object.config = config
  object.cooldown = cooldown
  
  
  object:SetPoint("CENTER",0,0)
  object:SetSize(64,64)
  
  
  object.icon = CreateFrame("Frame", nil, object)
  object.icon.texture = object.icon:CreateTexture(nil, "BACKGROUND")
  
  
  object.icon:SetAllPoints(object)
  object.icon:SetFrameLevel(1)
  
  name, _, texture = GetSpellInfo(2944)-- object.cooldown.id)
  
  object.icon.texture:SetAllPoints(object.icon)
  object.icon.texture:SetTexture(texture)
  --object.icon:SetAlpha(0.2)
  
  --local a = object.icon.texture:SetDesaturated(true)
  --print("support")
  --print(a)
  
  object.animation = CreateFrame("Cooldown", nil, object,  "CooldownFrameTemplate")
  object.animation:SetAllPoints(object)
  object.animation:SetCooldown(GetTime(), 120)
  
  return object
end


function button.update(self)
  --local start, duration = GetSpellCooldown("Spell Name")
  --myCooldown:SetCooldown(start, duration)
  print("update button") 
  self.animation:SetCooldown(GetTime(), 120)
end


function button.set_cooldown(self, cooldown)
  table.insert(cooldown._button, self)
end


local c = cooldown:new("player", 17) --pw:shield
local b = button:new("config",c)
b:set_cooldown(c)


--[[
-- Wrapper for the desaturation feature used in the default UI:
-- if running on display hardware (or drivers, etc) that does not support desaturation,
-- uses SetVertexColor to "dim" the texture instead
 
function SetDesaturation(texture, desaturation)
  local shaderSupported = texture:SetDesaturated(desaturation);
  if ( not shaderSupported ) then
    if ( desaturation ) then
      texture:SetVertexColor(0.5, 0.5, 0.5);
    else
      texture:SetVertexColor(1.0, 1.0, 1.0);
    end
  end
end
--]]









