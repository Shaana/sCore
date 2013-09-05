--[[
Copyright (c) 2008-2013 Shaana <shaana@student.ethz.ch>
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

local pp = namespace.pp

local function init()

	if config["pp"]["enable"] then
		pp.init(config["pp"]["ui_scale"])
	end
	
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
