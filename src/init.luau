--[[--
    Quick Start and API can be found at
    https://github.com/Coffilhg/Useful-Modules/tree/CoffeeObjects

    CoffeeObjects (CoffeeFolder & CoffeeBaseValue)
    Copyright © 2025 Coffilhg (Roblox UserId 517222346)
    
    

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    Full License & Notices: https://github.com/Coffilhg/Useful-Modules/tree/CoffeeObjects
    Module Version: 2.3.5
--]]--
--!optimize 2

--- Dependencies ---

-- Signal Source Repository: https://github.com/Data-Oriented-House/LemonSignal
local LemonSignal = require(script.Parent.LemonSignal) -- or wherever it's located and whatever it's named
-- CoffeeParser Source Repository: https://github.com/Coffilhg/Useful-Modules/tree/CoffeeParser
local CoffeeParser = require(script.Parent.CoffeeParser) -- or wherever it's located and whatever it's named

--- /E Dependencies ---



local module = {}

-- Types for internal use and exports
export type SupportedTypesList = CoffeeParser.SupportedTypesList

export type TableIndex = CoffeeParser.TableIndex --string | number
export type TableValue = CoffeeBaseValue | CoffeeFolder | CoffeeBaseValueStrict<SupportedTypesList> | CoffeeFolderStrict<PrimitiveTable> | SupportedTypesList | PrimitiveTable
export type PrimitiveTable = {[TableIndex]: TableValue}

export type CoffeeFolder = {
	ChildAdded: LemonSignal.Signal<TableIndex, CoffeeBaseValue | CoffeeFolder>, -- fires with the key and item that were added
	ChildRemoved: LemonSignal.Signal<TableIndex>, -- fires with the key that was destroyed
	Destroying: LemonSignal.Signal<>, -- Fired before destruction
	-- _Destroying: PerfectSignal.Signal<>, -- Fired before destruction, right before Destroying fires.
	Insert: (self: CoffeeFolder, newValue: TableValue) -> (),
	GetPath: (self: CoffeeFolder) -> {string},
	GetChildren: (self: CoffeeFolder) -> {[TableIndex]: CoffeeFolder | CoffeeBaseValue},
	Destroy: (self: CoffeeFolder) -> (),
	-- _IsArrayORTuple: (self: CoffeeFolder) -> boolean,
	-- _data: {[TableIndex]: CoffeeFolder | CoffeeBaseValue},
	-- _parent: CoffeeFolder?,
	-- _key: string?,
	[TableIndex]: any,
}

export type CoffeeFolderStrict<T> = { -- T must be {[TableIndex]: CoffeeFolder | CoffeeBaseValue}
	ChildAdded: LemonSignal.Signal<TableIndex, CoffeeBaseValue | CoffeeFolder>, -- fires with the key and item that were added
	ChildRemoved: LemonSignal.Signal<TableIndex>, -- fires with the key that was destroyed
	Destroying: LemonSignal.Signal<>, -- Fired before destruction
	-- _Destroying: PerfectSignal.Signal<>, -- Fired before destruction, right before Destroying fires.
	Insert: (self: CoffeeFolderStrict<T>, newValue: TableValue) -> (),
	GetPath: (self: CoffeeFolderStrict<T>) -> {string},
	GetChildren: (self: CoffeeFolderStrict<T>) -> T,
	Destroy: (self: CoffeeFolderStrict<T>) -> (),
	-- _IsArrayORTuple: (self: CoffeeFolderStrict<T>) -> boolean,
	-- _data: T,
	-- _parent: CoffeeFolder?,
	-- _key: string?,
} & T -- Perfect for autocomplete because index leads to internal _data, which is T

export type CoffeeFolderInternals<T> = {
	_Destroying: LemonSignal.Signal<>, -- Fired before destruction, right before Destroying fires.
	_IsArrayORTuple: (self: any) -> boolean, -- any here is actually the CoffeeFolder
	_data: T,
	_parent: CoffeeFolder?,
	_key: TableIndex?,
}

export type CoffeeBaseValue = {
	Value: SupportedTypesList,
	Changed: LemonSignal.Signal<SupportedTypesList, SupportedTypesList>, -- fires with previousValue and newValue
	Destroying: LemonSignal.Signal<>, -- Fired before destruction
	-- _Destroying: PerfectSignal.Signal<>, -- Fired before destruction, right before Destroying fires.
	Destroy: (self: CoffeeBaseValue) -> (),
	GetPath: (self: CoffeeBaseValue) -> {TableIndex},
	-- _Value: SupportedTypesList,
	-- _parent: CoffeeFolder?,
	-- _key: string?,
}

