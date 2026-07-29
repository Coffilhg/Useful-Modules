--[[--
    CoffeeRemotesRefined (Server-Side) V1.0.0
    Copyright © 2026 Coffilhg (Roblox UserId 517222346)

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/.

    GitHub Repository/Branch with latest version, documentation, etc:
    https://github.com/Coffilhg/Useful-Modules/tree/CoffeeRemotesRefined
    Stars are appreciated!
    
    Please make sure you're also using the Client-Side part of CoffeeRemotes (Refined)!
    List this as part of your wally [dependencies] (and make sure their versions match):
    CoffeeRemotesClient = "coffilhg/coffeeremotes-client@1.0.0"
--]]--
--!strict
--!optimize 2
--!native

local Players = game:GetService(`Players`)
local RunS = game:GetService(`RunService`)
local RS = game:GetService(`ReplicatedStorage`)

local IsStudio: boolean = RunS:IsStudio()
local Prefix: string = `[CoffeeRemotes-Server V1.0.0] `
local MainFolderName: string = `{Prefix}RemotesFolder`

-- Optimize the VM
local OSClock = os.clock
local type = type
local typeof = typeof
local rawget = rawget
local rawset = rawset
local setmetatable = setmetatable
local error = error
local warn = warn

-- Remote Function Exit Reasons (RFER)
-- Be an oracle only if IsStudio testing, not in-game!
-- Although only existing RemoteFunctions are there,
-- it isn't a black box like in Legacy CoffeeRemotes.
-- But you could add some honeypots!
local RFER_TooQuick = {`Sending Requests Too Quickly!`}
local RFER_NotFound = IsStudio and
	function(name: string, object: RemoteFunctionType)
		return {`OnServerInvoke/OnInvoke Callback for name="{name}" doesn't exist; Object and it's RemoteFunction Instance:`, object, rawget(object :: any, `_RI`)}
	end 
	or
	function()
		return RFER_TooQuick
	end
local RFER_PlayerLeft = IsStudio and {`Player Has Left`} or RFER_TooQuick

--- Default Cooldown (in seconds) between calls per EventName ---
local RemoteEventCooldown: number = 0.03
local RemoteFunctionCooldown: number = 0.03
local UnreliableRemoteEventCooldown: number = 0.01

if not RunS:IsServer() then
	error(`{Prefix} can only be required by Server-Side scripts!`)
end



--- Dependencies ---

-- Signal's Source Repository: https://github.com/Data-Oriented-House/LemonSignal --
local LemonSignal = require(RS.Packages.LemonSignal) -- or wherever it's located and whatever it's named

--- /E Dependencies ---



export type RemoteInstance = RemoteEvent | RemoteFunction | UnreliableRemoteEvent
export type CoffeeRemotesObject = RemoteEventType | RemoteFunctionType | UnreliableRemoteEventType
type KindOf = "RemoteEvent" | "RemoteFunction" | "UnreliableRemoteEvent"
type KindOfs = "RemoteEvents" | "RemoteFunctions" | "UnreliableRemoteEvents"
type OnInvokeCallback = (player: Player, ...any) -> (boolean, {})

type UserId = number
type RemoteInstanceName = string
type CooldownRoot = {
	[UserId]: {
		[RemoteInstanceName]: number?,
	},
}
export type PlayerCooldowns = {
	[KindOfs]: CooldownRoot,
}

type ClassInstancesTable<T = RemoteInstance, U = CoffeeRemotesObject> = {
	[T]: U
}
type RemoteEventClassInstancesTable = ClassInstancesTable<RemoteEvent, RemoteEventType>
type RemoteFunctionClassInstancesTable = ClassInstancesTable<RemoteFunction, RemoteFunctionType>
type UnreliableRemoteEventClassInstancesTable = ClassInstancesTable<UnreliableRemoteEvent, UnreliableRemoteEventType>



local PlayerCooldowns: PlayerCooldowns = {
	RemoteEvents = {},
	RemoteFunctions = {},
	UnreliableRemoteEvents = {},
}

