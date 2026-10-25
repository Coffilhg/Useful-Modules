--[[--
    CreateInstanceCoffee V0.1.0
    Copyright © 2026 Coffilhg (Roblox UserId 517222346)

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/.

    GitHub Repository/Branch with latest version, documentation, etc:
    https://github.com/Coffilhg/Useful-Modules/tree/CreateInstance
    Stars are appreciated!
--]]--

--!strict
--!optimize 2

const ClassNameTypePairs = require(`./ClassNameTypePairs`)
const CoffeeObjects = require(`./CoffeeObjects`)
const Val, Fol = CoffeeObjects.CoffeeBaseValue, CoffeeObjects.CoffeeFolder

type ClassNames = ClassNameTypePairs.ClassNameTypePairs
type ClassName = keyof<ClassNames>

type Create = <ClassNameGeneric>(ClassNameGeneric | ClassName | "") -> (
	(Properties<index<ClassNames, ClassNameGeneric>>) -> index<ClassNames, ClassNameGeneric>
)
type CreateMissing = (Instance?) -> Create
type Connection = { Disconnect: (any) -> () }
type Bindings = {[any]: {Connection}} -- property name -> {Changed, Destroying}; CoffeeFolder -> {ChildAdded, Destroying}



-- Locally-defined equivalent of CoffeeObjects.CoffeeBaseValueStrict<T>,
-- since type functions can't reference the outer `CoffeeObjects` local.
type function CoffeeBaseValueStrict(T: type)
	local t = types.newtable()
	t:setproperty(types.singleton("Value"), T)
	t:setproperty(types.singleton("Changed"), types.any) -- LemonSignal.Signal<T, T> shape, simplified
	t:setproperty(types.singleton("Destroying"), types.any)
	t:setproperty(types.singleton("Destroy"), types.any)
	t:setproperty(types.singleton("GetPath"), types.any)
	t:setproperty(types.singleton("GetFullName"), types.any)
	return t
end

type function Properties(instance: type?)
	local properties = types.newtable()

	while instance do
		for i, v in instance:properties() do
			-- Explicitly skip methods
			if (v.read and v.read.tag == "function") or (v.write and v.write.tag == "function") then
				continue
			end

			-- Skip properties that strictly lack a write type
			if not v.write then
				continue
			end

			-- Assign only writable properties, as T or CoffeeBaseValue<T>
			properties:setproperty(i, types.optional(types.unionof(
				v.write,
				CoffeeBaseValueStrict(v.write)
			)))
		end

		instance = instance:readparent()
	end

	properties:setindexer(types.number, types.any)

	return properties
end



const function release(entry: {Connection})
	for _, connection in entry do
		connection:Disconnect()
	end
end

-- The first applyProps call of an Instance creates its Bindings and the Destroying cleanup
const function ensureBindings(instance: Instance, bindings: Bindings?): Bindings
	if bindings then
		return bindings
	end

	const new: Bindings = {}
	instance.Destroying:Once(function()
		for _, entry in new do
			release(entry)
		end
		table.clear(new)
	end)
	return new
end

