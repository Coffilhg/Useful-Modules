--[[--
    Arrangement V1.0.0
    Copyright © 2026 Coffilhg (Roblox UserId 517222346)

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/.

    GitHub Repository/Branch with latest version, documentation, etc:
    https://github.com/Coffilhg/Useful-Modules/tree/Arrangement
    Stars are appreciated!
--]]--

local Arrangement = {}

local function ReadOnly()
	error("Table is read only!")
end
local function GetKeyByIndexMethod(self, index : number)
	return rawget(rawget(self, "r"), index)
end

-- indexing starts at 0, but it doesn't matter if you just
-- let the system work as it's originally designed to
function Arrangement.new()
	return setmetatable({
		a = setmetatable({}, {__newindex = ReadOnly}), -- [key] = number; arrangements
		r = setmetatable({}, {__newindex = ReadOnly}), -- [number] = key; reversed (arrangements reversed to be an array)
		n = 0,
		GetKeyByIndex = GetKeyByIndexMethod,
	}, {
		__newindex = ReadOnly,
		__index = function(self, key)
			local arrangements = rawget(self, "a")
			local index = rawget(arrangements, key)
			if index == nil then
				index = rawget(self, "n")
				rawset(self, "n", index + 1)
				rawset(arrangements, key, index)
				rawset(rawget(self, "r"), index, key)
			end
			return index
		end,
	})
end

return Arrangement