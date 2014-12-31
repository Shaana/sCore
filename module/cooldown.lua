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

local cooldown = {
  __instance = "cooldown",
  __cooldowns = {},
}
namespace.class.cooldown = cooldown

--TODO add global cooldown directory, if same cooldown is registered twice, simply return the one in the directory instead of creating it twice
--TODO somehow remove the gcd from being shown


cooldown.__init = {
  --player or pet spell cooldown
  [0] = function(self)
      _,_, self._texture = GetSpellInfo(self._id)
      --self.update = self.update
    end,
  --player slot cooldown
  [1] = function(self)
      self._property.slot_id = GetInventorySlotInfo(self._id)
      self._texture = GetInventoryItemTexture(self._unit, self._id)
      --self.update = self.update
    end,
  --player talent cooldown
  [2] = function(self)
      self.update = self._update_talent
    end,
  --enemy spell cooldown
  [3] = function(self)
      self.update = self._update_enemy_spell
    end,
    
}

--Note: id can be both a spell_id (integer) or a slot_id (string) and even enemy cooldowns
function cooldown.new(self, unit, id, duration, reset_spell_id)
  --TODO guid is only available after the player enter world or something ...
  local guid = "player" --UnitGUID(unit)
  
  --TODO this might cause problems, cooldowns could unintentionally get untracked
  --solution: make track/untrack private functions. Only track cooldown if one or more frames are registered
  if cooldown.__cooldowns[guid] then
    if cooldown.__cooldowns[guid][id] then
      cooldown.__cooldowns[guid][id]:_track()
      return cooldown.__cooldowns[guid][id]
    end
  else
    cooldown.__cooldowns[guid] = {}
  end

  local object = CreateFrame("Frame", nil, UIParent)
  
  core.inherit(object, self)
  
  object._unit = unit
  object._active = false
  object._id = id
  object._start, object._duration = 0, 0
  object._property = {} -- cooldown specific properties
  
  --the cooldown_button class can register buttons here, which will be updated On_event
  object._frames = {}
  
  --Note: 
  if type(object._id) == "number" then
    if object._unit == "player" or object._unit == "pet" then
      object._case = 0
    else
      object._case = 3
    end
    
  --item cooldown (slot name is given)
  elseif type(id) == "string" then
    local s, e, m = string.find(object._id, "^t([0-9])$")
    if s then
      object._case = 2
      --TODO
      -- scan tier for spells with base_cooldown, register a new cooldown:new(id)
      -- track/untrack spells that are currently picked by the player/unit
      object._property.tier = m
      object._property.cds = {}
      
      --cooldown = GetSpellBaseCooldown(id) --returns 0, if no cd and nil if error
      
      
      --local talent_id, spell_name, spell_texture = GetTalentInfo(object._tier, 1, 2) --GetTalentInfo(tier, column, talentGroup[, isInspect, inspectedUnit])
      --local _, talentName = GetTalentInfoByID(talent_id, 2); --DONT NEED THAT
      
      --This will return the right spell depending on spec
      --but only if the talent is picked and in the spell book ... (unless spell_id is used)
      --name, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(spell_name)
      
      --self:RegisterEvent("PREVIEW_TALENT_POINTS_CHANGED");
      --self:RegisterEvent("PLAYER_TALENT_UPDATE");
    else
      --Note: we save the numeric slot identifier not the slot_name passed to cooldown.new function
      object._case = 1
    end
  end

  cooldown.__init[object._case](object)

  object:SetScript("OnEvent", self.update) 
  object:_track()
  
  cooldown.__cooldowns[guid][id] = object
  return object
end

--TODO need to track more cooldowns
--especially when cooldown finishes, SPELL_UPDATE_USABLE is not called immediately
--a solution to this might be to check in the update_text function if remaining goes below 0, if so --> update
--test with cooldown reset spells !
 
cooldown.__event = {
  [0] = {
    "SPELL_UPDATE_COOLDOWN",
    },
  [1] = {
    "UNIT_INVENTORY_CHANGED",
    "BAG_UPDATE_COOLDOWN",
    },
  [2] = {
    "PREVIEW_TALENT_POINTS_CHANGED",
    "PLAYER_TALENT_UPDATE",
    "ACTIVE_TALENT_GROUP_CHANGED",
  }
}
 
function cooldown._track(self)
  if not self._active then
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    for i,v in ipairs(cooldown.__event[self._case]) do
      print(i,v)
      self:RegisterEvent(v)
    end
    
--    if self._type == 0 then --case[0]
--      --self:RegisterEvent("SPELL_UPDATE_USABLE")
--      self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
--    elseif self._type == 1 then
--      --Note: an item might be switched, update texture
--      self:RegisterEvent("UNIT_INVENTORY_CHANGED")
--      --Note: BAG_UPDATE_COOLDOWN fires every 3-5 seconds for no apparent reason 
--      self:RegisterEvent("BAG_UPDATE_COOLDOWN")
--    end
  end
end


function cooldown._untrack(self)
  self:UnregisterAllEvents()
  self._active = false
