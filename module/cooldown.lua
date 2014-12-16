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

local core = namespace.core


--TODO upvalue

local cooldown = {__instance = "cooldown"}

--Note: id can be both a spell_id (integer) or a slot_id (string) and even enemy cooldowns
function cooldown.new(self, unit, id, duration, reset_spell_id)
  local object = CreateFrame("Frame", nil, UIParent)
  
  core.inherit(object, self)
  
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


function cooldown.track(self)
  self:RegisterEvent("SPELL_UPDATE_USABLE")
end


function cooldown.untrack(self)
  self:UnregisterEvent("SPELL_UPDATE_USABLE")
end

--[[
function cooldown.update(self, event, arg0)
  --self.start, self.duration = GetSpellCooldown(self.id)
  if self.start > 0 then
    for i=1, #self._button do
      self._button[i]:update()
    end
  else
    --disable button ?
  end
end
--]]
function cooldown.update(self, event, arg0)
  local start, duration = GetSpellCooldown(self.id)
  if not (self.start == start and self.duration == duration) then
    self.start, self.duration = start, duration
    for i=1, #self._button do
      self._button[i]:update()
    end
  else
    print("droping update")
  end
end

--TODO
function cooldown.reset(self)

end



local button = {__instance = "cooldown_button"}

local config = {["anchor"] = {"CENTER",0,0},
                ["size"] = {64, 64},
                ["enable_tooltip"] = false,
                ["texture_border"] = nil,
                ["texture_background"] = nil,
                }

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
  object.cooldown = nil
  
  object:SetPoint("CENTER",0,0)
  object:SetSize(64,64)
  
  object.icon = CreateFrame("Frame", nil, object)
  object.icon.texture = object.icon:CreateTexture(nil, "BACKGROUND")
  
  object.icon:SetAllPoints(object)
  object.icon:SetFrameLevel(1)
  
  object.icon.texture:SetAllPoints(object.icon)
  
  --object.icon:SetAlpha(0.2)
  
  --local a = object.icon.texture:SetDesaturated(true)
  --print("support")
  --print(a)
  
  --Note: apparently the frame needs to inherit  from CooldownFrameTemplate in order to work 
  object.animation = CreateFrame("Cooldown", nil, object,  "CooldownFrameTemplate")
  object.animation:SetAllPoints(object)
  
  if cooldown then
    object:set_cooldown(cooldown)
  end

  return object
end


function button.update(self)
  --local start, duration = GetSpellCooldown("Spell Name")
  --myCooldown:SetCooldown(start, duration)
  --print("update button") 
  --self.animation:SetCooldown(GetTime(), 120)
  self.animation:SetCooldown(self.cooldown.start, self.cooldown.duration)
end


function button.set_cooldown(self, cooldown)
  table.insert(cooldown._button, self)
  self.cooldown = cooldown
  self.icon.texture:SetTexture(cooldown.texture)
end


local header = {__instance="cooldown_header"}


function header.new(self, config)

end

function header.update(self)

end




local c = cooldown:new("player", 17) --pw:shield
--print(c)
local b = button:new("config",c)
--print(b)

--b:set_cooldown(c)










