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

local assert, type, pairs, getmetatable, setmetatable = assert, type, pairs, getmetatable, setmetatable
local _G = _G

local addon, namespace = ...

--expose sCore to be used by other addons
_G.sCore = namespace

local core = {}
namespace.core = core

local class = {}
namespace.class = class

--inherit function for lua class implementations
local function _inherit(object, class)	
	assert(type(class) == "table")
	for k,v in pairs(class) do
		object[k] = v
	end
end
core._inherit = _inherit

--deep table copy function
local function _table_copy(t)
	if type(t) ~= "table" then
		return t
	end
	
	local mt = getmetatable(t)
	local new_table = {}
	
	for k,v in pairs(t) do
		if type(v) == "table" then
			v = _table_copy(v)
		end
		new_table[k] = v
	end	
	
	setmetatable(new_table, mt)
	return new_table
end
core._table_copy = _table_copy



--[[
--check for config integrety
--TODO replace this with some proper check function
--maybe move to sCore ? make something a little less specific

local function check_config_integrity()
	--make this function set default values as well ?
	--if attribute "includeWeapons", 1 given, we expect  "weaponTemplate", buffTemplate as well
	--__attribte expected for the coresponding table
	--anchor expected
end
core.check_config_integrity = check_config_integrity


local function check_attribute_integrity()

end
core.check_attribute_integrity = check_attribute_integrity
--]]




