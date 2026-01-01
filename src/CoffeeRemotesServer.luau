--[[--
    Quick Start and API can be found at
    https://github.com/Coffilhg/Useful-Modules/tree/CoffeeRemotes

    CoffeeRemotes (CoffeeRemotesServer)
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

local Players = game:GetService("Players")
local RunS = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

local DoWarningForSettingCooldownToNonexistentEvent = RunS:IsStudio()

--- Default Cooldown (in seconds) between calls per EventName ---
local RemoteEventCooldown = 0.03
local RemoteFunctionCooldown = 0.03
local UnreliableRemoteEventCooldown = 0.01

local RemoteEvent = RS:FindFirstChild("CoffeeRemotes_Event") :: RemoteEvent
if not RemoteEvent then
	RemoteEvent = Instance.new("RemoteEvent", RS)
	RemoteEvent.Name = "CoffeeRemotes_Event"
end
local RemoteFunction = RS:FindFirstChild("CoffeeRemotes_Function") :: RemoteFunction
if not RemoteFunction then
	RemoteFunction = Instance.new("RemoteFunction", RS)
	RemoteFunction.Name = "CoffeeRemotes_Function"
end
local UnreliableRemoteEvent = RS:FindFirstChild("CoffeeRemotes_Unreliable") :: UnreliableRemoteEvent
if not UnreliableRemoteEvent then
	UnreliableRemoteEvent = Instance.new("UnreliableRemoteEvent", RS)
	UnreliableRemoteEvent.Name = "CoffeeRemotes_Unreliable"
end

--- Dependencies (Not By @Coffilhg) ---

-- Signal's Source Repository: https://github.com/stravant/goodsignal/blob/master/README.md --
local Signal = require(script.GoodSignal_By_Stravant) -- or wherever it's located and whatever it's named

--- /E Dependencies (Not By @Coffilhg) ---



local module = {}

function module:FireClient(eventName : string, player : Player, ...)
	RemoteEvent:FireClient(player, eventName, ...)
end
function module:FireAllClients(eventName : string, ...)
	RemoteEvent:FireAllClients(eventName, ...)
end
local EventSignals = {} :: {[string]: Signal.Signal}
local EventCooldowns = {} :: {[string]: number}
local PlayerEventCooldowns = {}
function module:ConnectEvent(eventName : string, callback : (Player, ...any) -> ()) : Signal.Connection
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
function module:SetEventCooldown(eventName : string, newCooldownTime : number?, ignoreWarn : boolean?)
	if not ignoreWarn and not EventSignals[eventName] and DoWarningForSettingCooldownToNonexistentEvent then
		warn(`EventName "{eventName}" has no connected signals; It might be that it was never created either.`)
	end
	
	if type(newCooldownTime) == "number" then
		EventCooldowns[eventName] = newCooldownTime
	else
		EventCooldowns[eventName] = nil
	end
end
function module:DestroyEvent(eventName : string)
	module:DisconnectEvent(eventName)
	EventSignals[eventName] = nil

	module:SetEventCooldown(eventName, nil, true)
	PlayerEventCooldowns[eventName] = nil
end
RemoteEvent.OnServerEvent:Connect(function(player : Player, eventName : string, ...)
	local EventSignal = EventSignals[eventName]
	if not EventSignal then
		return
	end
	
	
	
	local cooldownTime = EventCooldowns[eventName]
	if not (cooldownTime and type(cooldownTime) == "number") then
		cooldownTime = RemoteEventCooldown or 0.03
	end
	
	if cooldownTime <= 0 then
		EventSignal:Fire(player, ...)
		return
	end



	if not PlayerEventCooldowns[eventName] then
		PlayerEventCooldowns[eventName] = {}
	end
	
	local UID = player.UserId

	local lastCallTime = PlayerEventCooldowns[eventName][UID] or 0
	if os.clock() - lastCallTime < cooldownTime then
		return
	end


	
	PlayerEventCooldowns[eventName][UID] = os.clock()
	
	EventSignal:Fire(player, ...)
end)









function module:InvokeClient(eventName : string, player : Player, ...)
	return RemoteFunction:InvokeClient(player, eventName, ...)
end
local OnInvokeCallbacks = {} :: {[string]: (Player, ...any) -> (boolean, {})}
local OnInvokeCooldowns = {} :: {[string]: number}
local PlayerInvokeCooldowns = {}
-- callback shall return a (success, result); Where success is a boolean (true / false) and result is a dictionary, array or a single value. Retuning a tuple result is NOT recommended: only the first value of the tuple will be returned. (Tuples are prohibited for security reasons)
function module.OnInvoke(eventName : string, callback : (Player, ...any) -> (boolean, {}))
	if OnInvokeCallbacks[eventName] then
		warn(`OnEvent Callback for eventName="{eventName}" already exists; Overwriting.`)
	end
	OnInvokeCallbacks[eventName] = callback
end
-- Sets the callback for the given eventName; If a callback was given before, it basically gets discarded.
function module.DiscardOnInvoke(eventName : string)
	OnInvokeCallbacks[eventName] = nil
end
function module:SetOnInvokeCooldown(eventName : string, newCooldownTime : number?, ignoreWarn : boolean?)
	if not ignoreWarn and not OnInvokeCallbacks[eventName] and DoWarningForSettingCooldownToNonexistentEvent then
		warn(`EventName "{eventName}" has no connected callback; It might be that it was never created either.`)
	end

	if type(newCooldownTime) == "number" then
		OnInvokeCooldowns[eventName] = newCooldownTime
	else
		OnInvokeCooldowns[eventName] = nil
	end
end
function module:DestroyFunction(eventName : string)
	module.DiscardOnInvoke(eventName)

	module:SetOnInvokeCooldown(eventName, nil, true)
	PlayerInvokeCooldowns[eventName] = nil
end
RemoteFunction.OnServerInvoke = function(player : Player, eventName : string, ...)
	local OnInvokeCallback = OnInvokeCallbacks[eventName]
	if not OnInvokeCallback then
		return false, {`Sending Requests Too Quickly!`}
		--instead of the free oracle {`OnServerInvoke Callback for eventName="{eventName}" doesn't exist`}
	end
	
	
	
	local cooldownTime = OnInvokeCooldowns[eventName]
	if not (cooldownTime and type(cooldownTime) == "number") then
		cooldownTime = RemoteFunctionCooldown or 0.03
	end

	if cooldownTime <= 0 then
		return OnInvokeCallback(player, ...)
	end



	if not PlayerInvokeCooldowns[eventName] then
		PlayerInvokeCooldowns[eventName] = {}
	end
	
	local UID = player.UserId

	local lastCallTime = PlayerInvokeCooldowns[eventName][UID] or 0
	if os.clock() - lastCallTime < cooldownTime then
		return false, {`Sending Requests Too Quickly!`}
	end



	PlayerInvokeCooldowns[eventName][UID] = os.clock()

	return OnInvokeCallback(player, ...)
end









function module:FireUnreliableClient(eventName : string, player : Player, ...)
	UnreliableRemoteEvent:FireClient(player, eventName, ...)
end
function module:FireAllUnreliableClients(eventName : string, ...)
	UnreliableRemoteEvent:FireAllClients(eventName, ...)
end
local UnreliableEventSignals = {} :: {[string]: Signal.Signal}
local UnreliableEventCooldowns = {} :: {[string]: number}
local PlayerUnreliableCooldowns = {}
function module:ConnectUnreliableEvent(eventName : string, callback : (Player, ...any) -> ()) : Signal.Connection
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
function module:SetUnreliableEventCooldown(eventName : string, newCooldownTime : number?, ignoreWarn : boolean?)
	if not ignoreWarn and not UnreliableEventSignals[eventName] and DoWarningForSettingCooldownToNonexistentEvent then
		warn(`EventName "{eventName}" has no connected signals; It might be that it was never created either.`)
	end

	if type(newCooldownTime) == "number" then
		UnreliableEventCooldowns[eventName] = newCooldownTime
	else
		UnreliableEventCooldowns[eventName] = nil
	end
end
function module:DestroyUnreliableEvent(eventName : string)
	module:DisconnectUnreliableEvent(eventName)
	UnreliableEventSignals[eventName] = nil

	module:SetUnreliableEventCooldown(eventName, nil, true)
	PlayerUnreliableCooldowns[eventName] = nil
end
UnreliableRemoteEvent.OnServerEvent:Connect(function(player : Player, eventName : string, ...)
	local EventSignal = UnreliableEventSignals[eventName]
	if not EventSignal then
		return
	end
	
	
	
	local cooldownTime = UnreliableEventCooldowns[eventName]
	if not (cooldownTime and type(cooldownTime) == "number") then
		cooldownTime = UnreliableRemoteEventCooldown or 0.01
	end

	if cooldownTime <= 0 then
		EventSignal:Fire(player, ...)
		return
	end
	
	
	
	if not PlayerUnreliableCooldowns[eventName] then
		PlayerUnreliableCooldowns[eventName] = {}
	end
	
	local UID = player.UserId

	local lastCallTime = PlayerUnreliableCooldowns[eventName][UID] or 0
	if os.clock() - lastCallTime < cooldownTime then -- Slightly tighter cooldown for high-freq data
		return
	end



	PlayerUnreliableCooldowns[eventName][UID] = os.clock()
	
	EventSignal:Fire(player, ...)
end)









-- Autocomplete will display all entries for OnServerEvent, all of them can be used as well.
-- OnServerEvent only exists to ease the replacement of Legacy Roblox Remotes;
-- OnServerEvent shouldn't be used when writing newer code - or get ready for confusing autocomplete.

export type RemoteEventType = {
	FireClient: (self: RemoteEventType, Player, ...any) -> RemoteEventType,
	FireAllClients: (self: RemoteEventType, ...any) -> RemoteEventType,
	Connect: (self: RemoteEventType, callback: (Player, ...any) -> ()) -> Signal.Connection,
	Disconnect: (self: RemoteEventType) -> RemoteEventType,
	SetCooldown: (self: RemoteEventType, newCooldownTime: number?) -> RemoteEventType,
	Destroy: (self: RemoteEventType) -> (),
	OnServerEvent: RemoteEventType, --{__index: RemoteEventType},
	--_EventName: string
}

export type RemoteFunctionType = {
	InvokeClient: (self: RemoteFunctionType, Player, ...any) -> (boolean, {}),
	SetCooldown: (self: RemoteFunctionType, newCooldownTime: number?) -> RemoteFunctionType,
	Destroy: (self: RemoteFunctionType) -> (),
	-- For faster typing.
	OnInvoke: ((...any) -> (boolean, {}))?, -- read&write only; Shouldn't be called
	-- Exists to ease the replacement of legacy Remote Functions.
	OnServerInvoke: ((...any) -> (boolean, {}))?, -- read&write only; Shouldn't be called
	--_EventName: string
}

export type UnreliableRemoteEventType = {
	FireClient: (self: UnreliableRemoteEventType, Player, ...any) -> UnreliableRemoteEventType,
	FireAllClients: (self: UnreliableRemoteEventType, ...any) -> UnreliableRemoteEventType,
	Connect: (self: UnreliableRemoteEventType, callback: (Player, ...any) -> ()) -> Signal.Connection,
	Disconnect: (self: UnreliableRemoteEventType) -> UnreliableRemoteEventType,
	SetCooldown: (self: UnreliableRemoteEventType, newCooldownTime: number?) -> UnreliableRemoteEventType,
	Destroy: (self: UnreliableRemoteEventType) -> (),
	OnServerEvent: UnreliableRemoteEventType, --{__index: UnreliableRemoteEventType},
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

function RemoteEventClass:FireClient(player : Player, ...)
	module:FireClient(self._EventName, player, ...) --RemoteEvent:FireClient(self._EventName, player, ...)
	return self
end
function RemoteEventClass:FireAllClients(...)
	module:FireAllClients(self._EventName, ...) --RemoteEvent:FireAllClients(self._EventName, ...)
	return self
end
function RemoteEventClass:Connect(callback : ((any)) -> ())
	return module:ConnectEvent(self._EventName, callback)
end
function RemoteEventClass:Disconnect()
	module:DisconnectEvent(self._EventName)
	return self
end
function RemoteEventClass:SetCooldown(newCooldownTime : number?)
	module:SetEventCooldown(self._EventName, newCooldownTime, true)
	return self
end
function RemoteEventClass:Destroy()
	module:DestroyEvent(self._EventName)
	module.RemoteEvent.instances[self._EventName] = nil
	
	setmetatable(self, DestroyedMetatable)
	rawset(self, "_EventName", nil)
end
-- Exists to ease the replacement of legacy Remote Events.
RemoteEventClass.OnServerEvent = {__index = RemoteEventClass}

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
	if key == "OnServerInvoke" or key == "OnInvoke" then
		if type(value) ~= "function" then
			warn(`OnServerInvoke must be a function (callback)`)
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
	if key == "OnServerInvoke" or key == "OnInvoke" then
		return OnInvokeCallbacks[self._EventName]
	end
	return
end
function InvokeClientMethod(self : RemoteFunctionType, player : Player, ...)
	return module:InvokeClient(self._EventName, player, ...)
end
function SetCooldownMethod(self : RemoteFunctionType, newCooldownTime : number?)
	module:SetOnInvokeCooldown(self._EventName, newCooldownTime, true)
	return self
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
		InvokeClient = InvokeClientMethod,
		SetCooldown = SetCooldownMethod,
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

function UnreliableRemoteEventClass:FireClient(player : Player, ...)
	module:FireUnreliableClient(self._EventName, player, ...) --UnreliableRemoteEvent:FireClient(self._EventName, player, ...)
	return self
end
function UnreliableRemoteEventClass:FireAllClients(...)
	module:FireAllUnreliableClients(self._EventName, ...) --UnreliableRemoteEvent:FireAllClients(self._EventName, ...)
	return self
end
function UnreliableRemoteEventClass:Connect(callback : ((any)) -> ())
	return module:ConnectUnreliableEvent(self._EventName, callback)
end
function UnreliableRemoteEventClass:Disconnect()
	module:DisconnectUnreliableEvent(self._EventName)
	return self
end
function UnreliableRemoteEventClass:SetCooldown(newCooldownTime : number?)
	module:SetUnreliableEventCooldown(self._EventName, newCooldownTime, true)
	return self
end
function UnreliableRemoteEventClass:Destroy()
	module:DestroyUnreliableEvent(self._EventName)
	module.UnreliableRemoteEvent.instances[self._EventName] = nil
	
	setmetatable(self, DestroyedMetatable)
	rawset(self, "_EventName", nil)
end
-- Exists to ease the replacement of legacy Unreliable Remote Events.
UnreliableRemoteEventClass.OnServerEvent = {__index = UnreliableRemoteEventClass}

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









Players.PlayerRemoving:Connect(function(player : Player)
	local UID = player.UserId
	for _, event in PlayerEventCooldowns do
		event[UID] = nil
	end
	for _, event in PlayerInvokeCooldowns do
		event[UID] = nil
	end
	for _, event in PlayerUnreliableCooldowns do
		event[UID] = nil
	end
end)

return module