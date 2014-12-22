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


--[[
  Allows to track spell and item cooldowns. 
  Buttons visually display the cooldown
  
  
  
  Notes:


  Examples:
  
    --create a new spell cooldown for the player (power word: shield)
    local spell_cooldown = cooldown:new("player", 17)
    
    --create the button
    local config = {
    
    }
    
    local spell_button = button:new(config, spell_cooldown)
    
    --this equivalent
    local spell_button = button:new(config)
    spell_button:set_cooldown(spell_cooldown)
  
--]]

local addon, namespace = ...
local core = namespace.core

--TODO upvalue

local cooldown = {__instance = "cooldown"}
namespace.class.cooldown = cooldown

--Note: id can be both a spell_id (integer) or a slot_id (string) and even enemy cooldowns
function cooldown.new(self, unit, id, duration, reset_spell_id)
  local object = CreateFrame("Frame", nil, UIParent)
  
  core.inherit(object, self)
  
  object._unit = unit
  object._id = id
  object._start, object._duration = 0, 0
  
  --the cooldown_button class can register buttons here, which will be updated On_event
  object._button = {}
  
  --spell cooldown
  if type(id) == "number" then
    _,_, object._texture = GetSpellInfo(id) --object.name
    object._type = 0
    
  --item cooldown (slot name is given)
  elseif type(id) == "string" then
    --Note: we save the numeric slot identifier not the slot_name passed to cooldown.new function
    object._id = GetInventorySlotInfo(id)
    object._texture = GetInventoryItemTexture(unit, object._id)
    object._type = 1

  --TODO
  --enemy cooldown
  --elseif not (unit == "player" or unit == "pet") then
    --object._type = 2
  end

  object:SetScript("OnEvent", self.update) 
  object:track()
  
  return object
end


function cooldown.track(self)
  self:RegisterEvent("PLAYER_ENTERING_WORLD")
  
  if self._type == 0 then
    self:RegisterEvent("SPELL_UPDATE_USABLE")
  elseif self._type == 1 then
    --Note: an item might be switched, update texture
    self:RegisterEvent("UNIT_INVENTORY_CHANGED")
    --Note: BAG_UPDATE_COOLDOWN fires every 3-5 seconds for no apparent reason 
    self:RegisterEvent("BAG_UPDATE_COOLDOWN")
  elseif self._type == 2 then
  
  elseif self._type == 3 then
  
  end
end


function cooldown.untrack(self)
  self:UnregisterAllEvents()
end


function cooldown.update(self, event, arg)
  if event == "UNIT_INVENTORY_CHANGED" and arg == self._unit then
    self._texture = GetInventoryItemTexture(self._unit, self._id)
    for i=1, #self._button do
      self._button[i]:update_texture()
    end
  end
  
  local start, duration
  
  if self._type == 0 then
    start, duration = GetSpellCooldown(self._id)
  elseif self._type == 1 then
    start, duration = GetInventoryItemCooldown(self._unit, self._id)
  end
  
  if not (self._start == start and self._duration == duration) then
    self._start, self._duration = start, duration
    for i=1, #self._button do
      self._button[i]:update()
    end
--  else
--    print("droping update")
--    print(self._type)
  end
  
  
  --[[
  elseif event == "BAG_UPDATE_COOLDOWN" then 
    local start, duration = GetInventoryItemCooldown(self._unit, self._slot_id)
    if not (self._start == start and self._duration == duration) then
      self._start, self._duration = start, duration
      for i=1, #self._button do
        self._button[i]:update()
      end
    else
      print("droping update bag")
    end
    
  elseif event == "SPELL_UPDATE_USABLE" then
    local start, duration = GetSpellCooldown(self._id)
    if not (self._start == start and self._duration == duration) then
      self._start, self._duration = start, duration
      for i=1, #self._button do
        self._button[i]:update()
      end
    else
      print("droping update spell")
    end
  end
  --]]
  
  
end



local button = {__instance = "cooldown_button"}
namespace.class.cooldown_button = button

local default_button_config = {
  ["anchor"] = {"CENTER", 0, 0},
  ["size"] = 64, --only supporting squared buttons
  ["enable_tooltip"] = false,
  ["texture_border"] = nil,
  ["texture_background"] = nil,
  ["texture_inset"] = 7,
  ["enable_text"] = true,
  ["text_font"] = {},
}

local backdrop = { 
   -- bgFile = nil, --"Interface\\AddOns\\sCore\\media\\bg_flat", 
    edgeFile = "Interface\\AddOns\\sCore\\media\\border",
    --tile = false,
   -- tileSize = 32, 
    edgeSize = 16, 
    insets = { 
      left = 0, 
      right = 0, 
      top = 0, 
      bottom = 0,
    },
  }



