--[[--
    Quick Start and API can be found at
    https://github.com/Coffilhg/Useful-Modules/tree/Arrangement

    Arrangement
    Copyright © 2026 Coffilhg (Roblox UserId 517222346)
    
    

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    Full License & Notices: https://github.com/Coffilhg/Useful-Modules/tree/Arrangement
    Module Version: 1.0.0
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