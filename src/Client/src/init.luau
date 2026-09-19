--[[--
    CoffeeRemotesRefined (Client-Side) V1.0.2
    Copyright © 2026 Coffilhg (Roblox UserId 517222346)

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/.

    GitHub Repository/Branch with latest version, documentation, etc:
    https://github.com/Coffilhg/Useful-Modules/tree/CoffeeRemotesRefined
    Stars are appreciated!
    
    Please make sure you're also using the Server-Side part of CoffeeRemotes (Refined)!
    List this as part of your wally [server-dependencies] (and make sure their versions match):
    CoffeeRemotesServer = "coffilhg/coffeeremotes-server@1.0.2"

    Namespacing (awaiting the module's Folders and Remote Instances) is delegated
    to NamespaceSync, which must sit next to this module (script.Parent):
    https://github.com/Coffilhg/Useful-Modules/tree/NamespaceSync
--]]--
--!strict
--!optimize 2
-- no native here, it's a CLIENT SIDE script!

local RunS = game:GetService(`RunService`)
local RS = game:GetService(`ReplicatedStorage`)

-- The following Two must match on Both Server and Client Side versions of the Module
-- ModuleVersion is handed to NamespaceSync as the projectVersion, so it takes part
-- in the Folders' metadata (tag `{FolderName}_{ModuleVersion}` + a matching attribute).
-- Bump it on BOTH sides whenever that metadata scheme changes.
local ModuleVersion: string = `V1_0_2`
local MainFolderName: string = `CoffeeRemotesRefined`

local YieldWarningTime: number = 15
local Prefix: string = `[CoffeeRemotes-Client {ModuleVersion}] ` -- This is only for Output
-- NamespaceSync inserts its own space after the debugPrefix, hence the unpadded variants.
-- The hints replace the ones the old handwritten yield warnings used to carry.
local DebugPrefix: string = `[CoffeeRemotes-Client {ModuleVersion}]`
local FolderDebugPrefix: string = `{DebugPrefix} [Did you add and require the Server-Side part of CoffeeRemotes (Refined)? Do their versions match?]`
local RemoteDebugPrefix: string = `{DebugPrefix} [Did you create it on the Server-Side, or is this a typo?]`

if not RunS:IsClient() then
	error(`{Prefix} can only be required by Client-Side scripts!`)
end



--- Dependencies ---

-- Signal's Source Repository: https://github.com/Data-Oriented-House/LemonSignal --
local LemonSignal = require(script.Parent.LemonSignal) -- or wherever it's located and whatever it's named

-- NamespaceSync's Source Repository/Branch: https://github.com/Coffilhg/Useful-Modules/tree/NamespaceSync --
local NamespaceSync = require(script.Parent.NamespaceSync) -- or wherever it's located and whatever it's named

--- /E Dependencies ---



export type RemoteInstance = BaseRemoteEventSubtypes | RemoteFunction -- RemoteEvent | RemoteFunction | UnreliableRemoteEvent
export type CoffeeRemotesObject = RemoteEventType | RemoteFunctionType | UnreliableRemoteEventType
type KindOf = "RemoteEvent" | "RemoteFunction" | "UnreliableRemoteEvent"
type OnInvokeCallback = (...any) -> (boolean, {})

type ClassInstancesTable<T = RemoteInstance, U = CoffeeRemotesObject> = {
	[T]: U
}
type RemoteEventClassInstancesTable = ClassInstancesTable<RemoteEvent, RemoteEventType>
type RemoteFunctionClassInstancesTable = ClassInstancesTable<RemoteFunction, RemoteFunctionType>
type UnreliableRemoteEventClassInstancesTable = ClassInstancesTable<UnreliableRemoteEvent, UnreliableRemoteEventType>

local MainFolder = NamespaceSync:cd(ModuleVersion, MainFolderName, RS, false, FolderDebugPrefix, YieldWarningTime)
-- The following Three (Folder names) must match on Both Server and Client Side versions of the Module
local RemoteEventsFolder = NamespaceSync:cd(ModuleVersion, `Events`, MainFolder, false, FolderDebugPrefix, YieldWarningTime)
local RemoteFunctionsFolder = NamespaceSync:cd(ModuleVersion, `Functions`, MainFolder, false, FolderDebugPrefix, YieldWarningTime)
local UnreliableRemoteEventsFolder = NamespaceSync:cd(ModuleVersion, `UnreliableEvents`, MainFolder, false, FolderDebugPrefix, YieldWarningTime)



local CoffeeRemotesRefinedClient = {}
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
CoffeeRemotesRefinedClient.RemoteEvent = RemoteEvent



local RemoteFunctionClassInstances: RemoteFunctionClassInstancesTable = {}
local RemoteFunction = {
	instances = RemoteFunctionClassInstances
} :: RemoteFunctionClass
CoffeeRemotesRefinedClient.RemoteFunction = RemoteFunction



local UnreliableRemoteEventClassInstances: UnreliableRemoteEventClassInstancesTable = {}
local UnreliableRemoteEvent = {
	instances = UnreliableRemoteEventClassInstances
} :: UnreliableRemoteEventClass
CoffeeRemotesRefinedClient.UnreliableRemoteEvent = UnreliableRemoteEvent



local function CheckForRemoteUsage(kindOf: KindOf, remote: RemoteInstance, name: string): (RemoteInstance | CoffeeRemotesObject, boolean)
	local object = CoffeeRemotesRefinedClient[kindOf][`instances`][remote] :: CoffeeRemotesObject?
	if object then
		warn(`{Prefix}{kindOf}Object with the name "{name}" already exists! Return the existing object.`)
		return object, true
	end

	return remote, false
end
local function GetRemote(name: string, where: Folder): (RemoteInstance | CoffeeRemotesObject, boolean)
	local kindOf: KindOf = where == RemoteEventsFolder and `RemoteEvent`
		or where == RemoteFunctionsFolder and `RemoteFunction`
		or `UnreliableRemoteEvent`
	
	local remote: RemoteInstance = NamespaceSync:AwaitManual(
		kindOf,
		name,
		where,
		nil, -- no modifiers; no Validator is needed for plain Remote Instances
		false, -- isRecursive; direct children of {where} only
		RemoteDebugPrefix,
		YieldWarningTime
	) :: any
	
	-- First thoughts: no check for
	-- `local object = module[kindOf][`instances`][remote] :: CoffeeRemotesObject?`
	-- is needed, cuz the Instance was JUST REPLICATED TO THE CLIENT SIDE THIS EXACT MOMENT
	-- So the code would surely be just:
	--return remote, false
	-- Pooling Considerations:
	-- If you reparent .Remote of the CoffeeRemotesObject anywhere else, then
	-- call a .new for that same kind and name, once you reparent that one .Remote
	-- back, it lands right here, so we'll still check.
	-- So the final code shall be:
	return CheckForRemoteUsage(kindOf, remote, name)
end

export type BaseRemoteEventSubtypes = RemoteEvent | UnreliableRemoteEvent

type RemoteEventBaseClassInstancesTable = RemoteEventClassInstancesTable | UnreliableRemoteEventClassInstancesTable

export type RemoteEventBaseType<T=BaseRemoteEventSubtypes> = {
	FireServer: (self: RemoteEventBaseType<T>, ...any) -> RemoteEventBaseType<T>,
	Connect: (self: RemoteEventBaseType<T>, callback: (...any) -> ()) -> LemonSignal.Connection,
	Wait: (self: RemoteEventBaseType<T>) -> (...any),
	Once: (self: RemoteEventBaseType<T>, callback: (...any) -> ()) -> LemonSignal.Connection,
	Disconnect: (self: RemoteEventBaseType<T>) -> RemoteEventBaseType<T>,
	Destroy: (self: RemoteEventBaseType<T>) -> (),
	OnClientEvent: RemoteEventBaseType<T>,
	
	-- Use this to detect .Destroying and .AncestryChanged
	read Remote: T, -- Expose a read-only Remote field
	
	-- When the :Destroy of the wrapper happens
	read Destroying: LemonSignal.Signal<>,
}

export type RemoteEventBaseTypeWInternals<T=BaseRemoteEventSubtypes> = {
	--_Name: string,
	_RI: T, -- RI = Remote Instance
	_Signal: (LemonSignal.Signal<any>)?,
	_IT: RemoteEventBaseClassInstancesTable,
} & RemoteEventBaseType<T>

type RemoteEventBaseDescriptor = {
	Folder: Folder,
	InstancesTable: RemoteEventBaseClassInstancesTable,
}

export type RemoteEventType = RemoteEventBaseType<RemoteEvent>
export type UnreliableRemoteEventType = RemoteEventBaseType<UnreliableRemoteEvent>

export type RemoteFunctionType = {
	InvokeServer: (self: RemoteFunctionType, ...any) -> (boolean, {}),
	Destroy: (self: RemoteFunctionType) -> (),
	
	-- For faster typing. <strong>read&write only; Shouldn't be called!</strong>
	OnInvoke: OnInvokeCallback?,
	
	-- Exists to ease the replacement of legacy Remote Functions. <strong>read&write only; Shouldn't be called</strong>
	OnClientInvoke: OnInvokeCallback?,
	
	-- Use this to detect .Destroying and .AncestryChanged
	read Remote: RemoteFunction, -- Expose a read-only Remote field
	
	-- When the :Destroy of the wrapper happens
	read Destroying: LemonSignal.Signal<>,
}

export type RemoteFunctionTypeWInternals = {
	--_Name: string,
	_RI: RemoteFunction, -- RI = Remote Instance
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

function RemoteEventBaseClass.FireServer(
	self: RemoteEventBaseTypeWInternals,
	...
): RemoteEventBaseTypeWInternals
	-- any is here to quiet down the linter, the type is by definition and must remain RemoteEventBase
	(self._RI :: BaseRemoteEventSubtypes | any):FireServer(...)
	
	return self
end

function RemoteEventBaseClass.Connect(self: RemoteEventBaseTypeWInternals, callback : (...any) -> ())
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

function RemoteEventBaseClass.Destroy(self: RemoteEventBaseTypeWInternals): ()
	self:Disconnect()
	
	local destroying = rawget(self :: any, `_Destroying`) :: LemonSignal.Signal<>
	local remote = rawget(self :: any, `_RI`) :: RemoteEvent | UnreliableRemoteEvent
	local instancesTable = rawget(self :: any, `_IT`) :: {[RemoteEvent | UnreliableRemoteEvent]: RemoteEventBaseType<RemoteEvent | UnreliableRemoteEvent>}
	
	if destroying then
		destroying:Fire()
		destroying:DisconnectAll()
	end
	
	instancesTable[remote] = nil

	setmetatable(self, DestroyedMetatable)
	--rawset(self :: any, `_Name`, nil)
	rawset(self :: any, `_RI`, nil)
	rawset(self :: any, `_IT`, nil)
	rawset(self :: any, `_Destroying`, nil)
	rawset(self :: any, `OnClientEvent`, nil)
end
-- T must be RemoteEventBase
function RemoteEventBaseClass.new<T>(
	name: string,
	descriptor: RemoteEventBaseDescriptor
): RemoteEventBaseType<T>
	if type(name) ~= `string` then
		error(`{Prefix}Can't create an unnamed RemoteEvent! Given name: {name}`)
	end

	local remoteOrObject, isUsedByObject = GetRemote(name, descriptor.Folder)
	if isUsedByObject then
		return remoteOrObject :: RemoteEventBaseType<T>
	end
	
	local instancesTable = descriptor.InstancesTable
	
	
	
	local self = setmetatable({}, RemoteEventBaseClass)
	--rawset(self :: any, `_Name`, name :: string)
	rawset(self :: any, `_RI`, remoteOrObject :: T)
	rawset(self :: any, `_IT`, instancesTable)
	rawset(self :: any, `_Destroying`, LemonSignal.new())
	-- Exists to ease the replacement of legacy Remote Events and Unreliable Remote Events.
	rawset(self :: any, `OnClientEvent`, self :: RemoteEventBaseType<T>)
	
	local function OnEvent(...)
		local signal = (self :: any)[`_Signal`] :: LemonSignal.Signal<any>
		if signal then
			signal:Fire(...)
		end
	end
	
	-- any is here to quiet down the linter, the type must be T
	(remoteOrObject :: T | any).OnClientEvent:Connect(OnEvent)
	
	instancesTable[remoteOrObject :: T] = self :: RemoteEventBaseType<T>
	return self :: RemoteEventBaseType<T>
end






local RemoteEventDescriptor: RemoteEventBaseDescriptor = {
	Folder = RemoteEventsFolder,
	InstancesTable = RemoteEventClassInstances,
}

function RemoteEvent.new(name: string): RemoteEventType
	return (RemoteEventBaseClass :: any).new(name, RemoteEventDescriptor) -- :: RemoteEventType
end






local UnreliableRemoteEventDescriptor: RemoteEventBaseDescriptor = {
	Folder = UnreliableRemoteEventsFolder,
	InstancesTable = UnreliableRemoteEventClassInstances,
}

function UnreliableRemoteEvent.new(name: string): UnreliableRemoteEventType
	return (RemoteEventBaseClass :: any).new(name, UnreliableRemoteEventDescriptor) -- :: UnreliableRemoteEventType
end






local RemoteFunctionClass = {}

function RemoteFunctionClass.InvokeServer(self: RemoteFunctionTypeWInternals, ...)
	return self._RI:InvokeServer(...)
end

function RemoteFunctionClass.Destroy(self: RemoteFunctionTypeWInternals)
	local destroying = rawget(self :: any, `_Destroying`) :: LemonSignal.Signal<>
	local remote = self._RI
	
	if destroying then
		destroying:Fire()
		destroying:DisconnectAll()
	end
	
	RemoteFunctionClassInstances[remote] = nil

	setmetatable(self, DestroyedMetatable)
	--rawset(self :: any, `_Name`, nil)
	rawset(self :: any, `_RI`, nil)
	rawset(self :: any, `_OnInvoke`, nil)
	rawset(self :: any, `_Destroying`, nil)
end

function RemoteFunctionClass.__newindex(self: RemoteFunctionTypeWInternals, key, value)
	if key == `OnClientInvoke` or key == `OnInvoke` then
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
	if key == `OnClientInvoke` or key == `OnInvoke` then
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

	local remoteOrObject, isUsedByObject = GetRemote(name, RemoteFunctionsFolder)
	if isUsedByObject then
		return remoteOrObject :: RemoteFunctionType
	end

	local self = setmetatable({}, RemoteFunctionClass)
	--rawset(self :: any, `_Name`, name :: string)
	rawset(self :: any, `_RI`, remoteOrObject :: RemoteFunction | any)
	rawset(self :: any, `_Destroying`, LemonSignal.new())

	local function OnInvoke(...): (boolean, {})
		local callback = (self :: any)._OnInvoke :: OnInvokeCallback
		if type(callback) ~= `function` then
			return false, {`OnClientInvoke Callback for name="{name}" wasn't registered, but the object exists!`}
		end
		
		return callback(...)
	end
	
	(remoteOrObject :: RemoteFunction | any).OnClientInvoke = OnInvoke

	RemoteFunctionClassInstances[remoteOrObject :: RemoteFunction | any] = self :: RemoteFunctionType
	return self :: RemoteFunctionType
end






-- Defaults to 15 whenever newYieldWarningTime is NaN, math.huge (inf) or it's type() ~= `number`
function CoffeeRemotesRefinedClient.SetYieldWarningTime(
	self: CoffeeRemotesRefinedClient,
	newYieldWarningTime: number?
): CoffeeRemotesRefinedClient
	if type(newYieldWarningTime) ~= `number` then
		YieldWarningTime = 15
		return self
	end
	
	-- the only limits built-in here are to prevent the following warning
	-- "Calling task.delay(t, f) where t is either NaN or infinite will cause t to default to 0."
	
	if newYieldWarningTime ~= newYieldWarningTime or newYieldWarningTime == math.huge then
		YieldWarningTime = 15
		return self
	end
	
	YieldWarningTime = newYieldWarningTime

	return self
end

function CoffeeRemotesRefinedClient.Unpack(
	self: CoffeeRemotesRefinedClient
): (RemoteEventClass, RemoteFunctionClass, UnreliableRemoteEventClass)
	return RemoteEvent, RemoteFunction, UnreliableRemoteEvent
end

table.freeze(CoffeeRemotesRefinedClient)
export type CoffeeRemotesRefinedClient = typeof(CoffeeRemotesRefinedClient)

return CoffeeRemotesRefinedClient :: CoffeeRemotesRefinedClient