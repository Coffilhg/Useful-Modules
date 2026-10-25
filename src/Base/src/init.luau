--[[--
    CreateInstance V0.1.0
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

type ClassNames = ClassNameTypePairs.ClassNameTypePairs
type ClassName = keyof<ClassNames>

type Create = <ClassNameGeneric>(ClassNameGeneric | ClassName | "") -> (
	(Properties<index<ClassNames, ClassNameGeneric>>) -> index<ClassNames, ClassNameGeneric>
)
type CreateMissing = (Instance?) -> Create



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

			-- Assign only writable properties
			properties:setproperty(i, types.optional(v.write))
		end

		instance = instance:readparent()
	end

	properties:setindexer(types.number, types.any)

	return properties
end



const function Create<ClassNameGeneric>(className: ClassNameGeneric | ClassName | "")
	const instance = Instance.new(className)

	const function applyProps(props: {[any]: any})
		if type(props) ~= `table` then
			return instance
		end
		
		const parent = props[`Parent`]
		if type(parent) ~= `nil` then
			props[`Parent`] = nil -- ignore in the loop
		end

		for k, v in props do
			if typeof(v) == `Instance` and type(k) == `number` then
				v.Parent = instance
				continue
			end

			(instance :: any)[k] = v
		end

		if type(parent) ~= `nil` then
			instance.Parent = parent -- a wrong type errors here, like any other property
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

		const function applyProps(props: {[any]: any})
			if isValid then
				return instance
			end

			if type(props) ~= `table` then
				return instance
			end

			const parent = props[`Parent`]
			if type(parent) ~= `nil` then
				props[`Parent`] = nil -- ignore in the loop
			end

			for k, v in props do
				if typeof(v) == `Instance` and type(k) == `number` then
					v.Parent = instance
					continue
				end

				(instance :: any)[k] = v
			end

			if type(parent) ~= `nil` then
				instance.Parent = parent -- a wrong type errors here, like any other property
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