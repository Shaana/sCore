--[[
Copyright (c) 2008-2014 Shaana <shaana@student.ethz.ch>
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

local config = namespace.config
local pp = namespace.core.pp

local function init()

	if config["pp"]["enable"] then
		pp.init(config["pp"]["ui_scale"])
	end
	

--[[
	local object = CreateFrame("Frame",nil, UIParent)
  sCore.pp.add_all(object)
  object:SetPoint("CENTER",80,0)
  object:SetSize(64,64)
  object.icon = CreateFrame("Frame", nil, object)
  object.icon.texture = object.icon:CreateTexture(nil, "BACKGROUND")
  object.icon:SetAllPoints(object)
  object.icon:SetFrameLevel(1)
  object.icon.texture:SetAllPoints(object.icon)
  object.icon.texture:SetTexture("Interface\\AddOns\\sBuff2\\media\\Border64")
  object.icon.texture:SetVertexColor(0.4, 0.4, 0.4, 1)
--]]

--[[
local c = cooldown:new("player", 17) --pw:shield
--print(c)
local b = button:new("config",c)
--print(b)

--b:set_cooldown(c)

--]]
  local cooldown = namespace.class.cooldown
  local button = namespace.class.cooldown_button
  local header = namespace.class.cooldown_header
  
  local d = cooldown:new("player", 8122) --"BackSlot"
  --local d = cooldown:new("player", "t7") --"BackSlot"
  local f = button:new(nil, d)
	
	--local h = header:new()
	
	local backdrop = { 
    edgeFile = "Interface\\AddOns\\sCore\\media\\border",
    edgeSize = 16, 
  }
	
	local b2_config = {
    ["anchor"] = {"LEFT", 80, 0},
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
	
	 local b3_config = {
    ["anchor"] = {"LEFT", 160, 0},
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
	
	local d2 = cooldown:new("player", "Trinket0Slot")
	--local d3 = cooldown:new("player", "t6")
  
  local f2 = button:new(b2_config, d2)
  --local f3 = button:new(b3_config, d3)
  
  
  --[[

  local frame = CreateFrame("Frame", "talent_text", UIParent)
  local tier = 6
  
  function frame.event(self, event, arg) 
    print(event, arg)
    for i=1, 3 do
      local talentID, name, texture, selected, available = GetTalentInfo(tier, i, GetActiveSpecGroup())
      if selected then
        local s_name, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(name)
        local c = cooldown:new("player", spellId)
        if self.cur_cd then
          self.cur_cd:_untrack()
        end
        self.cur_cd = c
        print(c._start)
        print("using talent: ", name)
        return
      end
    end
    print("no talent picked")
  end
  
  frame.cur_cd = nil
  frame:RegisterEvent("PREVIEW_TALENT_POINTS_CHANGED")
  frame:RegisterEvent("PLAYER_TALENT_UPDATE")
  frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
  --frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
  
  frame:SetScript("OnEvent", frame.event)
  --]]
	
	--[[

	--frame one
	local frame = CreateFrame("Frame", "sPixelPerfection", UIParent)
	
	print(frame.SetHeight)
	pp.add_all(frame)
	
	frame:SetHeight(768)
	frame:SetWidth(200)
	
	
	frame:SetPoint("TOPLEFT",5, 0)
	frame:Show()
	
	local t = frame:CreateTexture(nil,"BACKGROUND")
	t:SetAllPoints(frame)
	t:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
	t:SetVertexColor(0, 0, 0, 0.9)
	t:Show()
	
	
	--frame2 to compare
	local frame2 = CreateFrame("Frame", "sPixelPerfection2", UIParent)
	frame2:SetHeight(768)
	frame2:SetWidth(200)

	frame2:SetPoint("TOPLEFT",250, 0)
	frame2:Show()
	
	local t2 = frame2:CreateTexture(nil,"BACKGROUND")
	t2:SetAllPoints(frame2)
	t2:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
	t2:SetVertexColor(0, 0, 0, 0.9)
	t2:Show()
	
	--]]
end

init()
