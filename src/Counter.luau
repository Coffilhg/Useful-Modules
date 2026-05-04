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
local Signal = require(script.Parent.GoodSignal) -- or wherever it's located and whatever it's named

--- /E Dependencies (Not By @Coffilhg) ---

local Counter = {}

-- Type Defs
export type Counter = setmetatable<{
 count: number,
 startValue: number,
 interval: number,
 _taskId: number,
 Changed: Signal.Connection
}, typeof(Counter)>


-- creates new 'Counter' metatable
--@param interval number? - task interval after start fn in '__call' method (def: 60s)
--@param default number? - start value for counter (also uses for ':clear()' fn)
--@return self Counter
function Counter.new(interval : number?, default: number?): Counter
        local startValue: number = ((default and type(default) == "number") and default) or 0
	return setmetatable(
		{
			count = startValue,
                        startValue = startValue, 
			interval = (interval and type(interval) == "number") and interval or 60,
			_taskId = 0,
			Changed = Signal.new(),
		}, Counter
	) :: Counter
end

-- set 'Counter.count' to default
--@return self Counter
function Counter:clear(): Counter
	if self.count == self.startValue then
		return self -- already startValue, no need to increment the _taskId
	end
	self._taskId += 1 -- cancels all task delays, that were create before
	self.count = self.startValue
	return self
end

-- sets new interval for Counter
--@param interval number? - new interval
--@return self Counter
function Counter:setInterval(interval : number?): Counter
	-- this will fire __newindex, which handles everything
	self.interval = (interval and type(interval) == "number") and interval or 60
	return self
end

-- destroy whole Counter with cleanup
function Counter:destroy(): ()
	self._taskId += 1
	self.Changed:Destroy()
end



--- Metamethods ---

-- making availavle to use 'Counter' with all available fns
Counter.__index = Counter

-- set new index to Counter, also handle 'clear()' if '__newindex' it's an interval
--@param key Key
--@param value Value
function Counter:__newindex<Key, Value>(key: Key, value: Value): ()
       if key == "count" then
	   error("Cannot set 'count' directly. Use __call or clear()", 2)
       end
       if key == "interval" then
           self:clear()
       end
       rawset(self, key, value)
   end

-- converts 'Counter' to string for debug/output
--@return string
function Counter:__tostring(): string
       return `Counter(count={self.count}, startValue={self.startValue}, _taskId={self._taskId})`
end

-- increments the count, fires 'Changed' signal, schedules an automatic decrement after interval,
-- and returns newCount (=+1 from old)
--@return newCount number - new count 
function Counter:__call()
	self.count += 1
        local newCount: number = self.count
	self.Changed:Fire()

	local taskId = self._taskId
	task.delay(self.interval, function()
		if self._taskId ~= taskId then
			return
		end
		
		self.count -= 1
		self.Changed:Fire()
	end)
	
	return newCount
end



return Counter