local function mkdir(name: string, where: Instance?): Folder
	if typeof(where) ~= `Instance` then
		where = RS
	end
	
	local existing = (where :: Instance):FindFirstChild(name) :: Folder
	if not (existing and existing:IsA(`Folder`)) then
		existing = Instance.new(`Folder`)
		existing.Name = name
		existing.Parent = where -- Parent after naming for compliance with Client's WaitForChild
	end
	
	return existing
end

local MainFolder = mkdir(MainFolderName)
local RemoteEventsFolder = mkdir(`Events`, MainFolder)
local RemoteFunctionsFolder = mkdir(`Functions`, MainFolder)
local UnreliableRemoteEventsFolder = mkdir(`UnreliableEvents`, MainFolder)

local module = {}

local RemoteEventClassInstances: RemoteEventClassInstancesTable = {}
module.RemoteEvent = {
	instances = RemoteEventClassInstances,
}

local RemoteFunctionClassInstances: RemoteFunctionClassInstancesTable = {}
module.RemoteFunction = {
	instances = RemoteFunctionClassInstances
}

local UnreliableRemoteEventClassInstances: UnreliableRemoteEventClassInstancesTable = {}
module.UnreliableRemoteEvent = {
	instances = UnreliableRemoteEventClassInstances
}

local function mkremote(name: string, where: Folder): (RemoteInstance | CoffeeRemotesObject, boolean)
	local existing = where:FindFirstChild(name)
	local kindOf: KindOf = where == RemoteEventsFolder and `RemoteEvent`
		or where == RemoteFunctionsFolder and `RemoteFunction`
		or `UnreliableRemoteEvent`
	
	if existing then
		if not existing:IsA(kindOf) then
			error(`{Prefix}Found a non-{kindOf} Instance ("{existing.ClassName}") already occupying the name "{name}" in {where:GetFullName()}; This will lead to challenges on the client-side!`)
		end
		
		local object = module[kindOf][`instances`][existing] :: CoffeeRemotesObject?
		if object then
			warn(`{Prefix}{kindOf}Object with the name "{name}" already exists! Return the existing object.`)
			return object, true
		end
		warn(`{Prefix}{kindOf} with the name "{name}" already exists! Return the existing Instance.`)
		return existing :: RemoteInstance | any, false
	end
	
	existing = Instance.new(kindOf) :: RemoteInstance
	existing.Name = name
	existing.Parent = where -- Parent after naming for compliance with Client's WaitForChild
	
	return existing, false
end









-- Autocomplete will display all entries for OnServerEvent, all of them can be used as well.
-- OnServerEvent only exists to ease the replacement of Legacy Roblox Remotes;
-- OnServerEvent shouldn't be used when writing newer code - or get ready for confusing autocomplete.

export type RemoteEventBase = RemoteEvent | UnreliableRemoteEvent

type RemoteEventBaseClassInstancesTable = RemoteEventClassInstancesTable | UnreliableRemoteEventClassInstancesTable

export type RemoteEventBaseType<T=RemoteEventBase> = {
	FireClient: (self: RemoteEventBaseType<T>, Player, ...any) -> RemoteEventBaseType<T>,
	FireAllClients: (self: RemoteEventBaseType<T>, ...any) -> RemoteEventBaseType<T>,
	Connect: (self: RemoteEventBaseType<T>, callback: (Player, ...any) -> ()) -> LemonSignal.Connection,
	Wait: (self: RemoteEventBaseType<T>) -> (Player, ...any),
	Once: (self: RemoteEventBaseType<T>, callback: (Player, ...any) -> ()) -> LemonSignal.Connection,
	Disconnect: (self: RemoteEventBaseType<T>) -> RemoteEventBaseType<T>,
	SetCooldown: (self: RemoteEventBaseType<T>, newCooldownTime: number?) -> RemoteEventBaseType<T>,
	Destroy: (self: RemoteEventBaseType<T>) -> (),
	OnServerEvent: RemoteEventBaseType<T>,
	Remote: T, -- Expose a read-only Remote field
	Destroying: LemonSignal.Signal<>, -- When the :Destroy of the wrapper happens
}

