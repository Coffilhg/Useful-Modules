--[[--
    NamespaceSync V0.0.0
    Copyright © 2026 Coffilhg (Roblox UserId 517222346)

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/.

    GitHub Repository/Branch with latest version, documentation, etc:
    https://github.com/Coffilhg/Useful-Modules/tree/NamespaceSync
    Stars are appreciated!
--]]--
--!strict
--!optimize 2

const Debris = game:GetService(`Debris`)
const RS = game:GetService(`ReplicatedStorage`)

const LemonSignal = require(`./LemonSignal`)
const ClassNameTypePairs = require(`./ClassNameTypePairs`)

export type ClassName = keyof<ClassNameTypePairs.ClassNameTypePairs>
type ClassType<ClassNameGeneric=ClassName> = index<ClassNameTypePairs.ClassNameTypePairs, ClassNameGeneric>

export type ValidatorModifier = (Instance) -> boolean
export type MutatorModifier = (Instance) -> ()
export type GetOrCreateModifiers = {
	Validator: ValidatorModifier?,
	Mutator: MutatorModifier?,
}
export type AwaitModifiers = {
	Validator: ValidatorModifier?,
	Mutator: MutatorModifier?,
}
type DebugPrefix = (string | any)

const NamespaceSync = {}

local warnFunction = warn


-- Considered samples of "simple" functions:
--[[-- "GetOrCreateSimple" from https://github.com/Coffilhg/Useful-Modules/blob/CoffeeRemotesRefined/src/Server/src/init.luau
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
]]

--[[-- "AwaitSimple" from https://github.com/Coffilhg/Useful-Modules/blob/CoffeeRemotesRefined/src/Client/src/init.luau
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
	local remote = where:FindFirstChild(name)
	
	if typeof(remote) == `Instance` and (remote :: Instance).ClassName == kindOf then
		return CheckForRemoteUsage(kindOf, remote :: RemoteInstance | any, name) -- any to suppress linter
	end
	
	local query = LemonSignal.new() :: LemonSignal.Signal<>
	local searchResult: RemoteInstance
	local connection: RBXScriptConnection
	
	-- while `child: RemoteInstance` is false, we sort for such; (suppress linter)
	local function evaluateChild(child: RemoteInstance): boolean | any
		if child.Name == name and (child :: Instance).ClassName == kindOf then
			searchResult = child
			query:Fire()
			return true
		end

		return
	end

	connection = where.ChildAdded:Connect(evaluateChild :: any)
	for _, child in where:GetChildren() do
		if (evaluateChild :: any)(child) then
			break
		end
	end

	if not searchResult then
		local yieldWarningThread = task.delay(
			YieldWarningTime,
			warn,
			`{Prefix}Waiting for {kindOf} named "{name}". Did you create it on the Server-Side, or is this a typo?`
		)

		query:Wait()

		task.cancel(yieldWarningThread)
		query:Destroy() -- the variable will then be gc'ed
	end

	connection:Disconnect()
	
	-- First thoughts: no check for
	-- `local object = module[kindOf][`instances`][remote] :: CoffeeRemotesObject?`
	-- is needed, the instance was JUST REPLICATED TO THE CLIENT SIDE THIS EXACT MOMENT
	-- So the code would surely be just:
	--return searchResult, false
	-- Pooling Considerations:
	-- If you reparent .Remote of the CoffeeRemotesObject anywhere else, then
	-- call a .new for that same kind and name, once you reparent that one .Remote
	-- back, it lands right here, so we'll still check.
	-- So the final code shall be:
	return CheckForRemoteUsage(kindOf, searchResult, name)
end
]]



-- Makes the input safe for use as an AttributeName; Limits:
-- https://create.roblox.com/docs/en-us/reference/engine/classes/Instance#SetAttribute
-- adds a postfix V for "Version"
const function MakeSafeAttributeName(input: string)
	const sanitized = string.gsub(
		input,
		`[^%w_/%.%-]`,
		``
	)
	
	const startsWithReserved = string.lower(string.sub(sanitized, 1, 3)) == `rbx`
	if startsWithReserved then
		return `_{string.sub(sanitized, 4, 101)}V`
	end
	
	return `{string.sub(sanitized, 1, 99)}V`
end

-- returns Tag to add via :AddTag, AttributeName and AttributeValue to set via :SetAttribute
-- and check vice-versa :HasTag(Tag) and :GetAttribute(AttributeName) == AttributeValue
const function GenerateTagAndAttributeInfo(name: string, projectVersion: string): (string, string, string)
	const tag = `{name}_{projectVersion}`
	const attributeName = MakeSafeAttributeName(name)
	
	return
		tag, -- Tag
		attributeName,
		tag -- AttributeValue
end

-- unified utility to check for tag and attribute match
-- shall it be inlined? That gives better performance but less reliability for the future?
const function VerifyMetadata(
	folder: Instance,
	tag: string,
	attributeName: string,
	attributeValue: string
): boolean
	return folder:HasTag(tag) and folder:GetAttribute(attributeName) == attributeValue
end



--- Core ---

