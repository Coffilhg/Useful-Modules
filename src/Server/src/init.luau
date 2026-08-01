--[[--
    CoffeeRemotesRefined (Server-Side) V1.0.1
    Copyright © 2026 Coffilhg (Roblox UserId 517222346)

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/.

    GitHub Repository/Branch with latest version, documentation, etc:
    https://github.com/Coffilhg/Useful-Modules/tree/CoffeeRemotesRefined
    Stars are appreciated!
    
    Please make sure you're also using the Client-Side part of CoffeeRemotes (Refined)!
    List this as part of your wally [dependencies] (and make sure their versions match):
    CoffeeRemotesClient = "coffilhg/coffeeremotes-client@1.0.1"
--]]--
--!strict
--!optimize 2
-- no native here, this script does NO heavy math!

local Players = game:GetService(`Players`)
local RunS = game:GetService(`RunService`)
local RS = game:GetService(`ReplicatedStorage`)
local Debris = game:GetService(`Debris`)

-- The following Three must match on Both Server and Client Side versions of the Module
local ModuleVersion: string = `V1_0_1` -- must be compatible with query descendants in a way that...
local MainFolderName: string = `CoffeeRemotesRefined`
local ModuleFoldersTag: string = `CoffeeRemotesRefined_{ModuleVersion}` -- ...this is evaluated as a SINGLE Tag

local IsStudio: boolean = RunS:IsStudio()
local Prefix: string = `[CoffeeRemotes-Server {ModuleVersion}] ` -- This is only for Output

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
local RFER_PlayerLeft = IsStudio and {`Player Has Left or the PlayerCooldowns[KindOf][UID] was Wiped`} or RFER_TooQuick

--- Default Cooldown (in seconds) between calls per EventName ---
local RemoteEventCooldown: number = 0.03
local RemoteFunctionCooldown: number = 0.03
local UnreliableRemoteEventCooldown: number = 0.01

if not RunS:IsServer() then
	error(`{Prefix} can only be required by Server-Side scripts!`)
end



--- Dependencies ---

-- Signal's Source Repository: https://github.com/Data-Oriented-House/LemonSignal --
local LemonSignal = require(script.Parent.LemonSignal) -- or wherever it's located and whatever it's named

--- /E Dependencies ---



export type RemoteInstance = BaseRemoteEventSubtypes | RemoteFunction -- RemoteEvent | RemoteFunction | UnreliableRemoteEvent
export type CoffeeRemotesObject = RemoteEventType | RemoteFunctionType | UnreliableRemoteEventType
export type KindOf = "RemoteEvent" | "RemoteFunction" | "UnreliableRemoteEvent"
export type KindOfs = "RemoteEvents" | "RemoteFunctions" | "UnreliableRemoteEvents"
export type OnInvokeCallback = (player: Player, ...any) -> (boolean, {})