export type RemoteEventBaseTypeWInternals<T=RemoteEventBase> = {
	_Name: string,
	_RI: T, -- RI = Remote Instance
	_Cooldown: number?,
	_Signal: (LemonSignal.Signal<any>)?,
	_IT: RemoteEventBaseClassInstancesTable,
	_CR: CooldownRoot,
} & RemoteEventBaseType<T>

export type RemoteEventBaseDescriptor = {
	Folder: Folder,
	DefaultCooldown: number,
	CooldownsRoot: CooldownRoot,
	InstancesTable: RemoteEventBaseClassInstancesTable,
}

export type RemoteEventType = RemoteEventBaseType<RemoteEvent>
export type UnreliableRemoteEventType = RemoteEventBaseType<UnreliableRemoteEvent>

export type RemoteFunctionType = {
	InvokeClient: (self: RemoteFunctionType, Player, ...any) -> (boolean, {}),
	SetCooldown: (self: RemoteFunctionType, newCooldownTime: number?) -> RemoteFunctionType,
	Destroy: (self: RemoteFunctionType) -> (),
	-- For faster typing.
	OnInvoke: OnInvokeCallback?, -- read&write only; Shouldn't be called
	-- Exists to ease the replacement of legacy Remote Functions.
	OnServerInvoke: OnInvokeCallback?, -- read&write only; Shouldn't be called
	Remote: RemoteFunction, -- Expose a read-only Remote field
	Destroying: LemonSignal.Signal<>, -- When the :Destroy of the wrapper happens
}

export type RemoteFunctionTypeWInternals = {
	_Name: string,
	_RI: RemoteFunction, -- RI = Remote Instance
	_Cooldown: number?,
	_OnInvoke: OnInvokeCallback?,
} & RemoteFunctionType

local function DestroyedMTIndex()
	error(`Attempt to use destroyed CoffeeRemotesObject`)
end
local function DestroyedMTNewIndex()
	error(`Attempt to modify destroyed CoffeeRemotesObject`)
end
local DestroyedMetatable = {
	__index = DestroyedMTIndex,
	__newindex = DestroyedMTNewIndex,
}

-- Unified for RemoteEvent/UnreliableRemoteEvent Instances
local RemoteEventBaseClass = {}

function RemoteEventBaseClass.__index(
	self: RemoteEventBaseTypeWInternals,
	k: any
)
	if k == `Remote` then
		return rawget(self :: any, `_RI`)
	end
	if k == `Destroying` then
		return rawget(self :: any, `_Destroying`)
	end
	
	return rawget(RemoteEventBaseClass, k)
end

function RemoteEventBaseClass.__newindex(
	self: RemoteEventBaseTypeWInternals,
	k: any,
	v: any
)
	warn(`Nothing should be stored inside a RemoteEventBase (RemoteEvent | UnreliableRemoteEvent) object. The ["Remote" | "Destroying"] fields shall not be overwritten. Attempted writing [{k}] = {v}`)
	return
end

function RemoteEventBaseClass.FireClient(
	self: RemoteEventBaseTypeWInternals,
	player : Player,
	...
): RemoteEventBaseTypeWInternals
	-- any is here to quiet down the linter, the type is by definition and must remain RemoteEventBase
	(self._RI :: RemoteEventBase | any):FireClient(player, ...)

	return self
end

function RemoteEventBaseClass.FireAllClients(self: RemoteEventBaseTypeWInternals, ...)
	-- any is here to quiet down the linter, the type is by definition and must remain RemoteEventBase
	(self._RI :: RemoteEventBase | any):FireAllClients(...)

	return self
end

function RemoteEventBaseClass.Connect(self: RemoteEventBaseTypeWInternals, callback : (any) -> ())
	local signal = self._Signal :: LemonSignal.Signal<any>

	if not signal then
		signal = LemonSignal.new()
		rawset(self :: any, `_Signal`, signal)
	end

	return signal:Connect(callback)
end

