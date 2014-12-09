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

local core = namespace.core


--upvalue wow api
local GetTime = GetTime


local castbar = {}
namespace.castbar = castbar

--"UNIT_TARGET"
--[[
	object:RegisterEvent("UNIT_SPELLCAST_START")
	object:RegisterEvent("UNIT_SPELLCAST_STOP")
	object:RegisterEvent("UNIT_SPELLCAST_FAILED")
	object:RegisterEvent("UNIT_SPELLCAST_DELAYED")
	object:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	object:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
	object:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
	object:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	object:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
	object:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")

--]]

function castbar.new(self, config)
	local object = CreateFrame("Frame", config["name"], config["parent"])
	
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
	
	object.config = config
	
	--properties of the spell being cast
	object.property = {
		["name"] = nil,
		["text"] = nil,
		["texture"] = nil,
		["cast_id"] = -1,
		["duration"] = 0,
		["max"] = 0, --TODO rename, duration should be max
		["delay"] = 0,
		["casting"] = false,
		["channeling"] = false,
		["interruptible"] = 1, --nil or 1
	}

	
	object.bar = CreateFrame("StatusBar", nil, object)
	--object.bar.bg = object.bar:
	
	object.bar:SetSize(200,30)
	object.bar:SetPoint("CENTER", UIParent, "CENTER", 0,0)
	object.bar.texture = object.bar:SetStatusBarTexture("Interface\\AddOns\\sNameplates\\media\\barSmall")
	
	object.text = {}
	object.text.name = object:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	

	
	--events
	--object:RegisterEvent("UNIT_TARGET") --TODO needed ?
	object:RegisterEvent("UNIT_SPELLCAST_START")
	object:RegisterEvent("UNIT_SPELLCAST_STOP")
	object:RegisterEvent("UNIT_SPELLCAST_FAILED")
	object:RegisterEvent("UNIT_SPELLCAST_DELAYED")
	object:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	object:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	object:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
	object:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
	object:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	object:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
	object:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	
	object.bar:SetValue(0)
	object:SetScript("OnEvent", self.update)
	
	return object
end
print("loading castbar1")
local cast_event = {
	--[[
	["UNIT_SPELLCAST_START"] = function(self, spell) -- spell is the spell name
		
	end,
	
	["UNIT_SPELLCAST_STOP"] = function(self, spell, rank, line_id, spell_id)
		
	end,
	
	-- "spell", "rank", lineID, spellID
	["UNIT_SPELLCAST_FAILED"] = function(self, sepll, _, cast_id)
		
	end,
	--]]
}
print("loading castbar2")
function cast_event.UNIT_SPELLCAST_START(self, spell) --, cast_id, spell_id
	local name, _, text, texture, start_time, end_time, _, cast_id, interruptible = UnitCastingInfo(self.config["unit"])
	
	--Note: startTime - Time at which the cast was started (in milliseconds; can be compared to GetTime() * 1000)
	end_time = end_time / 1e3
	start_time = start_time / 1e3
	
	self.property["name"] = name --prob not needed
	self.property["text"] = text --prob not needed
	self.property["texture"] = texture --prob not needed
	self.property["cast_id"] = cast_id
	self.property["duration"] = GetTime() - start_time
	self.property["max"] = end_time - start_time --prob not needed 
	self.property["casting"] = true
	self.property["delay"] = 0
	self.property["interruptible"] = interruptible

	self.bar:SetMinMaxValues(0, self.property["max"])
    self.bar:SetValue(0)

	--TODO set some texts, etc.

	self.text.name:SetText(text)
	
	self:Show()
	
	self:SetScript("OnUpdate", self._update_casting)
end
print("loading castbar3")
function cast_event.UNIT_SPELLCAST_STOP(self, spell, rank, cast_id, spell_id)
	if(self.property["cast_id"] ~= cast_id) then
		return
	end
	
	self.property["casting"] = false
	self.bar:SetValue(0)
	self.bar:Hide()
end

function cast_event.UNIT_SPELLCAST_FAILED(self, spell, rank, cast_id, spell_id)
	if(self.property["cast_id"] ~= cast_id) then
		return
	end
	
	self.property["casting"] = false
	self.bar:SetValue(0)
	self.bar:Hide()
end
print("loading castbar4")
function cast_event.UNIT_SPELLCAST_DELAYED(self, spell, rank, cast_id, spell_id)
    local name, _, text, texture, start_time, end_time = UnitCastingInfo(self.config["unit"])
    if not start_time then
    	print("[!] d.Error: no start_time in event_delayed") 
    end
    if not self.bar:IsShown() then 
    	print("[!] d.Error: event_delay called, even though bar is hidden")  
    end

    local duration = GetTime() - (start_time / 1000)
    if(duration < 0) then
    	print("[!] d.Error: event_delay called, duration < 0")  
    	duration = 0 
    end --needed ?oO

    self.property["delay"] = self.property["delay"] + self.property["duration"] - duration
    self.property["duration"] = duration

	--TODO enable
	--if onupdate is running at same time ? might give a conflict
	--maybe better write to property table ?
    self.bar:SetValue(duration)
    print(self.property["delay"])
end

print("loading castbar4.5")
--Note: this might also be called when the unit was channeling a spell and got interrupted
function cast_event.UNIT_SPELLCAST_INTERRUPTED(self, spell, rank, cast_id, spell_id)
	if(self.property["cast_id"] ~= cast_id) then
		return
	end
	self.property["casting"] = false
	self.property["channeling"] = false
	self.bar:SetValue(0)
	self.bar:Hide()
end

function cast_event.UNIT_SPELLCAST_SUCCEEDED(self, spell, rank, cast_id, spell_id)
	print("yeah, casted :)")
	--TODO remove OnUpdate script ?
end



function cast_event.UNIT_SPELLCAST_INTERRUPTIBLE(self)
 self.property["interruptible"] = 1
end

function cast_event.UNIT_SPELLCAST_NOT_INTERRUPTIBLE(self)
	self.property["interruptible"] = nil
end

function cast_event.UNIT_SPELLCAST_CHANNEL_START(self, spell, rank, cast_id, spell_id)

end

function cast_event.UNIT_SPELLCAST_CHANNEL_UPDATE(self, spell, rank, cast_id, spell_id)

end

function cast_event.UNIT_SPELLCAST_CHANNEL_STOP(self, spell, rank, cast_id, spell_id)

end

print("loading castbar5")



function castbar.update(self, event, unit, ...)
	if self.config["unit"] ~= unit then
		return
	end
	--DEBUG
	print("update", event, unit, ...)
	cast_event[event](self, ...)
end


function castbar._update_casting(self, elapsed)
	--TODO throttle
	--if self.config["update_frequency"]
	print(self.property["max"])
	if self.property["casting"] then
		local cur = self.bar:GetValue() + elapsed
		if cur <= self.property["max"] then	
			self.bar:SetValue(cur)
		else
			--self:SetScript("OnUpdate", nil)
			print("[!] d.error value > max")
		end
	else
		--TODO remove script
		--self:SetScript("OnUpdate", nil)
	end


end
print("loading castbar7")
function castbar._update_channeling()

end

--DEBUG
local config = {}
config["player"] = {
	["name"] = nil,
	["parent"] = UIParent,
	["unit"] = "player",
	["update_frequency"] = 0.1,
}

--print("loading castbar")
--local c = castbar:new(config["player"])


