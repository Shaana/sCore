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

--[[

  --TODO (description, Example - test it)
  pixel perfection (pp), 
  e.g makes 1px borders look nice

  Note:
  
    - In order to make pixel perfection work anti-aliasing needs to be turned off. This can generally
      be done in the Wow video settings. In the case this doesn't work, one must override anti-aliasing
      for Wow through the configuration panel of the video card
   
    - It is assumed that all the frames registered with pp have an effective scale equal to the 
      UIParent's scale (which is equal to the UI scale)
   
    - Currently it is impossible to retrieve the UI scale CVar during the first code load. A solution
      to this problem is to hard code the value. Hence, the desired UI scale value should be set 
      in the 'config.lua' file. Under no circumstances is the UI scale to be changed in-game directly!

  Methods:
    
    - Replaces a frames method with a scaled version of the same function. Individual methods or all
      currently available methods can be replaced.
    
    pp.register_method(frame, method_name)
    pp.register(frame)
    
    - Currently the following methods are scaled to achieve pixel perfection
    
    SetHeight
    SetWidth
    SetSize
    SetPoint
    SetBackdrop


  Example:
    
    --create a frame with texture
    local frame = CreateFrame("Frame", nil, UIParent)
    
    --enable pixel perfection for the frame (before using SetPoint, SetSize, ....)
    sCore.pp.register(frame)
    
    frame:SetPoint("CENTER", 0, 0)
    frame:SetSize(64, 64)
    
    --create the texture 
    frame.texture = frame:CreateTexture(nil, "BACKGROUND")
    
    --enable pixel perfection for the texture, too
    sCore.pp.register(frame.texture)
    
    frame.texture:SetAllPoints(frame)
    frame.texture:SetTexture(0.5, 0.5, 0.5)
    

    
--]]

--upvalue
local string_match = string.match

--upvalue wow api
local CreateFrame, GetScreenResolutions, GetCurrentResolution = CreateFrame, GetScreenResolutions, GetCurrentResolution


local core = namespace.core

local pp = {method = {}}
namespace.core.pp = pp


--note:	its not a class, you can't make multiple objects.

--DISPLAY_SIZE_CHANGED

--TODO if pp._object then ... move it to first line ?
function pp.init()
	if not pp._object then
		local selected_resolution = ({GetScreenResolutions()})[GetCurrentResolution()]
		local resolution_width, resolution_height = string_match(selected_resolution, "(%d+)x(%d+)")
		
		pp._object = CreateFrame("Frame", nil, UIParent)
		pp._config = namespace.config["pp"]
		--mapping table to track replaced functions of frames
    --[[
    map_table = {   
        ["frame1"] = {  
            ["SetPoint"] = function C488F9F1,
            ["Setsize"] = function fC64Fd21,
        },    
        ["frame2"] = {...},
    }
    --]]
		pp._mapping = {}
		
		pp._ui_scale = pp._config["ui_scale"]
		pp._scale_factor = 768/(resolution_height*pp._config["ui_scale"])

		pp._object:RegisterEvent("VARIABLES_LOADED")
		pp._object:SetScript("OnEvent", pp._load)
	end
end


function pp._load()
	SetCVar("uiScale", pp._ui_scale)
	SetCVar("useUiScale", pp._config["enable"] and 1 or 0)
	
  -- initial loading is only required once
  pp._object:UnregisterEvent("VARIABLES_LOADED")
  
  -- enable warnings
  if pp._config["enable"] then
    pp._object:SetScript("OnEvent", function()
      core.warning("UI scale or display resolution changed. sCore.pp module won't function properly. Reload the interface to resolve.")
    end)
  
    pp._object:RegisterEvent("UI_SCALE_CHANGED")
    pp._object:RegisterEvent("DISPLAY_SIZE_CHANGED")
  end
end


function pp.register_method(frame, method_name)
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


function pp.register(frame)
  if pp._config["enable"] then
    for k,_ in pairs(pp.method) do
      --check if the frame has a method called k
      if frame[k] then
        pp.register_method(frame, k)
      end
    end
  end
end


function pp.scale(num_pixels)
    return pp._scale_factor * floor(num_pixels + .5)
end


function pp.get_scale_factor()
	return pp._scale_factor
end


function pp.method.SetHeight(frame, height)
	assert(pp._object, "pp not initialized") 
	pp._mapping[frame]["SetHeight"](frame, pp.scale(height))
end


function pp.method.SetWidth(frame, width)
	assert(pp._object, "pp not initialized") 
	pp._mapping[frame]["SetWidth"](frame, pp.scale(width))
end


function pp.method.SetSize(frame, width, height)
	assert(pp._object, "pp not initialized") 
    if not height then
        height = width
    end
	pp._mapping[frame]["SetSize"](frame, pp.scale(width), pp.scale(height))	
end

--TODO further test this function
function pp.method.SetPoint(frame, point, arg2, arg3, arg4, arg5)
	assert(pp._object, "pp not initialized")
	--first argument will never be a number
  if type(arg2) == "number" then arg2 = pp.scale(arg2) end
  if type(arg3) == "number" then arg3 = pp.scale(arg3) end
  if type(arg4) == "number" then arg4 = pp.scale(arg4) end
  if type(arg5) == "number" then arg5 = pp.scale(arg5) end
	pp._mapping[frame]["SetPoint"](frame, point, arg2, arg3, arg4, arg5)
end


--TODO test
function pp.method.SetFont(frame, font, size, flags)
	assert(pp._object, "pp not initialized")
	--TODO we need to make a point to pixel conversion, then scale and convert back!
	--for now we don't scale
	pp._mapping[frame]["SetFont"](frame, font, pp.scale(size), flags)
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
	--TODO disabled for know. Tests show that edgeSize and the insets DONT need to be scaled to achiev pixel perfection
	--TODO when creating the backdrop table, it's possible that certain values are nil, handle it
	local new_bd = core._table_copy(backdrop_table)

	--new_bd["tileSize"] = pp.scale(new_bd["tileSize"])
	--new_bd["edgeSize"] = pp.scale(new_bd["edgeSize"])
	--new_bd["insets"]["left"] = pp.scale(new_bd["insets"]["left"])
	--new_bd["insets"]["right"] = pp.scale(new_bd["insets"]["right"])
	--new_bd["insets"]["top"] = pp.scale(new_bd["insets"]["top"])
	--new_bd["insets"]["bottom"] = pp.scale(new_bd["insets"]["bottom"])
	pp._mapping[frame]["SetBackdrop"](frame, new_bd)
end


pp.init()