-- Make an [instance of a given className], named as provided or return an already existing one
-- Already existing ones can be further validated by a ValidatorModifier `modifiers.Validator`
-- Newly created ones can be mutated between `.new` and `.Parent = where` by a MutatorModifier
-- It is recommended to have both modifiers if you are using either, however it is allowed to also have only one
const function GetOrCreateManual<T>(
	className: T, -- LSP (T & ClassName)
	name: string,
	where: Instance?,
	modifiers: GetOrCreateModifiers?,
	debugPrefix: DebugPrefix?
): ClassType<T>
	if typeof(where) ~= `Instance` then
		where = RS
	end
	
	const isModifiersATable = type(modifiers) == `table`
	const validator: ValidatorModifier? = isModifiersATable and (modifiers :: any).Validator or nil
	const mutator: MutatorModifier? = isModifiersATable and (modifiers :: any).Mutator or nil
	const isValidatorCallable = type(validator) == `function`
	
	local firstMatch: ClassType<T>?
	const furtherMatches: {[number]: Instance} = {}
	local matches = 0
	
	for _, child in (where :: Instance):GetChildren() do
		if child.ClassName ~= className or child.Name ~= name then
			continue
		end
		if isValidatorCallable then
			if not (validator :: ValidatorModifier)(child) then
				continue
			end
		end

		matches += 1
		if matches > 1 then
			table.insert(furtherMatches, child)
			continue
		end
		firstMatch = child :: ClassType<T>
	end
	
	

	-- if there's multiple matches, every
	-- single of them except one will be
	-- :Destroy()'ed with a warning

	-- most expected and the best case scenario
	if matches < 1 then
		const instance = Instance.new(className)

		instance.Name = name
		
		if type(mutator) == `function` then
			mutator(instance)
		end

		instance.Parent = where -- Parent after naming (and performing other mutations) for compliance with WaitForChild

		return instance :: ClassType<T> -- LSP
	end
	
	if matches > 1 then
		for _, match in furtherMatches do
			match.Parent = nil
			Debris:AddItem(match, 180)
		end
		warnFunction(`{debugPrefix} Multiple matches found for selector: {className} named "{name}" with{isValidatorCallable and ` a custom validator modifier` or ``}; You have up to 180 seconds to troubleshoot them via clickable references:`, furtherMatches)
	end
	
	return firstMatch :: ClassType<T>
end

-- read desc of NamespaceSync.GetOrCreate
const function GetOrCreate<T>(
	className: T, -- actually T & ClassName
	projectVersion: string,
	name: string,
	where: Instance?,
	debugPrefix: DebugPrefix?
): Instance -- actually ClassType<T>
	const tag, attributeName, attributeValue = GenerateTagAndAttributeInfo(name, projectVersion)

	-- both a tag of {tag}
	-- and an attribute {attributeName} = {attributeValue}
	-- all this on top of the Instance being
	-- a {ClassName} and named {name}

	return GetOrCreateManual(
		className,
		name,
		where,
		{
			Validator = function(instance: Instance)
				return VerifyMetadata(instance, tag, attributeName, attributeValue)
			end,
			Mutator = function(instance: Instance)
				instance:AddTag(tag)
				instance:SetAttribute(attributeName, attributeValue)
			end,
		},
		debugPrefix
	)
end

-- Wait for [instance of a given className] named as provided and matching
-- ones can be further validated by a ValidatorModifier `modifiers.Validator`
const function AwaitManual<T>(
	className: T, -- LSP (T & ClassName)
	name: string,
	where: Instance?,
	modifiers: AwaitModifiers?,
	debugPrefix: DebugPrefix?,
	yieldWarningTime: number?
): ClassType<T>
	if typeof(where) ~= `Instance` then
		where = RS
	end
	if type(yieldWarningTime) ~= `number` then
		yieldWarningTime = 15
	end
	
	const validator: ValidatorModifier? = type(modifiers) == `table` and (modifiers :: any).ValidatorModifier or nil
	const isValidatorCallable = type(validator) == `function`
	
	const firstMatch = (where :: Instance):FindFirstChild(name)

	if typeof(firstMatch) == `Instance`
		and (firstMatch :: Instance).ClassName == className
		and (
			(not isValidatorCallable)
				or (validator :: ValidatorModifier)(firstMatch)
		)
	then
		return firstMatch :: ClassType<T>
	end
	
	
	
	const query = LemonSignal.new() :: LemonSignal.Signal<>
	local searchResult: ClassType<T>

	const function evaluateChild(child: Instance): boolean | any
		if (child :: Instance).ClassName == className
			and child.Name == name
			and (
				(not isValidatorCallable)
					or (validator :: ValidatorModifier)(child)
			)
		then
			searchResult = child :: ClassType<T>
			query:Fire()
			return true
		end

		return
	end

	const connection: RBXScriptConnection = (where :: Instance).ChildAdded:Connect(evaluateChild)
	for _, child in (where :: Instance):GetChildren() do
		if evaluateChild(child) then
			break
		end
	end

	if not searchResult then
		local yieldWarningThread = task.delay(
			yieldWarningTime,
			warnFunction,
			`{debugPrefix} Waiting for {className} {(where :: Instance):GetFullName()}["{name}"]. Did you :{className == `Folder` and `mkdir` or `GetOrCreate`} such "{name}"? Do their versions match?`
		)

		query:Wait()

		task.cancel(yieldWarningThread)
		query:Destroy() -- the variable will then be gc'ed
	end

	connection:Disconnect()

	return searchResult
