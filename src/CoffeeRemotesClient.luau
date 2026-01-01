--[[--
    Quick Start and API can be found at
    https://github.com/Coffilhg/Useful-Modules/tree/CoffeeRemotes

    CoffeeRemotes (CoffeeRemotesClient)
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

    Full License & Notices: https://github.com/Coffilhg/Useful-Modules/tree/CoffeeRemotes
    Module Version: 1.0.0
--]]--

local RS = game:GetService("ReplicatedStorage")
local RemoteEvent = RS:WaitForChild("CoffeeRemotes_Event", 30) :: RemoteEvent
local RemoteFunction = RS:WaitForChild("CoffeeRemotes_Function", 30) :: RemoteFunction
local UnreliableRemoteEvent = RS:WaitForChild("CoffeeRemotes_Unreliable", 30) :: UnreliableRemoteEvent
	
if not (RemoteEvent and RemoteFunction and UnreliableRemoteEvent) then
	warn(`One or multiple of the following (RemoteEvent / RemoteFunction / UnreliableRemoteEvent) were not found.\n"Did you forget to require(CoffeeRemotesServer)?\nDid you accidently modify the RemoteEvent/RemoteFunction/UnreliableRemoteEvent names on Client-side/Server-side versions?\nMake sure RemoteEvent AND RemoteFunction AND UnreliableRemoteEvent names are mathching on both versions (Client-side AND Server-side)"}\nRemoteEvent Status: {RemoteEvent and "Found" or "nil (Not Found)"}\nRemoteFunction Status: {RemoteFunction and "Found" or "nil (Not Found)"}\nUnreliableRemoteEvent Status: {UnreliableRemoteEvent and "Found" or "nil (Not Found)"}\nSomething Might Not Work Correctly`)
	if not RemoteEvent then
		RemoteEvent = RS:WaitForChild("CoffeeRemotes_Event")
	end
	if not RemoteFunction then
		RemoteFunction = RS:WaitForChild("CoffeeRemotes_Function")
	end
	if not UnreliableRemoteEvent then
		UnreliableRemoteEvent = RS:WaitForChild("CoffeeRemotes_Unreliable")
	end
end

--- Dependencies (Not By @Coffilhg) ---

-- Signal's Source Repository: https://github.com/stravant/goodsignal/blob/master/README.md --
local Signal = require(script.GoodSignal_By_Stravant) -- or wherever it's located and whatever it's named

--- /E Dependencies (Not By @Coffilhg) ---



local module = {}

function module:FireServer(eventName : string, ...)
	RemoteEvent:FireServer(eventName, ...)
end
local EventSignals = {} :: {[string]: Signal.Signal}
function module:ConnectEvent(eventName : string, callback : ((any)) -> ()) : Signal.Connection
	local EventSignal = EventSignals[eventName]
	if not EventSignal then
		EventSignal = Signal.new()
		EventSignals[eventName] = EventSignal
	end
	return EventSignal:Connect(callback)
end
function module:DisconnectEvent(eventName : string)
	local EventSignal = EventSignals[eventName]
	if not EventSignal then
		return
	end
	EventSignal:DisconnectAll()
end
function module:DestroyEvent(eventName : string)
	module:DisconnectEvent(eventName)
	EventSignals[eventName] = nil
end
RemoteEvent.OnClientEvent:Connect(function(eventName : string, ...)
	local EventSignal = EventSignals[eventName]
	if not EventSignal then
		return
	end
	
	EventSignal:Fire(...)
end)









function module:InvokeServer(eventName : string, ...)
	return RemoteFunction:InvokeServer(eventName, ...)
end
local OnInvokeCallbacks = {} :: {[string]: (...any) -> (boolean, {})}
-- callback shall return a (success, result); Where success is a boolean (true / false) and result a table (recommended)
function module.OnInvoke(eventName : string, callback : (...any) -> (boolean, {}))
	if OnInvokeCallbacks[eventName] then
		warn(`OnInvoke Callback for eventName="{eventName}" already exists; Overwriting.`)
	end
	OnInvokeCallbacks[eventName] = callback
end
-- Sets the callback for the given eventName; If a callback was given before, it basically gets discarded.
function module.DiscardOnInvoke(eventName : string)
	OnInvokeCallbacks[eventName] = nil
end
function module:DestroyFunction(eventName : string) -- exists solely to fit typing as if we were using server-side of CoffeeRemotes
	module.DiscardOnInvoke(eventName)