function button.new(self, config, cooldown)
  local object = CreateFrame("Frame",nil, UIParent)
  
  sCore.pp.add_all(object)
  
  core.inherit(object, self, true)
  
  object.config = default_button_config -- config
  object.cooldown = nil
  
  object:SetPoint(unpack(object.config["anchor"]))
  object:SetSize(object.config["size"], object.config["size"])
  
  object:SetFrameLevel(1)
  
  object:SetBackdrop(backdrop)
  object:SetBackdropColor(1,1,1,0)
  object:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
  
  object.texture = object:CreateTexture(nil, "BACKGROUND")
  
  
  object.icon = CreateFrame("Frame", nil, object)
  object.icon:SetAllPoints(object)
  object.icon:SetFrameLevel(1)
  
  --object.icon.texture = object.icon:CreateTexture(nil, "BACKGROUND")
  
  --TODO pp.add(texture, gloss, etc.)

  local i = object.config["texture_inset"] --dont need to scale that --> scaled in setpoint
  local j = i/object.config["size"] --what about that ? write a pp.settexcoord function prob not, cause scale(i)/scale(size) is smae as i/size (relative already)
  
--  object.icon.texture:SetPoint("TOPLEFT", i, -i)
--  object.icon.texture:SetPoint("BOTTOMRIGHT", -i, i)
--  object.icon.texture:SetTexCoord(j, 1-j, j, 1-j)
  
  object.texture:SetPoint("TOPLEFT", i, -i)
  object.texture:SetPoint("BOTTOMRIGHT", -i, i)
  object.texture:SetTexCoord(j, 1-j, j, 1-j)
  
  
  object.texture:SetTexture(cooldown._texture)
  
  --object.icon:SetAllPoints(object)
  --object.icon:SetFrameLevel(1)
  
  --object.icon.texture:SetAllPoints(object.icon)
  
  --object.icon:SetAlpha(0.2)
  
  --local a = object.icon.texture:SetDesaturated(true)
  --print("support")
  --print(a)
  
  --Note: apparently the frame needs to inherit  from CooldownFrameTemplate in order to work 
  object.animation = CreateFrame("Cooldown", nil, object,  "CooldownFrameTemplate")
  object.animation:SetAllPoints(object)
  
  object.text = object:CreateFontString(nil, "OVERLAY")
  object.text:SetPoint("CENTER", 0,0)
  object.text:SetFont("Interface\\AddOns\\sBuff2\\media\\skurri.TTF", 22, "OUTLINE")
  object.text:SetText("15")
  
  
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
  self.animation:SetCooldown(self.cooldown._start, self.cooldown._duration)
end

function button.update_texture(self)
  --self.icon.texture:SetTexture(self.cooldown._texture)
end


function button.set_cooldown(self, cooldown)
  table.insert(cooldown._button, self)
  self.cooldown = cooldown
  --self.icon.texture:SetTexture(cooldown._texture)
end


local header = {__instance="cooldown_header"}
namespace.class.cooldown_header = header

local default_header_config = {
  ["anchor"] = {},
  ["horizontal_spacing"] = 5,
  ["vertical_spacing"] = 5,
  ["grow_direction"] = "LEFTUP",
  ["spell_ids"] = {nil},
}

function header.new(self, config, button_config)
  local object =  CreateFrame("Frame",nil, UIParent)
  core.inherit(object, self)
  
  for i=1, #config["spell_ids"] do
    
    button:new(button_config)
  end
  
  return object
end

function header.update(self)

end



--[[
  ["PRIEST"] = {
17, -- Power Word: Shield
527,  -- Purify
586,  -- Fade
724,  -- Lightwell
6346, -- Fear Ward
8092, -- Mind Blast
8122, -- Psychic Scream
10060,  -- Power Infusion
14914,  -- Holy Fire
15286,  -- Vampiric Embrace
15487,  -- Silence
19236,  -- Desperate Prayer
32375,  -- Mass Dispel
32379,  -- Shdow Word: Death
33076,  -- Prayer of Mending
33206,  -- Pain Suppression
34433,  -- Shadowfiend
34861,  -- Circle of Healing
47540,  -- Penance
47585,  -- Dispersion
47788,  -- Guardian Spirit
62618,  -- Power Word: Barrier
64901,  -- Hymm of Hope
64044,  -- Psychic Horror
64843,  -- Divine Hymm
73325,  -- Leap of Faith
81206,  -- Chakra: Sanctuary
81209,  -- Chakra: Chastise
81208,  -- Chakra: Serenity
81700,  -- Archangel
88625,  -- Holy Word: Chastise
88684,  -- Holy Word: Serenity
88685,  -- Holy Word: Sanctuary
89485,  -- Inner Focus
108920, -- Void Tendrils
108921, -- Psyfiend
108968, -- Void Shift
109964, -- Spirit Shell
110744, -- Divine Star
120517, -- Halo
121135, -- Cascade
121536, -- Angelic Feather
123040, -- Mindbender
129250, -- Power Word: Solace
},
--]]





