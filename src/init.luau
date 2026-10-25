--[[--
    CreateInstanceReaction V0.1.0
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
const Reaction = require(`./Reaction`)
const O, ifV = Reaction.O, Reaction.ifV

type ClassNames = ClassNameTypePairs.ClassNameTypePairs
type ClassName = keyof<ClassNames>

type Create = <ClassNameGeneric>(ClassNameGeneric | ClassName | "") -> (
	(Properties<index<ClassNames, ClassNameGeneric>>) -> index<ClassNames, ClassNameGeneric>
)
type CreateMissing = (Instance?) -> Create
type Bindings = {[any]: Reaction.Ou} -- property name -> unsee



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

			-- Assign only writable properties, as T or Reaction.V<T> = (T?) -> T
			properties:setproperty(i, types.optional(types.unionof(
				v.write,
				types.newfunction({ head = { types.optional(v.write) } }, { head = { v.write } })
			)))
		end

		instance = instance:readparent()
	end

	properties:setindexer(types.number, types.any)

	return properties
end



-- The first applyProps call of an Instance creates its Bindings and the Destroying cleanup
const function ensureBindings(instance: Instance, bindings: Bindings?): Bindings
	if bindings then
		return bindings
	end

	const new: Bindings = {}
	instance.Destroying:Once(function()
		for _, unsee in new do
			unsee()
		end
		table.clear(new)
	end)
	return new
end

-- Binds instance[key] to the Reaction V, replacing an earlier binding of the same key
const function bind(instance: Instance, bindings: Bindings, key: any, value: Reaction.V<any>)
	const prev = bindings[key]
	if prev then
		prev()
	end

	local unsee: Reaction.Ou
	unsee = O(value, function(newValue, isDestroyed)
		if isDestroyed then
			unsee()
			if bindings[key] == unsee then
				bindings[key] = nil
			end
			return
		end
		(instance :: any)[key] = newValue
	end)
	bindings[key] = unsee

	;(instance :: any)[key] = value()
end



const function Create<ClassNameGeneric>(className: ClassNameGeneric | ClassName | "")
	const instance = Instance.new(className)
	local bindings: Bindings -- set on the first applyProps call

	const function applyProps(props: {[any]: any})
		if type(props) ~= `table` then
			return instance
		end
		bindings = ensureBindings(instance, bindings)

		const parent = props[`Parent`]
		if type(parent) ~= `nil` then
			props[`Parent`] = nil -- ignore in the loop
		end

		for k, v in props do
			if typeof(v) == `Instance` and type(k) == `number` then
				v.Parent = instance
				continue
			end
			if type(v) == `function` and ifV(v) then
				bind(instance, bindings, k, v)
				continue
			end

			(instance :: any)[k] = v
		end

		if type(parent) ~= `nil` then
			if type(parent) == `function` and ifV(parent) then
				bind(instance, bindings, `Parent`, parent)
			else
				instance.Parent = parent -- a wrong type errors here, like any other property
			end
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
		local bindings: Bindings-- set on the first applyProps call

		const function applyProps(props: {[any]: any})
			if isValid then
				return instance
			end

			if type(props) ~= `table` then
				return instance
			end
			bindings = ensureBindings(instance, bindings)

			const parent = props[`Parent`]
			if type(parent) ~= `nil` then
				props[`Parent`] = nil -- ignore in the loop
			end

			for k, v in props do
				if typeof(v) == `Instance` and type(k) == `number` then
					v.Parent = instance
					continue
				end
				if type(v) == `function` and ifV(v) then
					bind(instance, bindings, k, v)
					continue
				end

				(instance :: any)[k] = v
			end

			if type(parent) ~= `nil` then
				if type(parent) == `function` and ifV(parent) then
					bind(instance, bindings, `Parent`, parent)
				else
					instance.Parent = parent -- a wrong type errors here, like any other property
				end
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
-- Any property (["Parent"] included) may be a Reaction V (or a Reaction C, it returns a V): the property follows the V until the Instance fires Destroying or the V is removed with rmV. An Instance dropped without :Destroy() stays in memory as long as a V it is bound to does.
-- Don't use Create inside of Reaction.C, because this will create new Instances on every recompute that involves the use of Create.
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