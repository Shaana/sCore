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

--upvalue
local math_floor = math.floor

local core = namespace.core

local predict = {}
namespace.predict = predict


function predict.new(self, unit, config, parent)
	local object = CreateFrame("Frame", nil, parent)

	--inheritance
	core._inherit(object, predict)
	
	object.config = config
	object.unit = unit

	--Note:	only normalized values are stored!
	object.curent_values = {
		["health"] = 0,	--current health
		["incoming_heal"] = 0, --player's own healing
		["all_incoming_heal"] = 0, --incoming healing from all units
		["absorb"] = 0, --e.g shields
		["heal_absorb"] = 0, --e.g necrotic strike
		["factor"] = 1, --for normalizing the other values
	}
	
	--Note:	normalize everything to width for pixel perfection
	-- max_value = config["width"]
	
	--TODO
	local overflow_width = math_floor(config["overflow_factor"]*config["width"])
	object._overflow_width = overflow_width
	
	
	--TODO
	object:SetPoint(unpack(config["anchor"]))
	object:SetSize(20,20)
	
	--create basic frames
	object.health_bar = CreateFrame("StatusBar", nil, object)
	object.incoming_bar = CreateFrame("StatusBar", nil, object)
	object.all_incoming_bar = CreateFrame("StatusBar", nil, object)
	object.absorb_bar = CreateFrame("StatusBar", nil, object)

	object.health_bar.texture = object.health_bar:SetStatusBarTexture(config["texture"])
	object.incoming_bar.texture = object.incoming_bar:SetStatusBarTexture(config["texture"])
	object.all_incoming_bar.texture = object.all_incoming_bar:SetStatusBarTexture(config["texture"])
	object.absorb_bar.texture = object.absorb_bar:SetStatusBarTexture(config["texture"])
		
	--resize
	object.health_bar:SetSize(config["width"], config["height"])
	object.incoming_bar:SetSize(overflow_width, config["height"])
	object.all_incoming_bar:SetSize(overflow_width, config["height"])
	object.absorb_bar:SetSize(overflow_width, config["height"])


	--anchors
	--DEBUG
	--[[
	object.health_bar:SetPoint("TOPLEFT", object, "TOPLEFT", 0, 0)
	object.incoming_bar:SetPoint("TOPLEFT", object, "TOPLEFT", 0, -30)
	object.all_incoming_bar:SetPoint("TOPLEFT", object, "TOPLEFT", 0, -60)
	object.absorb_bar:SetPoint("TOPLEFT", object, "TOPLEFT", 0, -90)
	--]]
	
	object.health_bar:SetPoint("TOPLEFT", object, "TOPLEFT", 0, 0)
	object.incoming_bar:SetPoint("TOPLEFT", object, "TOPLEFT", 0, 0)
	object.all_incoming_bar:SetPoint("TOPLEFT", object, "TOPLEFT", 0, 0)
	object.absorb_bar:SetPoint("TOPLEFT", object, "TOPLEFT", 0, 0)

	--framelevel
	object.health_bar:SetFrameLevel(5)
	object.incoming_bar:SetFrameLevel(4)
	object.all_incoming_bar:SetFrameLevel(3)
	object.absorb_bar:SetFrameLevel(2)
	

	--DEBUG coloring
	object.health_bar:SetStatusBarColor(0,0,1)
	object.incoming_bar:SetStatusBarColor(0,1,0)
	object.all_incoming_bar:SetStatusBarColor(.5,1,0)
	object.absorb_bar:SetStatusBarColor(1,0,0)
	
	--maxvalue
	object.health_bar:SetMinMaxValues(0, config["width"])
	object.incoming_bar:SetMinMaxValues(0, overflow_width)
	object.all_incoming_bar:SetMinMaxValues(0, overflow_width)
	object.absorb_bar:SetMinMaxValues(0, overflow_width)
	
	--events
	object:RegisterEvent("UNIT_HEAL_PREDICTION")
	object:RegisterEvent("UNIT_MAXHEALTH")
	if config["frequent_update"] then
		object:RegisterEvent("UNIT_HEALTH_FREQUENT")
	else
		object:RegisterEvent("UNIT_HEALTH")
	end
	object:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
	object:RegisterEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED")

	object:RegisterEvent("PLAYER_ENTERING_WORLD")
	
	object:SetScript("OnEvent", self.update)

	

	return object
