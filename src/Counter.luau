--[[--
    Quick Start and API can be found at
    https://github.com/Coffilhg/Useful-Modules/tree/Counter

    Counter
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

    Full License & Notices: https://github.com/Coffilhg/Useful-Modules/tree/Counter
    Module Version: 1.0.0
--]]--

--- Dependencies (Not By @Coffilhg) ---

-- Signal's Source Repository: https://github.com/stravant/goodsignal/blob/master/README.md --
local Signal = require(script.GoodSignal_By_Stravant) -- or wherever it's located and whatever it's named

--- /E Dependencies (Not By @Coffilhg) ---

local Counter = {}

function Counter.new(interval : number?)
	return setmetatable(
		{
			count = 0,
			interval = (interval and type(interval) == "number") and interval or 60,
			_taskId = 0,
			Changed = Signal.new(),
		}, Counter
	)
end

function Counter:clear()
	if self.count == 0 then
		return self -- already 0, no need to increment the _taskId
	end
	self._taskId += 1 -- cancels all task delays, that were create before
	self.count = 0
	return self
end

function Counter:setInterval(interval : number?)
	-- this will fire __newindex, which handles everything
	self.interval = (interval and type(interval) == "number") and interval or 60
	return self
end



--- Metamethods ---

Counter.__index = Counter

function Counter:__newindex(key, value)
	if key == "interval" then
		self:clear()
	end
	rawset(self, key, value)
end

function Counter:__tostring()
	return `{self.count}`
end

function Counter:__call()
	self.count += 1
	self.Changed:Fire()

	local taskId = self._taskId
	task.delay(self.interval, function()
		if self._taskId ~= taskId then
			return
		end
		
		self.count -= 1
		self.Changed:Fire()
	end)
	
	return self.count
end



return Counter