-- Binds instance[key] to the CoffeeBaseValue, replacing an earlier binding of the same key.
-- The binding is released when the CoffeeBaseValue is destroyed (also when it's removed from its CoffeeFolder).
const function bind(instance: Instance, bindings: Bindings, key: any, value: CoffeeObjects.CoffeeBaseValue)
	const prev = bindings[key]
	if prev then
		release(prev)
	end

	local entry: {Connection}
	entry = {
		value.Changed:Connect(function(_, newValue)
			(instance :: any)[key] = newValue
		end),
		value.Destroying:Connect(function()
			if bindings[key] == entry then
				release(entry)
				bindings[key] = nil
			end
		end),
	}
	bindings[key] = entry

	;(instance :: any)[key] = value.Value
end

-- Applies the CoffeeFolder's children like more props (unless the props loop already did), then follows it:
-- children added later get applied too, until the CoffeeFolder or the Instance is destroyed.
-- Removed children need no handling: a CoffeeFolder destroys them, which releases their bindings.
-- A CoffeeFolder only ever holds CoffeeBaseValues and CoffeeFolders.
const function applyFolder(instance: Instance, bindings: Bindings, folder: CoffeeObjects.CoffeeFolder, applyChildren: boolean)
	if applyChildren then
		for key, value in folder do
			if Val.validateClass(value) or Val.validateUnlinkedClass(value) then
				bind(instance, bindings, key, value)
			else
				applyFolder(instance, bindings, value, true)
			end
		end
	end

	if bindings[folder] then
		return -- already followed
	end

	local entry: {Connection}
	entry = {
		folder.ChildAdded:Connect(function(key, value: CoffeeObjects.CoffeeBaseValue | CoffeeObjects.CoffeeFolder)
			if Val.validateClass(value) or Val.validateUnlinkedClass(value) then
				bind(instance, bindings, key, value :: CoffeeObjects.CoffeeBaseValue)
				return
			end
			applyFolder(instance, bindings, value :: CoffeeObjects.CoffeeFolder, true)
		end),
		folder.Destroying:Connect(function()
			if bindings[folder] == entry then
				release(entry)
				bindings[folder] = nil
			end
		end),
	}
	bindings[folder] = entry
end



const function Create<ClassNameGeneric>(className: ClassNameGeneric | ClassName | "")
	const instance = Instance.new(className)
	local bindings: Bindings -- set on the first applyProps call

	const function applyProps(props: {[any]: any})
		if type(props) ~= `table` then
			return instance
		end
		bindings = ensureBindings(instance, bindings)
		const isFolder = Fol.validateClass(props) or Fol.validateUnlinkedClass(props)
		
		const parent = props[`Parent`]
		if type(parent) ~= `nil` and not isFolder then
			props[`Parent`] = nil -- ignore in the loop (never on a CoffeeFolder, it would destroy that child)
		end

		for k, v in props do
			if typeof(v) == `Instance` and type(k) == `number` then
				v.Parent = instance
				continue
			end
			if type(v) == `table` then
				if Val.validateClass(v) or Val.validateUnlinkedClass(v) then
					bind(instance, bindings, k, v)
					continue
				end
				if Fol.validateClass(v) or Fol.validateUnlinkedClass(v) then
					applyFolder(instance, bindings, v, true)
					continue
				end
			end

			(instance :: any)[k] = v
		end

		if type(parent) ~= `nil` then
			instance.Parent = parent -- a wrong type errors here, like any other property
		end

		if isFolder then
			applyFolder(instance, bindings, props, false) -- the loop above already applied its children
		end

		return instance
	end

	return applyProps
end

-- The create inside of CreateMissing is essentially the same as the base Create.
-- Keep it that way. When changes are made to Create, apply them to create too.

const function CreateMissing(existing: Instance?)
	const function create<ClassNameGeneric>(className: ClassNameGeneric | ClassName | "")
		const isValid: boolean = typeof(existing) == `Instance` and existing.ClassName == className
		const instance: Instance = if isValid then existing :: Instance else Instance.new(className)
		local bindings: Bindings -- set on the first applyProps call

		const function applyProps(props: {[any]: any})
			if isValid then
				return instance
			end

			if type(props) ~= `table` then
				return instance
			end
			bindings = ensureBindings(instance, bindings)
			const isFolder = Fol.validateClass(props) or Fol.validateUnlinkedClass(props)

			const parent = props[`Parent`]
			if type(parent) ~= `nil` and not isFolder then
				props[`Parent`] = nil -- ignore in the loop (never on a CoffeeFolder, it would destroy that child)
			end

			for k, v in props do
				if typeof(v) == `Instance` and type(k) == `number` then
					v.Parent = instance
					continue
				end
				if type(v) == `table` then
					if Val.validateClass(v) or Val.validateUnlinkedClass(v) then
						bind(instance, bindings, k, v)
						continue
					end
					if Fol.validateClass(v) or Fol.validateUnlinkedClass(v) then
						applyFolder(instance, bindings, v, true)
						continue
					end
				end

				(instance :: any)[k] = v
			end

			if type(parent) ~= `nil` then
				instance.Parent = parent -- a wrong type errors here, like any other property
			end

			if isFolder then
				applyFolder(instance, bindings, props, false) -- the loop above already applied its children
			end

			return instance
		end

		return applyProps
	end

	return create
end

const CreateInstance = {
	Create = Create :: Create,
	CreateMissing = CreateMissing :: CreateMissing,
}

-- Quick API documentation:
-- ---
-- Create(className)(props)
-- creates an Instance of the given className (if possible using Instance.new), applies the given properties, all number indexed Instances = children; If key ["Parent"] is given, it will be set after everything else.
-- If given, the key ["Parent"] is wiped from props (except when CreateMissing returns the existing Instance); this is the only change ever made to the props table. If a frozen props table contains ["Parent"] = error! If one of the properties throws an error, the Instance stays unparented (and key ["Parent"] is wiped by then);
-- Any property may be a CoffeeBaseValue: the property follows its .Changed until the CoffeeBaseValue or the Instance is destroyed (a CoffeeFolder destroys the children it removes).
-- props may be a CoffeeFolder, and any value in props may be a CoffeeFolder too (nested CoffeeFolders inside a CoffeeFolder included): every CoffeeFolder's children are applied like more props, and children added later get applied as well. If several bind the same property, the last one applied wins.
-- A CoffeeFolder passed as props never gets its ["Parent"] wiped. CoffeeObjects can't store Instances, so ["Parent"] and children can't come from a CoffeeFolder; parent the Instance yourself (e.g. Create(className)(folder).Parent = parent).
-- ---
-- CreateMissing(existingInstance?) -> Create
-- If existingInstance exists and its .ClassName matches the className you input, props are ignored and the existingInstance is returned. Otherwise, it is the same as calling Create;
function CreateInstance.Unpack(
	self: CreateInstance
): (Create, CreateMissing)
	return Create :: Create,
		CreateMissing :: CreateMissing
end

table.freeze(CreateInstance)
export type CreateInstance = typeof(CreateInstance)
return CreateInstance