end

--Note:	update order matters !
--use this order: factor, health, inc_heal, absorbs

--TODO add dummy coloring to check if your heal will overheal ?

--TODO is there a better way to slove this ? with smart anchors ? --> less updating
function predict.update(self, event, unit)
	if not (unit == nil or self.unit == unit) then 
		return 
	end
	
	print(event, unit)
	
	--TODO is it really needed to update everything ?
	if event == "UNIT_MAXHEALTH" then
		self:update_factor()
		self:update_health()
		self:update_incoming_heal()
		self:update_absorb()
	
	elseif event == "UNIT_HEALTH_FREQUENT" or event == "UNIT_HEALTH" then
		self:update_health()
		self:update_incoming_heal()
		self:update_absorb()
	
	elseif event == "UNIT_HEAL_PREDICTION" then
		self.curent_values["incoming_heal"] = math_floor(self.curent_values["factor"]*(UnitGetIncomingHeals(self.unit, "player") or 0))
		self.curent_values["all_incoming_heal"] = math_floor(self.curent_values["factor"]*(UnitGetIncomingHeals(self.unit) or 0))
		self:update_incoming_heal()
		self:update_absorb()
	
	elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
		self.curent_values["absorb"] = math_floor(self.curent_values["factor"]*(UnitGetTotalAbsorbs(self.unit)))
		self:update_absorb()
	
	elseif event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" then
		--TODO
	
	
	elseif event == "PLAYER_ENTERING_WORLD" then
		self:update_factor()
		self:update_health()
		self:update_incoming_heal()
		self:update_absorb()
		
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end
	

end

function predict.update_factor(self)
	self.curent_values["factor"] = self.config["width"]/UnitHealthMax(self.unit)
end

function predict.update_health(self)
	self.curent_values["health"] = math_floor(self.curent_values["factor"]*UnitHealth(self.unit))
	self.health_bar:SetValue(self.curent_values["health"])
end


--local inc = {"incoming_heal", "all_incoming_heal"} 
--tODO doesnt work, cause self nil probably
--predict.__inc = {["incoming_heal"] = self.incoming_bar, ["all_incoming_heal"] = self.all_incoming_bar}

function predict.update_incoming_heal(self)
	--TODO maybe do some fancy for i=1, 2 do ...
	--player's incoming heal
	if self.curent_values["incoming_heal"] > 0 then
		local total = self.curent_values["incoming_heal"] + self.curent_values["health"]
		if total <= self._overflow_width then -- or statusMin, statusMax = self.incoming_bar:GetMinMaxValues()
			self.incoming_bar:SetValue(total)
		else 
			self.incoming_bar:SetValue(self._overflow_width)
		end
		self.incoming_bar:Show()
	else
		self.incoming_bar:Hide()
	end
	
	--all units
	if self.curent_values["all_incoming_heal"] > 0 then
		local total = self.curent_values["all_incoming_heal"] + self.curent_values["health"]
		if total <= self._overflow_width then -- or statusMin, statusMax = self.incoming_bar:GetMinMaxValues()
			self.all_incoming_bar:SetValue(total)
		else 
			self.all_incoming_bar:SetValue(self._overflow_width)
		end
		self.all_incoming_bar:Show()
	else
		self.all_incoming_bar:Hide()
	end

	
	
	--self.all_incoming_bar:SetValue(math_floor())
end

function predict.update_absorb(self)
	--TODO
	--totalHealAbsorbs = UnitGetTotalHealAbsorbs("unit")
	
	if self.curent_values["absorb"] > 0 then
		local total = self.curent_values["absorb"] + self.curent_values["all_incoming_heal"] + self.curent_values["health"]
		if total <= self._overflow_width then -- or statusMin, statusMax = self.incoming_bar:GetMinMaxValues()
			self.absorb_bar:SetValue(total)
		else 
			self.absorb_bar:SetValue(self._overflow_width)
		end
		self.absorb_bar:Show()
	else
		self.absorb_bar:Hide()
	end
	
end

function predict.update_all(self)

end



p = predict:new("player", namespace.config["health"], UIParent)