end

-- read desc of NamespaceSync.Await
const function Await<T>(
	className: T, -- actually T & ClassName
	projectVersion: string,
	name: string,
	where: Instance?,
	debugPrefix: DebugPrefix?,
	yieldWarningTime: number?
): Instance -- actually ClassType<T>
	const tag, attributeName, attributeValue = GenerateTagAndAttributeInfo(name, projectVersion)

	return AwaitManual(
		className,
		name,
		where,
		{
			Validator = function(instance: Instance)
				return VerifyMetadata(instance, tag, attributeName, attributeValue)
			end,
		},
		debugPrefix,
		yieldWarningTime
	)
end

--- /E Core ---


-- Make an [instance of a given className], named as provided or return an already existing one
-- Already existing ones can be further validated by a ValidatorModifier `modifiers.Validator`
-- Newly created ones can be mutated between `.new` and `.Parent = where` by a MutatorModifier
-- It is recommended to have both modifiers if you are using either, however it is allowed to also have only one
function NamespaceSync.GetOrCreateManual<T>(
	self: NamespaceSync,
	className: (T & ClassName),
	name: string,
	where: Instance?,
	modifiers: GetOrCreateModifiers?,
	debugPrefix: DebugPrefix?
): ClassType<T>
	return GetOrCreateManual(
		className,
		name,
		where,
		modifiers,
		debugPrefix
	)
end

-- this looks pointless, won't be making an AwaitSimple
--function NamespaceSync.GetOrCreateSimple<T>(
--	self: NamespaceSync,
--	className: (T & ClassName),
--	name: string,
--	where: Instance?,
--	debugPrefix: DebugPrefix?
--)
--	return GetOrCreateManual(
--		className,
--		name,
--		where,
--		nil,
--		debugPrefix
--	)
--end

-- Make an [instance of a given className], named as provided or return an already existing one with matching specifications
-- Applies preset auto-generated metadata: tag and attribute with a value and matches by the same criteria
function NamespaceSync.GetOrCreate<T>(
	self: NamespaceSync,
	className: (T & ClassName),
	projectVersion: string,
	name: string,
	where: Instance?,
	debugPrefix: DebugPrefix?
): ClassType<T>
	return GetOrCreate(
		className,
		projectVersion,
		name,
		where,
		debugPrefix
	) :: ClassType<T>
end



function NamespaceSync.AwaitManual<T>(
	self: NamespaceSync,
	className: (T & ClassName),
	name: string,
	where: Instance?,
	modifiers: AwaitModifiers?,
	debugPrefix: DebugPrefix?,
	yieldWarningTime: number?
): ClassType<T>
	return AwaitManual(
		className,
		name,
		where,
		modifiers,
		debugPrefix,
		yieldWarningTime
	)
end

-- Wait for [instance of a given className] named as provided and with matching
-- specifications; usually you'd only want to use this on the client-side
function NamespaceSync.Await<T>(
	self: NamespaceSync,
	className: (T & ClassName),
	projectVersion: string,
	name: string,
	where: Instance?,
	debugPrefix: DebugPrefix?,
	yieldWarningTime: number?
): ClassType<T>
	return Await(
		className,
		projectVersion,
		name,
		where,
		debugPrefix,
		yieldWarningTime
	) :: ClassType<T>
end

-- Make a folder named as provided or return an already existing one with matching specifications
function NamespaceSync.mkdir(
	self: NamespaceSync,
	projectVersion: string,
	name: string,
	where: Instance?,
	debugPrefix: (string | any)?
): Folder
	return GetOrCreate(
		"Folder",
		projectVersion,
		name,
		where,
		debugPrefix
	) :: Folder
end

-- Wait for folder named as provided and with matching specifications;
-- usually you'd only want to use this on the client-side
function NamespaceSync.cd(
	self: NamespaceSync,
	projectVersion: string,
	name: string,
	where: Instance?,
	debugPrefix: (string | any)?,
	yieldWarningTime: number?
): Folder
	return Await(
		"Folder",
		projectVersion,
		name,
		where,
		debugPrefix,
		yieldWarningTime
	) :: Folder
end

-- Set a function to be called instead of `warn`
-- defaults to default Roblox' `warn` (if given warnCallback is nil or not a function)
function NamespaceSync.SetWarnCallback(
	self: NamespaceSync,
	warnCallback: (...any) -> ()
): NamespaceSync
	if type(warnCallback) ~= `function` then
		warnFunction = warn
		return self
	end
	warnFunction = warnCallback
	
	return self
end

table.freeze(NamespaceSync)
export type NamespaceSync = typeof(NamespaceSync)
return NamespaceSync