end

--Note: if it's a talent cooldown this function is internally overwritten
function cooldown.info(self)
  return self._start, self._duration, self._texture
end


function cooldown.update(self, event, arg)
  --TODO remove
  print(event)
  --TODO update texture as well when entering world, not the case here
  if event == "UNIT_INVENTORY_CHANGED" and arg == self._unit then
    self._texture = GetInventoryItemTexture(self._unit, self._property.slot_id)
    for frame,_ in pairs(self._frames) do
      frame:update()
    end
  end
  
  local start, duration
  
  if self._case == 0 then
    start, duration = GetSpellCooldown(self._id)
  elseif self._case == 1 then
    start, duration = GetInventoryItemCooldown(self._unit, self._property.slot_id)
  end
  
  
  --TODO test gcd stop and add option 
  if not (self._duration == duration and self._start == start) then
    --(duration > 1.5 or duration == 0)
    if (duration > 1.5 or duration == 0) then
      --TODO make it nicer code ...
      --Note: force update after cooldown expired
      if duration > 0 then
        print("adding callback")
        --Note: (GetTime() - start) is NOT zero as one might expect
        C_Timer.After(duration - (GetTime() - start), function() 
        print("callback")
        self:update()
        end)
      end
      
      
      self._start, self._duration = start, duration
      --TODO remove
      --for i=1, #self._button do
      for frame,_ in pairs(self._frames) do
        --self._button[]:update()
        frame:update()
      end
    else
      --print(duration)
    end
  else
    --print("droping update")
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


function cooldown._update_spell(self, event, arg)

end


function cooldown._update_slot(self, event, arg)

end


function cooldown._update_talent(self, event, arg)
  
end


function cooldown.register(self, frame)
  if not self._frames[frame] then
    self._frames[frame] = true
    return true
  end
  return false
end


function cooldown.unregister(self, frame)
  if self._frames[frame] then
    self._frames[frame] = nil
    return true
  end
  return false
end


local button = {__instance = "cooldown_button"}
namespace.class.cooldown_button = button

local backdrop = { 
    edgeFile = "Interface\\AddOns\\sCore\\media\\border",
    edgeSize = 16, 
  }

local default_button_config = {
  ["anchor"] = {"LEFT", 0, 0},
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
  --local j = i/object.config["size"] --what about that ? write a pp.settexcoord function prob not, cause scale(i)/scale(size) is smae as i/size (relative already)
  local j = 5/64 --0.0625 --4/64
  
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
  object.text:SetFont("Interface\\AddOns\\sCore\\media\\big_noodle_titling.ttf", 19, "OUTLINE")
  --"Interface\\AddOns\\sBuff2\\media\\skurri.TTF", 19, "OUTLINE")
  
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
  --TODO remove, only upate if needed, or maybe always, function not called often anyway
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
    --TODO when switching trinkets, the animation doesn't stop
    --StopAnimating() not working ?
    --self.animation:StopAnimating()
    self.animation:SetCooldown(0,0) 
    self:SetScript("OnUpdate", nil)
    self.text:SetText("")
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
  
--TODO instead add a c_timer to the cooldown class, that does basically that
--doesnt belong here, should be in the cd class
--  if remaining < 0 then
--    print(remaining)
--    self._cooldown:update()
--  end
  
end


function button.set_cooldown(self, cooldown)
  --TODO check cooldown:register() return code. act accordingly
  if cooldown:register(self) then
    self._cooldown = cooldown
    self:update()
  end
end


local header = {__instance="cooldown_header"}
namespace.class.cooldown_header = header

local default_header_config = {
  ["anchor"] = {"CENTER",-420,-185},
  ["horizontal_spacing"] = 5,
  ["vertical_spacing"] = 5,
  ["grow_direction"] = "LEFTUP",
  ["spell_ids"] = {
    "Trinket0Slot",
    47585,  -- Dispersion
    15487,  -- Silence
    8122, -- Psychic Scream
    6346, -- Fear Ward
    120517, -- Halo
    8092, -- Mind Blast
  },
}

function header.new(self, config, button_config)
  local object =  CreateFrame("Frame",nil, UIParent)
  
  core.pp.add_all(object)
  core.inherit(object, self)
  
  object.config = config  or default_header_config
  --TODO make a copy, so we can change anchor and wont affect things ...
  object.button_config = button_config or default_button_config
  
  object:SetSize(40,40)
  object:SetPoint(unpack(object.config["anchor"]))
  
  object.button_config["size"] = 36
  
  local x, y
  local h_dist = 0
  local x_size = object.button_config["size"]
  --local cur_anch = {}
  for i=1, #object.config["spell_ids"] do
    x = (h_dist + x_size)*(i % 12)
    y = 0 
    cur_anch = {"TOPLEFT", object, "TOPLEFT", x, y}
    object.button_config["anchor"] = cur_anch
    local c = cooldown:new("player", object.config["spell_ids"][i])
    button:new(object.button_config, c)
  end
  
  return object
end


--TODO, when config is reloaded ?
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