function RemoteEventBaseClass.Wait(self: RemoteEventBaseTypeWInternals)
	local signal = self._Signal :: LemonSignal.Signal<any>

	if not signal then
		signal = LemonSignal.new()
		rawset(self :: any, `_Signal`, signal)
	end

	return signal:Wait()
end

function RemoteEventBaseClass.Once(self: RemoteEventBaseTypeWInternals, callback : (any) -> ())
	local signal = self._Signal :: LemonSignal.Signal<any>

	if not signal then
		signal = LemonSignal.new()
		rawset(self :: any, `_Signal`, signal)
	end

	return signal:Once(callback)
end

function RemoteEventBaseClass.Disconnect(self: RemoteEventBaseTypeWInternals)
	local signal = self._Signal :: LemonSignal.Signal<any>

	if signal then
		signal:DisconnectAll()
		rawset(self :: any, `_Signal`, nil)
	end
	return self
end

function RemoteEventBaseClass.SetCooldown(self: RemoteEventBaseTypeWInternals, newCooldownTime : number?)
	rawset(self :: any, `_Cooldown`, newCooldownTime)

	return self
end

function RemoteEventBaseClass.Destroy(self: RemoteEventBaseTypeWInternals): ()
	self:Disconnect()
	
	local destroying = rawget(self :: any, `_Destroying`) :: LemonSignal.Signal<>
	local remote = rawget(self :: any, `_RI`) :: RemoteEvent | UnreliableRemoteEvent
	local name = rawget(self :: any, `_Name`) :: string
	local instancesTable = rawget(self :: any, `_IT`) :: {[RemoteEvent | UnreliableRemoteEvent]: RemoteEventBaseType<RemoteEvent | UnreliableRemoteEvent>}
	local cooldownRoot = rawget(self :: any, `_CR`) :: CooldownRoot
	
	if destroying then
		destroying:Fire()
		destroying:DisconnectAll()
	end
	
	instancesTable[remote] = nil
	for UID, cooldownsPerNameTable in cooldownRoot do
		cooldownsPerNameTable[name] = nil
	end
	
	if remote then
		remote:Destroy()
	end

	setmetatable(self, DestroyedMetatable)
	rawset(self :: any, `_Name`, nil)
	rawset(self :: any, `_RI`, nil)
	rawset(self :: any, `_Cooldown`, nil)
	
	rawset(self :: any, `_IT`, nil) -- Instances Table
	-- RemoteEventClassInstances / UnreliableRemoteEventClassInstances
	
	rawset(self :: any, `_CR`, nil) -- Cooldowns Root
	-- PlayerCooldowns.RemoteEvents / PlayerCooldowns.UnreliableRemoteEvents
	
	rawset(self :: any, `_Destroying`, nil)
	rawset(self :: any, `OnServerEvent`, nil)
end

