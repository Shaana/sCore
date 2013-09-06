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

local core = namespace.core

local pp = {method = {}}
namespace.pp = pp

--Note: Asuming Scale of every frame is 1 and parent tree ends with UIParent
--check http://nclabs.org/articles/2

function pp.init(ui_scale)
	local selected_resolution = ({GetScreenResolutions()})[GetCurrentResolution()]
	local resolution_width, resolution_height = string.match(selected_resolution, "(%d+)x(%d+)")
	
	if not pp._object then
		pp._object = CreateFrame("Frame", nil, UIParent)
		pp._mapping = {} --mapping table to track replaced functions of frames.
		--[[
		map_table = { 	["frame1"] = { 	["SetPoint"] = function C488F9F1,
										["Setsize"] = function fC64Fd21,},
						
						["frame2"] = {...},
		}
		--]]
		
		--Note: seams like if you turn off uiscale, wow already has pixelperfection implemented
		if ui_scale then
			assert(ui_scale < 1.2) --TODO possibly this should be <= 1 ?
			assert(ui_scale >= 0.64)
			
			pp._ui_scale = ui_scale
			pp._use_ui_scale = 1 --turned on
			pp._scale_factor = 768/(resolution_height*ui_scale)
		else
			pp._use_ui_scale = 0 --turned off
			pp._scale_factor = 1
		end	
	end

	pp._object:RegisterEvent("VARIABLES_LOADED")
	pp._object:SetScript("OnEvent", pp._load)
end

--TODO write this function
function pp.reload()
	--Go through mapping table and resize 
	--using old scale and new scale
	--this might be tricky to implement
end

function pp._load()
	assert(pp._object, "pp not initialized") 
	
	--setting the multisampling to 1x (anti-aliasing)
	-- If that doesn't work you must override the anti-aliasing for WoW through a configuration panel for your video card
	SetMultisampleFormat(1)
	if pp._use_ui_scale == 1 then
    	SetCVar("uiScale", pp._ui_scale)
    end
    SetCVar("useUiScale", pp._use_ui_scale)
    pp._object:UnregisterEvent("VARIABLES_LOADED") --only need to do this once
end

function pp.add(frame, method_name)
	assert(pp._object, "pp not initialized")
	assert(method_name, "missing arg")
	assert(frame[method_name], "doesn't have this method: "..method_name)
	
	--check if the frame has a method called method_name
	if frame[method_name] then 
		--first time we map a function for this frame
		if not pp._mapping[frame] then
			pp._mapping[frame] = {}
		end
		
		assert(not pp._mapping[frame][method_name], "already mapped this function")
	
		--map the original methed
		if not pp._mapping[frame][method_name] then
			pp._mapping[frame][method_name] = frame[method_name]
			frame[method_name] = pp.method[method_name]
		end
	end
end

function pp.add_all(frame)
	for k,_ in pairs(pp.method) do
		--check if the frame has a method called k
		if frame[k] then
			pp.add(frame, k)
		end
	end
end


--TODO write those two functions
function pp.remove(frame, method_name)

end


function pp.remove_all(frame)

end


function pp._scale(num_pixels)
    return pp._scale_factor * floor(num_pixels + .5)
end


function pp.method.SetHeight(frame, height)
	assert(pp._object, "pp not initialized") 
	pp._mapping[frame]["SetHeight"](frame, pp._scale(height))
end


function pp.method.SetWidth(frame, width)
	assert(pp._object, "pp not initialized") 
	pp._mapping[frame]["SetWidth"](frame, pp._scale(width))
end


function pp.method.SetSize(frame, width, height)
	assert(pp._object, "pp not initialized") 
    if not height then
        height = width
    end
	pp._mapping[frame]["SetSize"](frame, pp._scale(width), pp._scale(height))	
end

--TODO further test this function
function pp.method.SetPoint(frame, point, arg2, arg3, arg4, arg5)
	assert(pp._object, "pp not initialized")
	--first argument will never be a number
	if type(arg2) == "number" then arg2 = pp._scale(arg2) end
    if type(arg3) == "number" then arg3 = pp._scale(arg3) end
    if type(arg4) == "number" then arg4 = pp._scale(arg4) end
    if type(arg5) == "number" then arg5 = pp._scale(arg5) end
	pp._mapping[frame]["SetPoint"](frame, point, arg2, arg3, arg4, arg5)
end


--TODO test
function pp.method.SetFont(frame, font, size, flags)
	assert(pp._object, "pp not initialized")
	--TODO we need to make a point to pixel conversion, then scale and convert back!
	--for now we dont scale
	pp._mapping[frame]["SetFont"](frame, font, pp._scale(size), flags)
end

--TODO test
function pp.method.SetBackdrop(frame, backdrop_table)
	assert(pp._object, "pp not initialized")
	assert(type(backdrop_table) == "table")
	--[[
	{ 	bgFile = "bgFile",
		edgeFile = "edgeFile",
		tile = false,
		tileSize = 0,
		edgeSize = 32, 
		insets = { left = 0, right = 0, top = 0, bottom = 0 }.
	}
	--]]
	local new_bd = core._table_copy(backdrop_table)
	new_bd["tileSize"] = pp._scale(new_bd["tileSize"])
	new_bd["edgeSize"] = pp._scale(new_bd["edgeSize"])
	new_bd["insets"]["left"] = pp._scale(new_bd["insets"]["left"])
	new_bd["insets"]["right"] = pp._scale(new_bd["insets"]["right"])
	new_bd["insets"]["top"] = pp._scale(new_bd["insets"]["top"])
	new_bd["insets"]["bottom"] = pp._scale(new_bd["insets"]["bottom"])
	
	pp._mapping[frame]["SetFont"](frame, new_bd)
end

--TODO there are more functions like setMaxResize




