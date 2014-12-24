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
  
  local d = cooldown:new("player", 8122) --"BackSlot"
  local f = button:new(nil, d)
	
	
	
	
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
