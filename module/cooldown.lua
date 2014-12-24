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

--TODO implement core.pp property that the whole thing also works then it's disabled

local cooldown = {__instance = "cooldown"}
namespace.class.cooldown = cooldown

--Note: id can be both a spell_id (integer) or a slot_id (string) and even enemy cooldowns
function cooldown.new(self, unit, id, duration, reset_spell_id)
  local object = CreateFrame("Frame", nil, UIParent)
  
  core.inherit(object, self)
  
  object._unit = unit
  object._id = id
  object._start, object._duration = -1, -1 --using impossible values to force at least one update
  
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

--TODO need to track more cooldowns
--especially when cooldown finishes, SPELL_UPDATE_USABLE is not called immediately
--a solution to this might be to check in the update_text function if remaining goes below 0, if so --> update
--test with cooldown reset spells !
 
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
  --TODO remove
  print(event)
  --TODO update texture as well when entering world, not the case here
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
  else
    print("droping update")
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

local backdrop = { 
    edgeFile = "Interface\\AddOns\\sCore\\media\\border",
    edgeSize = 16, 
  }

local default_button_config = {
  ["anchor"] = {"CENTER", 0, 0},
  ["size"] = 64, --only supporting squared buttons, use even number to make it look nice
  ["backdrop"] = backdrop,
  ["border_color"] = {0.4, 0.4, 0.4, 1},
  ["enable_tooltip"] = false,
  ["texture_border"] = nil,
  ["texture_background"] = nil,
  ["texture_desaturate"] = true,
  ["texture_inset"] = 6, --really chrange, backdrop seams to be off by 1px, the border is actually 7px
  ["enable_text"] = true,
  ["text_font"] = {"Interface\\AddOns\\sCore\\media\\big_noodle_titling.ttf", 19, "OUTLINE"},
}


--TODO consistancy with _ and dropping it
function button.new(self, config, cooldown)
  local object = CreateFrame("Frame",nil, UIParent)
  
  core.pp.add_all(object)
  
  core.inherit(object, self, true)
    
  object.config = config or default_button_config --TODO change to config
  object._cooldown = cooldown
  
  object:SetPoint(unpack(object.config["anchor"]))
  object:SetSize(object.config["size"], object.config["size"])
  object:SetFrameLevel(1)
  
  object:SetBackdrop(object.config["backdrop"])
  object:SetBackdropBorderColor(unpack(object.config["border_color"]))
  
  --Note: don't need to scale, cause SetPoint will be scalled
  local i = object.config["texture_inset"] --dont need to scale that --> scaled in setpoint
  local j = i/object.config["size"] --what about that ? write a pp.settexcoord function prob not, cause scale(i)/scale(size) is smae as i/size (relative already)
  
  object.texture = object:CreateTexture(nil, "BACKGROUND")
  core.pp.add_all(object.texture)
  
  object.texture:SetPoint("TOPLEFT", i, -i)
  object.texture:SetPoint("BOTTOMRIGHT", -i, i)
  object.texture:SetTexCoord(j, 1-j, j, 1-j)
    
  --Note: apparently the frame needs to inherit  from CooldownFrameTemplate in order to work 
  object.animation = CreateFrame("Cooldown", nil, object,  "CooldownFrameTemplate")
  core.pp.add_all(object.animation)
  
  object.animation:SetFrameLevel(1)
  object.animation:SetPoint("TOPLEFT", i, -i)
  object.animation:SetPoint("BOTTOMRIGHT", -i, i)
  object.animation:SetDrawEdge(false)
  
  object.text = object:CreateFontString(nil, "OVERLAY")
  object.text:SetPoint("CENTER", 0,0)
  --object.text:SetFont(unpack(object.config["text_font"])) --not working
  object.text:SetFont("Interface\\AddOns\\sBuff2\\media\\skurri.TTF", 19, "OUTLINE")
  
  if cooldown then
    object:set_cooldown(cooldown)
  end

  --TODO, remove
  object._last_text_update = 0

  return object
end


function button.update(self)
  assert(self._cooldown, "no cd set to button")
  
  --update texture in any case
  --TODO remove, only upate if needed
  self.texture:SetTexture(self._cooldown._texture)
  
  --on cooldown
  if self._cooldown._duration > 0 then
    self.texture:SetDesaturated(self.config["texture_desaturate"]) --grey style
    self:SetAlpha(0.8)
    self.animation:SetCooldown(self._cooldown._start, self._cooldown._duration)
    self:SetScript("OnUpdate", self._update_text)
  
  --ready  
  else
    self.texture:SetDesaturated(false)
    self:SetAlpha(1)
    self.text:SetText("")
    self:SetScript("OnUpdate", nil)
  end

end

function button._update_text(self, elapsed)
--  if self._last_text_update < self.update_frequency then 
--    self._last_text_update = self._last_text_update + elapsed
--    return
--  end
  
  self._last_text_update = 0
  
  local start, duration = self._cooldown._start, self._cooldown._duration
  local remaining = duration - (GetTime() - start)
  
  self.text:SetText(core.format_time(remaining))
  
  
end

function button.update_texture(self)
  --self.icon.texture:SetTexture(self.cooldown._texture)
end


function button.set_cooldown(self, cooldown)
  table.insert(cooldown._button, self)
  self._cooldown = cooldown
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