end
RemoteFunction.OnClientInvoke = function(eventName : string, ...)
	local OnInvokeCallback = OnInvokeCallbacks[eventName]
	if not OnInvokeCallback then
		return false, {`OnClientInvoke Callback for eventName="{eventName}" doesn't exist`}
	end

	return OnInvokeCallback(...)
end









function module:FireUnreliableServer(eventName : string, ...)
	UnreliableRemoteEvent:FireServer(eventName, ...)
end
local UnreliableEventSignals = {} :: {[string]: Signal.Signal}
function module:ConnectUnreliableEvent(eventName : string, callback : (...any) -> ()) : Signal.Connection
	local EventSignal = UnreliableEventSignals[eventName]
	if not EventSignal then
		EventSignal = Signal.new()
		UnreliableEventSignals[eventName] = EventSignal
	end
	return EventSignal:Connect(callback)
end
function module:DisconnectUnreliableEvent(eventName : string)
	local EventSignal = UnreliableEventSignals[eventName]
	if not EventSignal then
		return
	end
	EventSignal:DisconnectAll()
end
function module:DestroyUnreliableEvent(eventName : string)
	module:DisconnectUnreliableEvent(eventName)
	UnreliableEventSignals[eventName] = nil
end
UnreliableRemoteEvent.OnClientEvent:Connect(function(eventName : string, ...)
	local EventSignal = UnreliableEventSignals[eventName]
	if not EventSignal then
		return
	end

	EventSignal:Fire(...)
end)









-- Autocomplete will display all entries for OnClientEvent, all of them can be used as well.
-- OnClientEvent only exists to ease the replacement of Legacy Roblox Remotes;
-- OnClientEvent shouldn't be used when writing newer code - or get ready for confusing autocomplete.

export type RemoteEventType = {
	FireServer: (self: RemoteEventType, ...any) -> RemoteEventType,
	Connect: (self: RemoteEventType, callback: (...any) -> ()) -> Signal.Connection,
	Disconnect: (self: RemoteEventType) -> RemoteEventType,
	Destroy: (self: RemoteEventType) -> (),
	OnClientEvent: RemoteEventType, --{__index: RemoteEventType},
	--_EventName: string
}

export type RemoteFunctionType = {
	InvokeServer: (self: RemoteFunctionType, ...any) -> (boolean, {}),
	Destroy: (self: RemoteFunctionType) -> (),
	-- For faster typing.
	OnInvoke: ((...any) -> (boolean, {}))?, -- read&write only; Shouldn't be called
	-- Exists to ease the replacement of legacy Remote Functions.
	OnClientInvoke: ((...any) -> (boolean, {}))?, -- read&write only; Shouldn't be called
	--_EventName: string
}

export type UnreliableRemoteEventType = {
	FireServer: (self: UnreliableRemoteEventType, ...any) -> UnreliableRemoteEventType,
	Connect: (self: UnreliableRemoteEventType, callback: (...any) -> ()) -> Signal.Connection,
	Disconnect: (self: UnreliableRemoteEventType) -> UnreliableRemoteEventType,
	Destroy: (self: UnreliableRemoteEventType) -> (),
	OnClientEvent: UnreliableRemoteEventType, --{__index: UnreliableRemoteEventType},
	--_EventName: string
}

local DestroyedMetatable = {
	__index = function(_, key)
		error(`Attempt to use destroyed CoffeeRemoteObject (method "{key}")`, 2)
	end,
	__newindex = function()
		error("Attempt to modify destroyed CoffeeRemoteObject", 2)
	end,
}



module.RemoteEvent = {
	instances = {},
}
local RemoteEventClass = {}
RemoteEventClass.__index = RemoteEventClass

function RemoteEventClass:FireServer(...)
	module:FireServer(self._EventName, ...) --RemoteEvent:FireServer(self._EventName, ...)
	return self
end
function RemoteEventClass:Connect(callback : ((any)) -> ())
	return module:ConnectEvent(self._EventName, callback)
end
function RemoteEventClass:Disconnect()
	module:DisconnectEvent(self._EventName)
	return self
end
function RemoteEventClass:Destroy()
	module:DestroyEvent(self._EventName)
	module.RemoteEvent.instances[self._EventName] = nil
	
	setmetatable(self, DestroyedMetatable)
	rawset(self, "_EventName", nil)
