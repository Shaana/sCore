--[[
Copyright (c) 2008-2015 Shaana <shaana@student.ethz.ch>
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
along with sCore. If not, see <http://www.gnu.org/licenses/>.
--]]

local setmetatable, pairs = setmetatable, pairs

local addon, namespace = ...

local config = {}
namespace.config = config

---config section
config["core"] = {
	["show_error"] = true,
	["show_warning"] = true,
	["show_debug"] = true,
}

config["pp"] = {
	["enable"] = true,
	["ui_scale"] = 0.7, --nil or 0.64 to 1; nil turns it off
}

config["console"] = {
	["enable"] = true,
	
}

config["aura"] = {
	 ["__index"] = config["core"],
}


--inheritance for the config
for k,_ in pairs(config) do 
	setmetatable(config[k], config[k])
end