export type CoffeeBaseValueStrict<T> = { -- T is ONE of the types from SupportedTypesList
	Value: T,
	Changed: LemonSignal.Signal<T, T>, -- fires with previousValue and newValue
	Destroying: LemonSignal.Signal<>, -- Fired before destruction
	-- _Destroying: PerfectSignal.Signal<>, -- Fired before destruction, right before Destroying fires.
	Destroy: (self: CoffeeBaseValueStrict<T>) -> (),
	GetPath: (self: CoffeeBaseValueStrict<T>) -> {TableIndex},
	-- _Value: T,
	-- _parent: CoffeeFolder?,
	-- _key: string?,
}

export type CoffeeBaseValueInternals<T> = {
	_Destroying: LemonSignal.Signal<>,
	_Value: T,
	_parent: CoffeeFolder?,
	_key: TableIndex?,
}

--- GetPathMethod REQUIRED by CoffeeBaseValue AND CoffeeFolder ---

-- Traverses up the hierarchy via _parent references to reconstruct the object's location.
-- @return An array of keys (strings or numbers) representing the path from the root.
local function GetPathMethod(self: CoffeeBaseValue | CoffeeFolder) : {[number]: TableIndex}
	local path : {TableIndex} = {}
	local current = self
	local parent = rawget(current, "_parent")

	-- after this loop is complete, path is actually backwards from what is expected
	while parent do
		-- the _key will only be nil if it's the root, but since the root does
		-- not have a _parent, the loop stops and root' _key (nil) is not read
		table.insert(path, rawget(current, "_key") :: TableIndex) -- O(1) instead of table.insert(path, 1, rawget(current, "_key") :: TableIndex) O(n)

		current = parent
		parent = rawget(current, "_parent")
	end

	-- reverse
	local length = #path
	for i = 1, math.floor(length/2) do
		local j = length - i + 1
		path[i], path[j] = path[j], path[i]
	end

	return path
end
--- Methods REQUIRED by CoffeeFolder ---

-- Determines if the folder contains sequential numeric keys (behaving like an array/tuple).
-- Returns true if it is an array/tuple, or false if it is a dictionary.
-- @return boolean.
local function IsArrayORTupleMethod(self : CoffeeFolder) : boolean
	if #self == 0 then
		-- if a table is really empty, next will return nil
		return next(self._data) == nil -- Not an array or a tuple
	end
	return true
end

-- Appends a new value to the end of the folder, provided the folder is an array/tuple.
-- Automatically wraps raw tables into CoffeeFolders and primitives into CoffeeBaseValues.
-- @param newValue The value to be wrapped and inserted.
local function InsertMethod(self : CoffeeFolder, newValue : TableValue)
	if not self:_IsArrayORTuple() then
		warn("Can't :Insert to a Dictionary!")
		return
	end

	local index = #self + 1

	self[index] = newValue
end

-- Returns the internal data table containing all children.
-- @return A dictionary of keys to CoffeeBaseValues or CoffeeFolders.
local function GetChildrenMethod(self : CoffeeFolder) : {[TableIndex]: CoffeeFolder | CoffeeBaseValue}
	return self._data
end

-- Destroys the Folder and all of its children recursively.
-- Disconnects all internal signals.
local function DestroyMethod(self : CoffeeFolder)
	self._Destroying:Fire()
	self.Destroying:Fire()

	self._Destroying:DisconnectAll()
	self.Destroying:DisconnectAll()

	self.ChildAdded:DisconnectAll()
	self.ChildRemoved:DisconnectAll()

	for _, item in self._data do
		local destroy = item["Destroy"]
		if destroy then
			destroy(
				item -- self
			)
		end
	end

	rawset(self, "_data", nil)
	rawset(self, "_parent", nil)
	rawset(self, "_key", nil)

	setmetatable(self, nil)
end

--- /E Methods REQUIRED by CoffeeFolder ---










--- CoffeeBaseValue REQUIRES Signal AND GetPathMethod ---
local CoffeeBaseValue = {}
module.CoffeeBaseValue = CoffeeBaseValue

--- Replicate The Way BaseValue Instances Work (Somewhat Accurate) ---

local SupportedTypes = CoffeeParser.SupportedTypes



local Value = {}

-- Handles assignment to the Value instance, enforcing type validation for the Value property.
-- Fires the Changed signal when the Value property is updated.
-- @param key The key being assigned to (e.g., "Value").
-- @param newValue The new value to assign. For "Value", must be one of SupportedTypesList.
function Value:__newindex(key, newValue)
	if key == "Value" then
		local typeofNewValue = typeof(newValue)
		if not SupportedTypes[newValue] then
			error(`\n>\tCoffeeBaseValue Does Not Support typeof: "{typeofNewValue}";\n>\tAll supported Types:{CoffeeParser.SupportedTypesDebugMessage};`)
		end

		local previousValue = self._Value
		self._Value = newValue
		self.Changed:Fire(previousValue, newValue)

		return
	end

	rawset(self, key, newValue)
