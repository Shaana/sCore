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

local pp = {}
namespace.class.pp = pp

local _inherit = namespace.core._inherit


--Note: This function should only be called once.
--it's not possible to change ui_scale after new() has been called for the first time
function pp.new(self, ui_scale)
	--ensure that only one pp object exists
	if not pp.object then
		pp.object = CreateFrame("Frame", nil, UIParent)
		_inherit(pp.object, pp)
		
		if not ui_scale or ui_scale == 1 then
			--Note: seams like if you turn off uiscale, wow already has pixelperfection implemented
			pp.object.ui_scale = 1
			pp.object.use_ui_scale = 0 --turned off
		else
			assert(ui_scale < 1.2) --Note: possibly this should be <= 1 ?
			assert(ui_scale >= 0.64)
			pp.object.ui_scale = ui_scale
			pp.object.use_ui_scale = 1 --turned on
		end	
	end
	
	return pp.object
end


function pp.init(self)
	local selected_resolution = ({GetScreenResolutions()})[GetCurrentResolution()]
	local resolution_width, resolution_height = string.match(selected_resolution, "(%d+)x(%d+)")
	
	print(selected_resolution)
	print(resolution_width, resolution_height)
	
	if self.use_ui_scale == 0 then
		self.scale_factor = 1
	else
		self.scale_factor = 768/(resolution_height*self.ui_scale)
	end
	
	--TODO add functions here we want to use SetSize(), SetPoint() ...
	-- if scalefactor is 1, then simple use the normal functions, otherwiese override them with the scaled functions
	
	print(self.ui_scale)
	print(self.scale_factor)
	
	self:RegisterEvent("VARIABLES_LOADED")
	self:SetScript("OnEvent", self._load)
end

function pp._load(self)
	--setting the multisampling to 1x (anti-aliasing)
	-- If that doesn't work you must override the anti-aliasing for WoW through a configuration panel for your video card
	print("loading pixel perfection ...")
	SetMultisampleFormat(1)
    SetCVar("uiScale", self.ui_scale)
    SetCVar("useUiScale", self.use_ui_scale)
    self:UnregisterEvent("VARIABLES_LOADED") --only need to do this once
end


local function _scale(numpixels, factor)
    return factor * floor(numpixels + .5)
end

local function size(frame, width, height)
    if not height then
        height = width
    end
    frame:SetSize(scale(width), scale(height))
end

local function point(obj, arg1, arg2, arg3, arg4, arg5)
    -- anyone has a more elegant way for this?
    if type(arg1)=="number" then arg1 = scale(arg1) end
    if type(arg2)=="number" then arg2 = scale(arg2) end
    if type(arg3)=="number" then arg3 = scale(arg3) end
    if type(arg4)=="number" then arg4 = scale(arg4) end
    if type(arg5)=="number" then arg5 = scale(arg5) end
    obj:SetPoint(arg1, arg2, arg3, arg4, arg5)
end



function pp.size(self, frame, width, height)
    if not height then
        height = width
    end
    frame:SetSize(_scale(width, self.scale_factor), _scale(height, self.scale_factor))
end






local function init()
	local my_pp = pp:new()
	my_pp:init()
	print("lulu: ", my_pp) 
	print("lulu: ", my_pp.ui_scale)
	print("lulu: ", my_pp.scale_factor) 

	local my_pp2 = pp:new(0.877)
	print("lulu: ", my_pp2) 

	--frame one
	local frame = CreateFrame("Frame", "sPixelPerfection", UIParent)
	--frame:SetHeight(768)
	--frame:SetWidth(200)
	
	my_pp:size(frame, 200, 768)
	
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
	
end

init()