-- T must be RemoteEventBase
function RemoteEventBaseClass.new<T>(
	name: string,
	descriptor: RemoteEventBaseDescriptor
): RemoteEventBaseType<T>
	if type(name) ~= `string` then
		error(`{Prefix}Can't create an unnamed RemoteEvent! Given name: {name}`)
	end

	local remoteOrObject, isUsedByObject = mkremote(name, descriptor.Folder)
	if isUsedByObject then
		return remoteOrObject :: RemoteEventBaseType<T>
	end
	
	local defaultCooldown = descriptor.DefaultCooldown
	local root = descriptor.CooldownsRoot
	local instancesTable = descriptor.InstancesTable
	


	local self = setmetatable({}, RemoteEventBaseClass)
	rawset(self :: any, `_Name`, name :: string)
	rawset(self :: any, `_RI`, remoteOrObject :: T)
	rawset(self :: any, `_Cooldown`, defaultCooldown :: number)
	rawset(self :: any, `_CR`, root)
	rawset(self :: any, `_IT`, instancesTable)
	rawset(self :: any, `_Destroying`, LemonSignal.new())
	-- Exists to ease the replacement of legacy Remote Events and Unreliable Remote Events.
	rawset(self :: any, `OnServerEvent`, self :: RemoteEventBaseType<T>)

	
	
	local function OnEvent(player : Player, ...)
		local signal = (self :: any)[`_Signal`] :: LemonSignal.Signal<any>
		if not signal then
			return
		end

		local cooldownTime = (self :: any)[`_Cooldown`]
		local cooldownTimeType = type(cooldownTime)
		if cooldownTimeType ~= `number` then
			if cooldownTimeType == `nil` then -- 0 seconds cooldown
				signal:Fire(player, ...)
				return
			end

			cooldownTime = defaultCooldown or 0.03
		end

		if cooldownTime <= 0 then
			signal:Fire(player, ...)
			return
		end



		local UID = player.UserId
		local playerEntry = root[UID]
		if not playerEntry then
			-- player left
			return
		end



		local lastCallTime = playerEntry[name] or 0
		local now = OSClock()
		if now - lastCallTime < cooldownTime then
			return
		end



		playerEntry[name] = now

		signal:Fire(player, ...)
	end
	
	-- any is here to quiet down the linter, the type must be T
	(remoteOrObject :: T | any).OnServerEvent:Connect(OnEvent)
	
	instancesTable[remoteOrObject :: T] = self :: RemoteEventBaseType<T>
	return self :: RemoteEventBaseType<T>
end






local RemoteEventDescriptor: RemoteEventBaseDescriptor = {
	Folder = RemoteEventsFolder,
	DefaultCooldown = RemoteEventCooldown,
	CooldownsRoot = PlayerCooldowns.RemoteEvents,
	InstancesTable = RemoteEventClassInstances,
}

function module.RemoteEvent.new(name: string): RemoteEventType
	-- any is here to mute type linter; Otherwise we'd have to create an Instance just to mock the type!
	return (RemoteEventBaseClass :: any).new(name, RemoteEventDescriptor) -- :: RemoteEventType
end






local UnreliableRemoteEventDescriptor: RemoteEventBaseDescriptor = {
	Folder = UnreliableRemoteEventsFolder,
	DefaultCooldown = UnreliableRemoteEventCooldown,
	CooldownsRoot = PlayerCooldowns.UnreliableRemoteEvents,
	InstancesTable = UnreliableRemoteEventClassInstances,
}

function module.UnreliableRemoteEvent.new(name: string): UnreliableRemoteEventType
	-- any is here to mute type linter; Otherwise we'd have to create an Instance just to mock the type!
	return (RemoteEventBaseClass :: any).new(name, UnreliableRemoteEventDescriptor) -- :: UnreliableRemoteEventType
end






local RemoteFunctionClass = {}

function RemoteFunctionClass.InvokeClient(self: RemoteFunctionTypeWInternals, player: Player, ...)
	return self._RI:InvokeClient(player, ...)
end

function RemoteFunctionClass.SetCooldown(self: RemoteFunctionTypeWInternals, newCooldownTime: number?)
	rawset(self :: any, `_Cooldown`, newCooldownTime)

	return self
end

function RemoteFunctionClass.Destroy(self: RemoteFunctionTypeWInternals)
	local destroying = rawget(self :: any, `_Destroying`) :: LemonSignal.Signal<>
	local name = rawget(self :: any, `_Name`)
	local remote = self._RI
	
	if destroying then
		destroying:Fire()
		destroying:DisconnectAll()
	end
	
	RemoteFunctionClassInstances[remote] = nil
	if remote then
		remote:Destroy()
	end
	
	for UID, cooldownsPerNameTable in PlayerCooldowns.RemoteFunctions do
		cooldownsPerNameTable[name] = nil
	end

	setmetatable(self, DestroyedMetatable)
	rawset(self :: any, `_Name`, nil)
	rawset(self :: any, `_RI`, nil)
	rawset(self :: any, `_Cooldown`, nil)
	rawset(self :: any, `_OnInvoke`, nil)
	rawset(self :: any, `_Destroying`, nil)
end

