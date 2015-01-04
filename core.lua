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



local function is_instance(object, class)
  if object.__instance == class.__instance then
    return true
  end
  return false
end
core.is_instance = is_instance

--This is the new version of the inherit function and will replace _inherit in the future
local function inherit(object, class, secure)
  assert(type(class) == "table")
  if secure then
    --just create links
    for k,v in pairs(class) do
      object[k] = v
    end
  end
  --use meta tables for the inheritance
  local parent = {class, getmetatable(object).__index}
  setmetatable(object, class)
  class.__index = function(t,k)
    for i=1, #parent do
      local v = parent[i][k]
      if v then
        return v
      end
    end
  end
end
core.inherit = inherit

--TODO outdated, use upper inherit function
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
core._table_copy = _table_copy --TODO remove _


local function si_value(value)
  if value >= 1e6 then
    return ("%.0f m"):format(value*1e-6)
  elseif value >= 1e3 then
    return ("%.0f k"):format(value*1e-3)
  else
    return value
  end
end
core.si_value = si_value

local function format_time(time, show_msec, show_sec, show_min, show_hour)
  if time < (show_msec or 2) then
    return ("%.1f"):format(time)
  elseif time < (show_sec or 60) then
    return ("%.0f"):format(time)
  elseif time < (show_min or 3600) then --60*60
    return ("%.0f m"):format(time/60)
  elseif time < (show_hour or 86400) then --60*60*24
    return ("%.0f h"):format(time/3600)
  else
    return ("%.0f d"):format(time/86400)
  end
end
core.format_time = format_time



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




