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

local config = {}
namespace.config = config

---config section
config["default"] = {
	--["__index"] = config["core"],
	--["font"] = {"Interface\\AddOns\\sBuff2\\media\\skurri.TTF", 18, "OUTLINE"},
	["test"] = true,
}

--inheritance for the config
for k,_ in pairs(config) do 
	setmetatable(config[k], config[k])
end