function RemoteFunctionClass.__newindex(self: RemoteFunctionTypeWInternals, key, value)
	if key == `OnServerInvoke` or key == `OnInvoke` then
		local valueType = type(value)
		
		if valueType == `function` or valueType == `nil` then
			rawset(self :: any, `_OnInvoke`, value)
			return
		end
		
		warn(`{key} must be a function (callback) or nil (to "disconnect"), got {valueType}:`, value)
		return
	end
	
	warn(`Nothing should be stored inside a RemoteFunction object. The ["Remote" | "Destroying"] fields shall not be overwritten. Attempted writing [{key}] = {value}`)
	return
end

function RemoteFunctionClass.__index(self: RemoteFunctionTypeWInternals, key)
	if key == `OnServerInvoke` or key == `OnInvoke` then
		return rawget(self :: any, `_OnInvoke`)
	end
	if key == `Remote` then
		return rawget(self :: any, `_RI`)
	end
	if key == `Destroying` then
		return rawget(self :: any, `_Destroying`)
	end
	return rawget(RemoteFunctionClass, key)
end

function module.RemoteFunction.new(name: string): RemoteFunctionType
	if type(name) ~= `string` then
		error(`{Prefix}Can't create an unnamed RemoteFunction! Given name: {name}`)
	end
	
	local remoteOrObject, isUsedByObject = mkremote(name, RemoteFunctionsFolder)
	if isUsedByObject then
		return remoteOrObject :: RemoteFunctionType
	end

	local self = setmetatable({}, RemoteFunctionClass)
	rawset(self :: any, `_Name`, name :: string)
	rawset(self :: any, `_RI`, remoteOrObject :: RemoteFunction)
	rawset(self :: any, `_Cooldown`, RemoteFunctionCooldown :: number)
	rawset(self :: any, `_Destroying`, LemonSignal.new())
	
	local root = PlayerCooldowns.RemoteFunctions;
	
	local function OnInvoke(player: Player, ...): (boolean, {})
		local callback = (self :: any)._OnInvoke :: OnInvokeCallback
		if typeof(callback) ~= `function` then
			return false, (RFER_NotFound :: any)(name, self)
		end

		local cooldownTime = self._Cooldown :: number
		local cooldownTimeType = type(cooldownTime)
		if cooldownTimeType ~= `number` then
			if cooldownTimeType == `nil` then -- 0 seconds cooldown
				return callback(player, ...)
			end

			cooldownTime = RemoteFunctionCooldown or 0.03
		end

		if cooldownTime <= 0 then
			return callback(player, ...)
		end



		local UID = player.UserId
		local playerEntry = root[UID]
		if not playerEntry then
			-- player left
			return false, RFER_PlayerLeft
			-- free oracle removed once again 
		end



		local lastCallTime = playerEntry[name] or 0
		local now = OSClock()
		if now - lastCallTime < cooldownTime then
			return false, RFER_TooQuick
		end



		playerEntry[name] = now
		
		return callback(player, ...)
	end
	
	(remoteOrObject :: RemoteFunction).OnServerInvoke = OnInvoke
	
	RemoteFunctionClassInstances[remoteOrObject :: RemoteFunction] = self :: RemoteFunctionType
	return self :: RemoteFunctionType
end






local function OnPlayerAdded(player: Player)
	local UID = player.UserId
	
	--PlayerCooldowns.RemoteEvents[UID] = {}
	--PlayerCooldowns.RemoteFunctions[UID] = {}
	--PlayerCooldowns.UnreliableRemoteEvents[UID] = {}
	
	for kindOf, v in PlayerCooldowns do
		if v[UID] then
			continue
		end
		
		v[UID] = {}
	end
end
Players.PlayerAdded:Connect(OnPlayerAdded)
for _, player in Players:GetPlayers() do
	OnPlayerAdded(player)
end

local function OnPlayerRemoving(player: Player)
	local UID = player.UserId
	for kindOf, v in PlayerCooldowns do
		v[UID] = nil
	end
end

Players.PlayerRemoving:Connect(OnPlayerRemoving)

module._PlayerCooldowns = PlayerCooldowns

return module