type UserId = number
type RemoteInstanceName = string
type RemoteInstanceNameTimestampPairs = {
	[RemoteInstanceName]: number?,
}
type CooldownRoot = {
	[UserId]: RemoteInstanceNameTimestampPairs,
}
export type PlayerCooldowns = {
	[KindOfs]: CooldownRoot,
}
export type PlayerCooldownsBackup = {
	[KindOfs]: RemoteInstanceNameTimestampPairs,
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
local BackUpPlayerCooldowns: LemonSignal.Signal<Player, PlayerCooldownsBackup> = LemonSignal.new()

-- Please make sure the name given is compatible with use in :QueryDescendants via the very unsafe #{name} part of the selector
-- There is no safe escape implemented to make the name compatible automatically; And this shall remain such by design, there's no need to overengineer a function just to create four folders with hardcoded names (no user input).
local function mkdir(name: string, where: Instance?): Folder
	if typeof(where) ~= `Instance` then
		where = RS
	end

	local folder_s = (where :: Instance):QueryDescendants(
		`>Folder#{name}.{ModuleFoldersTag}[$CRRV = "{ModuleVersion}"]`
	) :: {[number]: Folder}
	local matches = #folder_s
	-- both a tag of {ModuleFoldersTag}
	-- and an attribute CRRV = {ModuleVersion}
	-- (CRRV ~ CoffeeRemotesRefinedVersion)
	-- all this on top of the Instance being
	-- a Folder and named {name}

	-- if there's multiple matches, every
	-- single of them except one will be
	-- :Destroy()'ed with a warning

	-- most expected and the best case scenario
	if matches < 1 then
		local folder = Instance.new(`Folder`)

		folder.Name = name
		folder:SetAttribute(`CRRV`, ModuleVersion)
		folder:AddTag(ModuleFoldersTag)

		folder.Parent = where -- Parent after naming for compliance with Client's WaitForChild

		return folder
	end

	if matches > 1 then
		local destroyedReferences = {}
		for i = 2, matches do
			local folder = folder_s[i]
			table.insert(destroyedReferences, folder)
			folder.Parent = nil
			Debris:AddItem(folder, 180)
		end
		warn(`{Prefix}Multiple matches found for selector: Folder named "{name}" with Tag {ModuleFoldersTag} and an Attribute "CRRV" equal to "{ModuleVersion}"; You have up to 180 seconds to troubleshoot them via clickable references:`, destroyedReferences)
	end

	return folder_s[1]
end

local MainFolder = mkdir(MainFolderName)
-- The following Three (Folder names) must match on Both Server and Client Side versions of the Module
local RemoteEventsFolder = mkdir(`Events`, MainFolder)
local RemoteFunctionsFolder = mkdir(`Functions`, MainFolder)
local UnreliableRemoteEventsFolder = mkdir(`UnreliableEvents`, MainFolder)



local CoffeeRemotesRefinedServer = {}
export type RemoteEventClass = {
	read instances: RemoteEventClassInstancesTable,
	new: (name: string) -> (RemoteEventType),
}
export type RemoteFunctionClass = {
	read instances: RemoteFunctionClassInstancesTable,
	new: (name: string) -> (RemoteFunctionType),
}
export type UnreliableRemoteEventClass = {
	read instances: UnreliableRemoteEventClassInstancesTable,
	new: (name: string) -> (UnreliableRemoteEventType),
}



local RemoteEventClassInstances: RemoteEventClassInstancesTable = {}
local RemoteEvent = {
	instances = RemoteEventClassInstances,
} :: RemoteEventClass
CoffeeRemotesRefinedServer.RemoteEvent = RemoteEvent



local RemoteFunctionClassInstances: RemoteFunctionClassInstancesTable = {}
local RemoteFunction = {
	instances = RemoteFunctionClassInstances
} :: RemoteFunctionClass
CoffeeRemotesRefinedServer.RemoteFunction = RemoteFunction



local UnreliableRemoteEventClassInstances: UnreliableRemoteEventClassInstancesTable = {}
local UnreliableRemoteEvent = {
	instances = UnreliableRemoteEventClassInstances
} :: UnreliableRemoteEventClass
CoffeeRemotesRefinedServer.UnreliableRemoteEvent = UnreliableRemoteEvent



local function mkremote(name: string, where: Folder): (RemoteInstance | CoffeeRemotesObject, boolean)
	local kindOf: KindOf = where == RemoteEventsFolder and `RemoteEvent`
		or where == RemoteFunctionsFolder and `RemoteFunction`
		or `UnreliableRemoteEvent`
	-- safely escaping names just to use QueryDescendants might be a waste of resources
	--local remote_s = where:QueryDescendants(`>{kindOf}#{name}`)
	
	local firstMatch: RemoteInstance?
	local furtherMatches: {[number]: RemoteInstance} = {}
	local matches = 0
	-- while `remote: RemoteInstance` is false, we sort for such; (suppress linter)
	for _, remote: RemoteInstance in where:GetChildren() do
		if remote.Name ~= name or remote.ClassName ~= kindOf then
			continue
		end
		
		matches += 1
		if matches > 1 then
			table.insert(furtherMatches, remote)
			continue
		end
		firstMatch = remote
	end
	
	
	
	if matches < 1 then
		local remote = Instance.new(kindOf) :: RemoteInstance
		
		remote.Name = name
		remote.Parent = where -- Parent after naming for compliance with Client's WaitForChild
		
		return remote, false
	end
	
	if matches > 1 then
		for _, remote in furtherMatches do
			-- client sided scripts shall use CoffeeRemotesObject.Remote
			-- .AncestryChanged event to detect such stuff safely, although
			-- this is very unlikely to happen
			remote.Parent = nil
			Debris:AddItem(remote, 180)
		end
		warn(`{Prefix}Multiple matches found for selector: {kindOf} named "{name}"; You have up to 180 seconds to troubleshoot them via clickable references:`, furtherMatches)
	end
	
	local object = CoffeeRemotesRefinedServer[kindOf][`instances`][firstMatch] :: CoffeeRemotesObject?
	if object then
		warn(`{Prefix}{kindOf}Object with the name "{name}" already exists! Return the existing object.`)
		return object, true
	end
	
	warn(`{Prefix}{kindOf} with the name "{name}" already exists! Return the existing Instance.`)
	return firstMatch :: RemoteInstance | any, false
end








-- Autocomplete will display all entries for OnServerEvent, all of them can be used as well.
-- OnServerEvent only exists to ease the replacement of Legacy Roblox Remotes;
-- OnServerEvent shouldn't be used when writing newer code - or get ready for confusing autocomplete.

export type BaseRemoteEventSubtypes = RemoteEvent | UnreliableRemoteEvent

type RemoteEventBaseClassInstancesTable = RemoteEventClassInstancesTable | UnreliableRemoteEventClassInstancesTable

export type RemoteEventBaseType<T=BaseRemoteEventSubtypes> = {
	FireClient: (self: RemoteEventBaseType<T>, Player, ...any) -> RemoteEventBaseType<T>,
	FireAllClients: (self: RemoteEventBaseType<T>, ...any) -> RemoteEventBaseType<T>,
	Connect: (self: RemoteEventBaseType<T>, callback: (Player, ...any) -> ()) -> LemonSignal.Connection,
	Wait: (self: RemoteEventBaseType<T>) -> (Player, ...any),
	Once: (self: RemoteEventBaseType<T>, callback: (Player, ...any) -> ()) -> LemonSignal.Connection,
	Disconnect: (self: RemoteEventBaseType<T>) -> RemoteEventBaseType<T>,
	SetCooldown: (self: RemoteEventBaseType<T>, newCooldownTime: number?) -> RemoteEventBaseType<T>,
	Destroy: (self: RemoteEventBaseType<T>) -> (),
	OnServerEvent: RemoteEventBaseType<T>,
	
	-- Use this to detect .Destroying and .AncestryChanged
	read Remote: T, -- Expose a read-only Remote field
	
	-- When the :Destroy of the wrapper happens
	read Destroying: LemonSignal.Signal<>,
}

export type RemoteEventBaseTypeWInternals<T=BaseRemoteEventSubtypes> = {
	_Name: string,
	_RI: T, -- RI = Remote Instance
	_Cooldown: number?,
	_Signal: (LemonSignal.Signal<any>)?,
	_IT: RemoteEventBaseClassInstancesTable,
	_CR: CooldownRoot,
} & RemoteEventBaseType<T>

type RemoteEventBaseDescriptor = {
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
	
	-- For faster typing. <strong>read&write only; Shouldn't be called!</strong>
	OnInvoke: OnInvokeCallback?,
	
	-- Exists to ease the replacement of legacy Remote Functions. <strong>read&write only; Shouldn't be called</strong>
	OnServerInvoke: OnInvokeCallback?,
	
	-- Use this to detect .Destroying and .AncestryChanged
	read Remote: RemoteFunction, -- Expose a read-only Remote field
	
	-- When the :Destroy of the wrapper happens
	read Destroying: LemonSignal.Signal<>,
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
	(self._RI :: BaseRemoteEventSubtypes | any):FireClient(player, ...)

	return self
end

function RemoteEventBaseClass.FireAllClients(self: RemoteEventBaseTypeWInternals, ...)
	-- any is here to quiet down the linter, the type is by definition and must remain RemoteEventBase
	(self._RI :: BaseRemoteEventSubtypes | any):FireAllClients(...)

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



		local lastCallTime = playerEntry[name]
		local now = os.clock()
		if type(lastCallTime) == `number` and now - lastCallTime < cooldownTime then
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

function RemoteEvent.new(name: string): RemoteEventType
	-- any is here to mute type linter; Otherwise we'd have to create an Instance just to mock the type!
	return (RemoteEventBaseClass :: any).new(name, RemoteEventDescriptor) -- :: RemoteEventType
end






local UnreliableRemoteEventDescriptor: RemoteEventBaseDescriptor = {
	Folder = UnreliableRemoteEventsFolder,
	DefaultCooldown = UnreliableRemoteEventCooldown,
	CooldownsRoot = PlayerCooldowns.UnreliableRemoteEvents,
	InstancesTable = UnreliableRemoteEventClassInstances,
}

function UnreliableRemoteEvent.new(name: string): UnreliableRemoteEventType
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

function RemoteFunction.new(name: string): RemoteFunctionType
	if type(name) ~= `string` then
		error(`{Prefix}Can't create an unnamed RemoteFunction! Given name: {name}`)
	end
	
	local remoteOrObject, isUsedByObject = mkremote(name, RemoteFunctionsFolder)
	if isUsedByObject then
		return remoteOrObject :: RemoteFunctionType
	end

	local self = setmetatable({}, RemoteFunctionClass)
	rawset(self :: any, `_Name`, name :: string)
	rawset(self :: any, `_RI`, remoteOrObject :: RemoteFunction | any)
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



		local lastCallTime = playerEntry[name]
		local now = os.clock()
		if type(lastCallTime) == `number` and now - lastCallTime < cooldownTime then
			return false, RFER_TooQuick
		end



		playerEntry[name] = now
		
		return callback(player, ...)
	end
	
	(remoteOrObject :: RemoteFunction | any).OnServerInvoke = OnInvoke
	
	RemoteFunctionClassInstances[remoteOrObject :: RemoteFunction | any] = self :: RemoteFunctionType
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
	local backup: PlayerCooldownsBackup = {}
	
	for kindOf: KindOfs, v: CooldownRoot in PlayerCooldowns do
		
		-- note for contributors: if a yield is ever introduced between reading playerEntry
		-- and writing to it in OnEvent/OnInvoke, this handoff-without-copy becomes unsafe
		-- and a shallow copy of v[UID] shall be written into backup instead of the reference
		
		backup[kindOf] = v[UID] -- store the reference as backup
		-- no need to make a copy, because this reference is no longer used by this module
		v[UID] = nil -- wipe the reference internally
	end
	
	BackUpPlayerCooldowns:Fire(player, backup)
end

Players.PlayerRemoving:Connect(OnPlayerRemoving)

CoffeeRemotesRefinedServer.PlayerCooldowns = PlayerCooldowns
CoffeeRemotesRefinedServer.BackUpPlayerCooldowns = BackUpPlayerCooldowns



local DefaultCooldownSetters: {[KindOf]: (number?) -> ()} = {
	RemoteEvent = function(newDefault: number?)
		--RemoteEventCooldown = newDefault or 0.03 -- unused after module completes initializing
		RemoteEventDescriptor.DefaultCooldown = newDefault or 0.03
	end,
	RemoteFunction = function(newDefault: number?)
		RemoteFunctionCooldown = newDefault or 0.03
	end,
	UnreliableRemoteEvent = function(newDefault: number?)
		--UnreliableRemoteEventCooldown = newDefault or 0.01  -- unused after module completes initializing
		UnreliableRemoteEventDescriptor.DefaultCooldown = newDefault or 0.01
	end,
}

-- if kindOf is not a valid KindOf, there'll be a warning.
-- (export type KindOf = "RemoteEvent" | "RemoteFunction" | "UnreliableRemoteEvent")
-- type(newDefault) ~= `number` -> defaults to hardcoded defaults (0.03 or 0.01 for UnreliableRemoteEvents)
function CoffeeRemotesRefinedServer.SetDefaultCooldown(
	self: CoffeeRemotesRefinedServer,
	kindOf: KindOf,
	newDefault: number?
): CoffeeRemotesRefinedServer
	if type(newDefault) ~= `number` then
		newDefault = nil
	end
	
	local setter = DefaultCooldownSetters[kindOf]
	if not setter then
		warn(`{Prefix} kindOf "{kindOf}" is not a valid input; Default Cooldown for specified kindOf not updated.`)
		return self
	end
	
	setter(newDefault)
	
	return self
end

function CoffeeRemotesRefinedServer.Unpack(
	self: CoffeeRemotesRefinedServer
): (RemoteEventClass, RemoteFunctionClass, UnreliableRemoteEventClass)
	return RemoteEvent, RemoteFunction, UnreliableRemoteEvent
end

table.freeze(CoffeeRemotesRefinedServer)
export type CoffeeRemotesRefinedServer = typeof(CoffeeRemotesRefinedServer)

return CoffeeRemotesRefinedServer :: CoffeeRemotesRefinedServer