end
-- Exists to ease the replacement of legacy Remote Events.
RemoteEventClass.OnClientEvent = {__index = RemoteEventClass}

function module.RemoteEvent.new(eventName : string) : RemoteEventType
	if not eventName or type(eventName) ~= "string" then
		warn(`Can't create an unnamed RemoteEvent! Given eventName: {eventName}`)
		return
	end
	
	local self = module.RemoteEvent.instances[eventName]
	if self then
		warn(`RemoteEvent with the name "{eventName}" already exists! Return the existing object.`)
		return self
	end
	
	self = setmetatable({
		_EventName = eventName,	
	}, RemoteEventClass)
	
	module.RemoteEvent.instances[eventName] = self
	return self
end



module.RemoteFunction = {
	instances = {},
}
local RemoteFunctionClass = {}
function RemoteFunctionClass:__newindex(key, value)
	if key == "OnClientInvoke" or key == "OnInvoke" then
		if type(value) ~= "function" then
			warn(`OnClientInvoke must be a function (callback)`)
			return
		end
		
		module.DiscardOnInvoke(self._EventName)
		if value == nil then
			return
		end
		
		module.OnInvoke(self._EventName, value)
		return
	end
	warn("Nothing should be stored inside a RemoteFunction object.")
	return
end
function RemoteFunctionClass:__index(key)
	if key == "OnClientInvoke" or key == "OnInvoke" then
		return OnInvokeCallbacks[self._EventName]
	end
	return
end
function InvokeServerMethod(self : RemoteFunctionType, ...)
	return module:InvokeServer(self._EventName, ...)
end
function DestroyFunctionMethod(self : RemoteFunctionType)
	module:DestroyFunction(self._EventName)
	module.RemoteFunction.instances[self._EventName] = nil
	
	setmetatable(self, DestroyedMetatable)
	for k, v in pairs(self) do
		if type(v) == "function" then
			rawset(self, k, nil)
		end
	end
	rawset(self, "_EventName", nil)
end

function module.RemoteFunction.new(eventName : string) : RemoteFunctionType
	if not eventName or type(eventName) ~= "string" then
		warn(`Can't create an unnamed RemoteFunction! Given eventName: {eventName}`)
		return
	end

	local self = module.RemoteFunction.instances[eventName]
	if self then
		warn(`RemoteFunction with the name "{eventName}" already exists! Return the existing object.`)
		return self
	end

	self = setmetatable({
		_EventName = eventName,	
		InvokeServer = InvokeServerMethod,
		Destroy = DestroyFunctionMethod,
	}, RemoteFunctionClass)

	module.RemoteFunction.instances[eventName] = self
	return self
end



module.UnreliableRemoteEvent = {
	instances = {},
}
local UnreliableRemoteEventClass = {}
UnreliableRemoteEventClass.__index = UnreliableRemoteEventClass

function UnreliableRemoteEventClass:FireServer(...)
	module:FireUnreliableServer(self._EventName, ...) --UnreliableRemoteEvent:FireServer(self._EventName, ...)
	return self
end
function UnreliableRemoteEventClass:Connect(callback : ((any)) -> ())
	return module:ConnectUnreliableEvent(self._EventName, callback)
end
function UnreliableRemoteEventClass:Disconnect()
	module:DisconnectUnreliableEvent(self._EventName)
	return self
end
function UnreliableRemoteEventClass:Destroy()
	module:DestroyUnreliableEvent(self._EventName)
	module.UnreliableRemoteEvent.instances[self._EventName] = nil
	
	setmetatable(self, DestroyedMetatable)
	rawset(self, "_EventName", nil)
end
-- Exists to ease the replacement of legacy Unreliable Remote Events.
UnreliableRemoteEventClass.OnClientEvent = {__index = UnreliableRemoteEventClass}

function module.UnreliableRemoteEvent.new(eventName : string) : UnreliableRemoteEventType
	if not eventName or type(eventName) ~= "string" then
		warn(`Can't create an unnamed UnreliableRemoteEvent! Given eventName: {eventName}`)
		return
	end

	local self = module.UnreliableRemoteEvent.instances[eventName]
	if self then
		warn(`UnreliableRemoteEvent with the name "{eventName}" already exists! Return the existing object.`)
		return self
	end

	self = setmetatable({
		_EventName = eventName,	
	}, UnreliableRemoteEventClass)

	module.UnreliableRemoteEvent.instances[eventName] = self
	return self
end

return module