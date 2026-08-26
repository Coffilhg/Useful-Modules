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
type ClassType<ClassName="Folder"> = index<ClassNameTypePairs.ClassNameTypePairs, ClassName>

const NamespaceSync = {}

local warnFunction = warn


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


-- Make an instance of a given className, named as provided or return an already existing one with matching specifications
function NamespaceSync.GetOrCreate<T>(
	self: NamespaceSync,
	className: (T & ClassName),
	name: string,
	projectVersion: string,
	where: Instance?,
	debugPrefix: (string | any)?
): ClassType<T>
	if typeof(where) ~= `Instance` then
		where = RS
	end
	
	const tag, attributeName, attributeValue = GenerateTagAndAttributeInfo(name, projectVersion)
	
	const folder_s: {[number]: Instance} = {}
	local matches = 0
	
	for _, child in (where :: Instance):GetChildren() do
		if not (child.ClassName == className and child.Name == name) then
			continue
		end
		if not VerifyMetadata(child, tag, attributeName, attributeValue) then
			continue
		end
		
		table.insert(folder_s, child)
		matches += 1
	end
	-- both a tag of {tag}
	-- and an attribute {attributeName} = {attributeValue}
	-- all this on top of the Instance being
	-- a {ClassName} and named {name}

	-- if there's multiple matches, every
	-- single of them except one will be
	-- :Destroy()'ed with a warning

	-- most expected and the best case scenario
	if matches < 1 then
		local folder = Instance.new(className)

		folder.Name = name
		folder:SetAttribute(attributeName, attributeValue)
		folder:AddTag(tag)

		folder.Parent = where -- Parent after naming (and performing other mutations) for compliance with WaitForChild

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
		warnFunction(`{debugPrefix} Multiple matches found for selector: {className} named "{name}" with Tag \{{tag}} and an Attribute "{attributeName}" equal to "{attributeValue}"; You have up to 180 seconds to troubleshoot them via clickable references:`, destroyedReferences)
	end

	return folder_s[1] :: ClassType<T>
end

-- Wait for [instance of a given className] named as provided and with matching
-- specifications; usually you'd only want to use this on the client-side
function NamespaceSync.Await<T>(
	self: NamespaceSync,
	className: (T & ClassName),
	name: string,
	projectVersion: string,
	where: Instance?,
	debugPrefix: (string | any)?,
	yieldWarningTime: number?
): ClassType<T>
	if typeof(where) ~= `Instance` then
		where = RS
	end
	if type(yieldWarningTime) ~= `number` then
		yieldWarningTime = 15
	end
	
	const tag, attributeName, attributeValue = GenerateTagAndAttributeInfo(name, projectVersion)
	
	
	
	const folder = (where :: Instance):FindFirstChild(name)

	if typeof(folder) == `Instance`
		and (folder :: Instance).ClassName == className
		and VerifyMetadata(folder, tag, attributeName, attributeValue)
	then
		return folder :: ClassType<T>
	end

	const query = LemonSignal.new() :: LemonSignal.Signal<>
	local searchResult: ClassType<T>

	local function evaluateChild(child: Instance): boolean | any
		if (child :: Instance).ClassName == className
			and child.Name == name
			and VerifyMetadata(child, tag, attributeName, attributeValue)
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

-- Make an folder named as provided or return an already existing one with matching specifications
function NamespaceSync.mkdir(
	self: NamespaceSync,
	name: string,
	projectVersion: string,
	where: Instance?,
	debugPrefix: (string | any)?
): ClassType<"Folder">
	-- code is too complex to typecheck without this suppression using `any`
	return (self :: any):GetOrCreate(
		"Folder",
		name,
		projectVersion,
		where,
		debugPrefix
	)
end

-- Wait for folder named as provided and with matching specifications;
-- usually you'd only want to use this on the client-side
function NamespaceSync.cd(
	self: NamespaceSync,
	name: string,
	projectVersion: string,
	where: Instance?,
	debugPrefix: (string | any)?,
	yieldWarningTime: number?
): ClassType<"Folder">
	-- code is too complex to typecheck without this suppression using `any`
	return (self :: any):Await(
		"Folder",
		name,
		projectVersion,
		where,
		debugPrefix,
		yieldWarningTime
	)
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