end

-- Retrieves the value of a key from the Value instance, returning the stored value for the Value property.
-- @param key The key to access (e.g., "Value").
-- @return The value associated with the key, or the stored _Value for "Value".
function Value:__index(key)
	if key == "Value" then
		return self._Value
	end
	return rawget(Value, key)
end

-- Returns a string representation of the Value instance in the format "type: value".
-- Auto fired when doing print(Value)
-- @return A string describing the type and value of the instance.
function Value:__tostring()
	return `{typeof(self._Value)}: {self._Value}`
end

-- Destroys the Value instance, disconnecting all Changed signal callbacks and clearing the metatable.
function Value:Destroy()
	self._Destroying:Fire()
	self.Destroying:Fire()

	self._Destroying:DisconnectAll()
	self.Destroying:DisconnectAll()
	self.Changed:DisconnectAll()

	rawset(self, "_parent", nil)
	rawset(self, "_key", nil)

	setmetatable(self, nil)
end

-- Creates a new Value instance with a default value, mimicking Roblox BaseValue instances. (Limited To Supported Types; Supports some types, that BaseValues don't).
-- @param defaultValue The initial value for the Value instance. Must be one of SupportedTypesList.
-- @return A Value instance with properties Value, Changed, and Destroy.
function CoffeeBaseValue.new(defaultValue : SupportedTypesList) : CoffeeBaseValue
	local typeofDefaultValue = typeof(defaultValue)
	if not SupportedTypes[typeofDefaultValue] then
		error(`\n>\tCoffeeBaseValue Does Not Support typeof: "{typeofDefaultValue}";\n>\tAll supported Types:{CoffeeParser.SupportedTypesDebugMessage};`)
	end

	local self = setmetatable({}, Value)
	rawset(self, "_Value", defaultValue)
	rawset(self, "Changed", LemonSignal.new())
	rawset(self, "Destroying", LemonSignal.new())
	rawset(self, "_Destroying", LemonSignal.new())
	rawset(self, "GetPath", GetPathMethod)

	return self
end

-- Does the same as CoffeeBaseValue.new;
-- The type of the initial defaultValue value will now follow in autocomplete for this CoffeeBaseValue.
-- You can still do CoffeeBaseValue.Value = a type different from the default, but at this point just use non-strict.
-- @param defaultValue The initial value for the Value instance. Must be one of SupportedTypesList (T is inferred from it).
-- @return A CoffeeBaseValueStrict<T> (Value) instance with typed Value property.
function CoffeeBaseValue.strictNew<T>(defaultValue : T & SupportedTypesList) : CoffeeBaseValueStrict<T>
	local self = CoffeeBaseValue.new(defaultValue) :: CoffeeBaseValueStrict<T>
	return self
end

-- Validates whether a given object is a valid Value instance.
-- @param v The object to validate.
-- @return True if the object is a Value instance, false otherwise.
function CoffeeBaseValue.validateClass(v)
	return getmetatable(v) == Value
end

function CoffeeBaseValue.validateUnlinkedClass(v)
	-- rawget is used to avoid triggering Folder:__index when
	-- doing CoffeeBaseValue.validateUnlinkedClass(CoffeeFolder)
	return type(v) == "table"
		and	rawget(v, "_Value") ~= nil
		and	rawget(v, "Changed") ~= nil
		and rawget(v, "Destroying") ~= nil
end









--- CoffeeFolder REQUIRES Signal AND GetPathMethod AND CoffeeBaseValue AND InsertMethod ---
local CoffeeFolder = {}
module.CoffeeFolder = CoffeeFolder

--- Replicate The Way Folder Instances Work (Somewhat Accurate) ---

local Folder = {}

-- Intercepts assignment to the Folder. 
-- Handles child removal (if nil), wrapping raw data into CoffeeObjects, and parent-linking.
-- Fires ChildAdded or ChildRemoved signals accordingly.
-- Overwriting an existing key/index ALWAYS fires ChildRemoved and then ChildAdded, this
-- is intended behavior in the V2+, unlike the V1.

-- Handles the assignment of new children to the Folder.
-- Automatically wraps raw tables in CoffeeFolders and supported primitives in CoffeeBaseValues.
-- @param key The key/index for the new child.
-- @param newValue The value to store. If nil, the child is removed and destroyed.
function Folder:__newindex(key : TableIndex, newValue : TableValue)
	--print("new index inside", self)
	--print("kv:", key, newValue)
	local data = rawget(self, "_data")

	local oldItem = rawget(data, key)

	if oldItem then
		if newValue == nil then
			rawset(data, key, nil)
			self.ChildRemoved:Fire(key)

			local destroy = oldItem["Destroy"]
			if destroy then
				destroy(
					oldItem -- self
				)
			end

			return -- same as return nil
		else
			local destroy = oldItem["Destroy"]
			if destroy then
				destroy(
					oldItem -- self
				)
			end
		end
	end



	local itemToStore

	if type(newValue) == "table" then
		if CoffeeBaseValue.validateClass(newValue) or CoffeeBaseValue.validateUnlinkedClass(newValue)
			or CoffeeFolder.validateClass(newValue) or CoffeeFolder.validateUnlinkedClass(newValue)	
		then
			--print("A CoffeeBaseValue OR CoffeeFolder")
			itemToStore = newValue -- already a CoffeeObject
		else
			--print("A table, not a CoffeeObject")
			itemToStore = CoffeeFolder.new(newValue)
		end
	else
		--print("Hopefully one of the Supported Types")
		itemToStore = CoffeeBaseValue.new(newValue)
	end

	rawset(itemToStore, "_parent", self)

	rawset(itemToStore, "_key", key)

	-- Listen for child self-destruction
	if itemToStore["_Destroying"] then
		itemToStore["_Destroying"]:Connect(function()
			local destroyedItem = rawget(data, key)

			if data and destroyedItem == itemToStore then
				rawset(data, key, nil)
				self.ChildRemoved:Fire(key)
			end
		end)
	end

	rawset(data, key, itemToStore)
	self.ChildAdded:Fire(key, itemToStore)
end

-- Provides access to children stored in the internal _data table.
-- @param key The name or index of the child to retrieve.
-- @return The CoffeeBaseValue or CoffeeFolder associated with the key.
function Folder:__index(key : TableIndex)
	return rawget(self._data, key)
end

-- Allows the folder to be used in generic 'for' loops (e.g.: for key, child in folder do ... end).
function Folder:__iter()
	return next, rawget(self, "_data")
end

-- Returns the count of children if the folder is an array/tuple.
-- Works the same way as #, this metamethod is just a proxy.
-- Expect same quirks in behavior as with #table
function Folder:__len()
	local data = rawget(self, "_data")
	if not data then
		return 0
	end
	return #data
end


-- Creates a new CoffeeFolder instance, mimicking a Roblox Folder Instance.
-- @param data Optional initial table to populate the folder with.
-- @return A CoffeeFolder instance with ChildAdded, ChildRemoved, and tree-traversal methods.
function CoffeeFolder.new(data : ({} & PrimitiveTable)?) : CoffeeFolder
	local self = setmetatable({}, Folder)
	rawset(self, "_data", {})
	rawset(self, "ChildAdded", LemonSignal.new())
	rawset(self, "ChildRemoved", LemonSignal.new())
	rawset(self, "Destroying", LemonSignal.new())
	rawset(self, "_Destroying", LemonSignal.new())
	rawset(self, "_IsArrayORTuple", IsArrayORTupleMethod)
	rawset(self, "Insert", InsertMethod)
	rawset(self, "GetPath", GetPathMethod)
	rawset(self, "GetChildren", GetChildrenMethod)
	rawset(self, "Destroy", DestroyMethod)

	if type(data) ~= "table" then
		return self
	end

	--print("Adding", data, "into a coffeefolder")
	for k, v in data do
		self[k] = v -- newindex will handle this
	end

	return self
end

-- Creates a strictly-typed CoffeeFolder instance (for better autocomplete and type inference).
-- See examples at https://github.com/Coffilhg/Useful-Modules/blob/CoffeeObjects/src/Examples/StrictTypesAndObjects.luau
-- Behaves identically to CoffeeFolder.new, but the returned object's children are typed as T.
-- The structure of the initial data table will now follow in autocomplete for this CoffeeFolderStrict<T>.
-- @param data Optional initial table to populate the folder with (T is inferred from it).
-- @return A CoffeeFolderStrict<T> instance.
function CoffeeFolder.strictNew<T>(data : T & PrimitiveTable) : CoffeeFolderStrict<T>
	local self = CoffeeFolder.new(data) :: CoffeeFolderStrict<T>
	return self
end

-- Validates whether a given object is a valid CoffeeFolder instance.
-- @param v The object to validate.
-- @return True if the object is a CoffeeFolder instance, false otherwise.
function CoffeeFolder.validateClass(v)
	return getmetatable(v) == Folder
end

-- Validates whether a given table mimics the structure of a CoffeeFolder. (Useful when metatable is lost after a DeepCopy)
-- @param v The object to validate.
-- @return True if the object has the required internal Folder properties.
function CoffeeFolder.validateUnlinkedClass(v)
	return type(v) == "table"
		and	rawget(v, "_data") ~= nil
		and	rawget(v, "ChildAdded") ~= nil
		and	rawget(v, "ChildRemoved") ~= nil
		and rawget(v, "Destroying") ~= nil
end

return module