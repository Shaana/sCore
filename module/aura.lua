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

--[[
Example

local config = {

}

local h = header:new(config)

--]]











--[[
local addon, namespace = ...

--upvalue


local core = namespace.core
local pp = namespace.pp

local button = {}
namespace.button = icon

local header = {}
namespace.header = header

local core = namespace.core

--TODO get ride of that template poop
--just put everythig into the config

--only needed in _set_attribute(header, attribute)
local pp_attributes = {"xOffset", "yOffset", "wrapXOffset", "wrapYOffset"}

local function _set_attribute(header, attribute)
	assert(type(attribute) == "table")
	
	--inheritance
	if type(attribute.__index) == "table" then
		_set_attribute(header, attribute.__index)
	end
	for k,v in pairs(attribute) do
		if k ~= "__index" then
			--TODO check if scalling really works
			--pixel perfection
			if pp.loaded() then
				for _,b in ipairs(pp_attributes) do
					if b == k then
						print("scalling", k, v)
						v = pp.scale(v)
						print(v, pp._scale_factor)
						break
					end
				end
			end
			header:SetAttribute(k,v)
		end
	end
end

local function set_attribute(header,attribute)
	--temporary disable SecureAuraHeader_OnAttributeChanged
	local old_ignore = header:GetAttribute("_ignore")
	
	header:SetAttribute("_ignore", "attributeChanges")
	_set_attribute(header, attribute)
	header:SetAttribute("_ignore", old_ignore)
end


---header class
--handles objects created by the button class
function header.new(self, config, template)
	local object = CreateFrame("Frame", config["name"], config["parent"], template)
	
	--inheritance
	if template then
		--Note:	Tempering with the metatable causes the the secure template to break
		--		Therefore we inherit the options with a function. (basically creating links to each of the class functions)
		core._inherit(object, header)
	else
		--inherit functions from two objects (listed in parent table)
		local parents = {self, getmetatable(object).__index}
		setmetatable(object, self)
		self.__index = function(t,k)
			for i=1, 2 do --#parents = 2
				local v = parents[i][k]
				if v then
					return v
				end
			end
		end
	end
	
	--add pixel perfection
	if pp.loaded() then
		pp.add_all(object)
	end
	
	object.config = config
	object.button = {} --here we put the list of buttons created by the button class
	
	object:SetPoint(unpack(config["anchor"]))
	
	if template and attribute then
		--Note:	the inheritance of the attribute config happens in this function
		set_attribute(object, attribute)
		
		--Note: the maximum number buffs/debuffs a unit can have is 40
		local max_aura_with_wrap = object:GetAttribute("wrapAfter")*object:GetAttribute("maxWraps")
		object.max_aura = max_aura_with_wrap > 40 and 40 or max_aura_with_wrap
	
		if object.config["helpful"] and object:GetAttribute("includeWeapons") == 1 then
			--TODO During the first login UNIT_INVENTORY_CHANGED is fired 30+ times (caching of inventory?) - might wanna do something about that
			object:RegisterEvent("UNIT_INVENTORY_CHANGED")
		end
	
	else
		object.max_aura = 40	
					
		--Note:	The UNIT_INVENTORY_CHANGED event is necessary for buff headers, because when a new TempEnchant is applied/weapon are being switched UNIT_AURA is fired and immediately afterwards UNIT_INVENTORY_CHANGED,
		--		but only after UNIT_INVENTORY_CHANGED was fired the new icon returned by GetInventoryItemTexture() is available
		--		For some reason button.update_temp_enchant(self) is only called once! (some smart blizzard code?)
				
		--if object.config["helpful"] and object:GetAttribute("includeWeapons") == 1 then
		--	--TODO During the first login UNIT_INVENTORY_CHANGED is fired 30+ times (caching of inventory?) - might wanna do something about that
		--	object:RegisterEvent("UNIT_INVENTORY_CHANGED")
		--end
	end
	
	
	--vehicle support
	if object.config["display_vehicle_aura"] then
		object:RegisterEvent("UNIT_ENTERED_VEHICLE")
		object:RegisterEvent("UNIT_EXITED_VEHICLE")
	end
	
	--pet battle support (hide frames during a battle)
	object:RegisterEvent("PET_BATTLE_CLOSE")
	object:RegisterEvent("PET_BATTLE_OPENING_START")

	--this will run SecureAuraHeader_Update(header), if we use a template
	object:Show()
	object:HookScript("OnEvent", self.update)
	
	return object
end

function header.update(self, event, unit)

end



function button.new(self, header, config)

end

function button.update(self)

end



--TEMP
local config = {}
config["default"] = {
	--attribute part
	["horizontal_spacing"] = 10,
	["vertical_spacing"] = 28,
	["grow_direction"] = "LEFTDOWN",

	["wrap_after"] = 12,
	["sort_method"] = "TIME",
	["sort_direction"] = "-",
	
	--rest
	["size"] = {64, 64}, --width, height
	
	["border_texture"] = "Interface\\AddOns\\sBuff2\\media\\Border64",
	["border_texture_size"] = {64, 64},
	["border_inset"] = 4, --depends on texture

	["gloss_texture"] = "Interface\\AddOns\\sBuff2\\media\\Gloss64",
	["gloss_texture_size"] = {64, 64},
	["gloss_color"] = {0.2, 0.2, 0.2, 1},
	
	["count_font"] = {"Interface\\AddOns\\sBuff2\\media\\skurri.TTF", 22, "OUTLINE"},
	["count_color"] = {1,1,1,1},
	["count_x_offset"] = -6,
	["count_y_offset"] = 8,
	
	["expiration_font"] = {"Interface\\AddOns\\sBuff2\\media\\skurri.TTF", 18, "OUTLINE"},
	["expiration_color"] = {1,1,1,1},
	["expiration_x_offset"] = 2,
	["expiration_y_offset"] = 0,
	
	["update_format"] = {2,60,3600,86400}, --{msec, sec, min, hour}, e.g time_remaning < sec --> show seconds
	["update_frequency"] = {0.05,0.2,20,60,300},
	
	["display_vehicle_aura"] = false, --true/false display vehicle auras when in a vehicle instead of unit aura
	
}

config["buff"] = {
	["__index"] = config["default"],
	["helpful"] = true, --simple true/false to check if it's a buff or debuff header
	["anchor"] = {"TOPRIGHT", UIParent, "TOPRIGHT", -250, -15}, --{"CENTER", UIParent, "CENTER", 0, 0},
	["border_color"] = {0.4, 0.4, 0.4, 1},
	["includeWeapons"] = 1, --only has effect for buff headers
	["max_wraps"] = 3,
}

config["debuff"] = {
	["__index"] = config["default"],
	["helpful"] = false, --simple true/false to check if it's a buff or debuff header
	["anchor"] = {"TOPRIGHT", UIParent, "TOPRIGHT", -250, -266}, --{"CENTER", UIParent, "CENTER", 0, -200},
	["border_color"] = {0.8, 0, 0, 1},
	["max_wraps"] = 5,
}

local h = header:new(config["test"], "SecureAuraHeaderTemplate", attribute["test"], "my_headers_name")
--local h = header:new(config["test"])
--TEMP END


print("LOADING__3")

--]]











