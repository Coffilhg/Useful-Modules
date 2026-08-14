--[[--
    Counter V1.0.1
    Copyright © 2026 Coffilhg (Roblox UserId 517222346)

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/.

    GitHub Repository/Branch with latest version, documentation, etc:
    https://github.com/Coffilhg/Useful-Modules/tree/Counter
    Stars are appreciated!
--]]--

--- Dependencies (Not By @Coffilhg) ---

-- Signal's Source Repository: https://github.com/Data-Oriented-House/LemonSignal --
local Signal = require(script.Parent.LemonSignal) -- or wherever it's located and whatever it's named

--- /E Dependencies (Not By @Coffilhg) ---

local Counter = {}

-- Type Defs
export type Counter = setmetatable<{
    count: number,
    startValue: number,
    interval: number,
    _taskId: number,
	Changed: Signal.Signal<>,
	new: (interval : number?, default: number?) -> Counter,
	clear: (self: Counter) -> Counter,
	setInterval: (self: Counter, interval : number?) -> Counter,
	destroy: (self: Counter) -> (),
}, {
	__call: (self: Counter) -> number,
	__tostring: (self: Counter) -> number,
}>


-- creates new 'Counter' metatable
--@param interval number? - task interval after start fn in '__call' method (def: 60s)
--@param default number? - start value for counter (also uses for ':clear()' fn)
--@return self Counter
function Counter.new(interval : number?, default: number?): Counter
    local startValue: number = type(default) == "number" and default or 0
    
	return setmetatable(
		{
			count = startValue,
            startValue = startValue, 
			interval = type(interval) == "number" and interval or 60,
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
	
	self._taskId += 1 -- cancels all task delays, that were created before
	self.count = self.startValue
	return self
end

-- sets new interval for Counter
--@param interval number? - new interval
--@return self Counter
function Counter:setInterval(interval : number?): Counter
	-- this will fire __newindex, which handles everything
	self.interval = type(interval) == "number" and interval or 60
	self:clear()
	return self
end

-- destroy whole Counter with cleanup
-- remember to erase all references so the
-- base table is GC'ed!
function Counter:destroy(): ()
	self._taskId += 1
	self.Changed:Destroy()
end



--- Metamethods ---

-- making available to use 'Counter' with all available functions
Counter.__index = Counter

-- __newindex removed because it wasn't working anyways
-- you're free to change anything, but this is not
-- recommended and might lead to errors;
-- Recommended usage - :setInterval method;
-- to fix this a proxy approach could've been used, but
-- this module is intended to be fast rather than safe
-- proxy approach means more table acesses per use
-- for pro-users - do your stuff and call :clear method!

-- converts 'Counter' to string for debug/output
--@return string
function Counter:__tostring(): string
    return `Counter(count={self.count}, startValue={self.startValue}, _taskId={self._taskId})`
end

-- increments the count, fires 'Changed' signal, schedules an automatic decrement after interval,
-- and returns newCount (=+1 from old)
--@return newCount number - new count 
function Counter:__call()
	local newCount: number = self.count + 1
	
	self.count = newCount
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