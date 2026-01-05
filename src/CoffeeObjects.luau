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
    Module Version: 2.0.0
--]]--



--- Dependencies (Not By @Coffilhg) ---

-- Signal's Source Repository: https://github.com/stravant/goodsignal/blob/master/README.md --
local Signal = require(script.GoodSignal_By_Stravant) -- or wherever it's located and whatever it's named

--- /E Dependencies (Not By @Coffilhg) ---



local module = {}

-- Types for internal use and exports
export type SupportedTypesList = string | number | boolean |
BrickColor | CFrame | Color3 |
ColorSequence | Content | EnumItem |
Font | NumberRange | NumberSequence |
Ray | Rect | UDim | UDim2 | Vector2 | Vector3

export type CoffeeBaseValue = {
	Value: SupportedTypesList,
	Changed: Signal.Signal,
	Destroying: Signal.Signal, -- Fired before destruction
	Destroy: (self: CoffeeBaseValue) -> (),
	GetPath: (self: CoffeeBaseValue) -> {string},
	_Value: SupportedTypesList,
	_parent: CoffeeFolder?,
	_key: string?
}

export type CoffeeFolder = {
	ChildAdded: Signal.Signal,
	ChildRemoved: Signal.Signal,
	Destroying: Signal.Signal, -- Fired before destruction
	Insert: (self: CoffeeFolder, newValue: CoffeeBaseValue | CoffeeFolder | SupportedTypesList | PrimitiveTable) -> (),
	GetPath: (self: CoffeeFolder) -> {string},
	GetChildren: (self: CoffeeFolder) -> {[string | number]: CoffeeFolder | CoffeeBaseValue},
	Destroy: (self: CoffeeFolder) -> (),
	_IsArrayORTuple: (self: CoffeeFolder) -> boolean,
	_data: {[string | number]: CoffeeFolder | CoffeeBaseValue},
	_parent: CoffeeFolder?,
	_key: string?,
	[string | number]: any 
}

export type PrimitiveTable = {
	[string | number]: CoffeeBaseValue | CoffeeFolder | SupportedTypesList | PrimitiveTable,
}

--- GetPathMethod REQUIRED by CoffeeBaseValue AND CoffeeFolder ---

-- Traverses up the hierarchy via _parent references to reconstruct the object's location.
-- @return An array of keys (strings or numbers) representing the path from the root.
local function GetPathMethod(self: CoffeeBaseValue | CoffeeFolder) : {[number]: string | number}
	local path = {}
	local current = self
	local parent = rawget(current, "_parent")

	while parent do
		table.insert(path, 1, rawget(current, "_key")) -- I thought using reverse in the end, but reverse doesnt exist, so doing this is ok
		current = parent
		parent = rawget(current, "_parent")
	end

	return path
end
--- Methods REQUIRED by CoffeeFolder ---

-- Determines if the folder contains sequential numeric keys (behaving like an array/tuple).
-- Returns true if it is an array/tuple, or false if it is a dictionary.
-- @return boolean.
local function IsArrayORTupleMethod(self : CoffeeFolder) : boolean
	if #self == 0 then
		for k, v in self do
			return false -- default nil (falsy) ~ Not an array or a tuple
		end
	end
	return true
end

-- Appends a new value to the end of the folder, provided the folder is an array/tuple.
-- Automatically wraps raw tables into CoffeeFolders and primitives into CoffeeBaseValues.
-- @param newValue The value to be wrapped and inserted.
local function InsertMethod(self : CoffeeFolder, newValue : CoffeeBaseValue | CoffeeFolder | SupportedTypesList | PrimitiveTable)
	if not self:_IsArrayORTuple() then
		warn("Can't :Insert to a Dictionary!")
		return
	end

	local index = #self + 1

	self[index] = newValue
end

-- Returns the internal data table containing all children.
-- @return A dictionary of keys to CoffeeBaseValues or CoffeeFolders.
local function GetChildrenMethod(self : CoffeeFolder) : {[string | number]: CoffeeFolder | CoffeeBaseValue}
	return self._data
end

-- Destroys the Folder and all of its children recursively.
-- Disconnects all internal signals.
local function DestroyMethod(self : CoffeeFolder)
	self.Destroying:Fire()
	self.Destroying:DisconnectAll()
	
	self.ChildAdded:DisconnectAll()
	self.ChildRemoved:DisconnectAll()
	
	for _, item in pairs(self._data) do
		if item.Destroy then item:Destroy() end
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

local supportedTypes = {
	string = true, number = true, boolean = true,
	BrickColor = true, CFrame = true, Color3 = true,
	ColorSequence = true, Content = true, EnumItem = true,
	Font = true, NumberRange = true, NumberSequence = true,
	Ray = true, Rect = true, UDim = true, UDim2 = true, Vector2 = true, Vector3 = true,
}
local supportedTypesArray = {}
local supportedTypesTemp = {}
for key, _ in pairs(supportedTypes) do
	table.insert(supportedTypesTemp, key)
	local tempConcat = table.concat(supportedTypesTemp, ", ")
	if #tempConcat >= 36 then
		table.insert(supportedTypesArray, tempConcat)
		supportedTypesTemp = {}
	end
end
local supportedTypesDebugMessage = table.concat(supportedTypesArray, ",\n>\t")
supportedTypesArray = nil
supportedTypesTemp = nil



local Value = {}

-- Creates a new Value instance with a default value, mimicking Roblox BaseValue instances (Limited To Supported Types; Supports Some, That BaseValues Don't).
-- @param defaultValue The initial value for the Value instance. Must be one of SupportedTypesList.
-- @return A Value instance with properties Value, Changed, and Destroy.
function Value.new(defaultValue : SupportedTypesList) : CoffeeBaseValue
	assert(supportedTypes[typeof(defaultValue)], `\n>\tCoffeeBaseValue Does Not Support typeof: "{typeof(defaultValue)}";\n>\tAll supported Types:\n>\t{supportedTypesDebugMessage};`)

	local self = setmetatable({}, Value)
	self._Value = defaultValue
	self.Changed = Signal.new()
	self.Destroying = Signal.new()
	rawset(self, "GetPath", GetPathMethod)

	return self
end

-- Handles assignment to the Value instance, enforcing type validation for the Value property.
-- Fires the Changed signal when the Value property is updated.
-- @param key The key being assigned to (e.g., "Value").
-- @param newValue The new value to assign. For "Value", must be one of SupportedTypesList.
function Value:__newindex(key, newValue)
	if key == "Value" then
		assert(supportedTypes[typeof(newValue)], `\n>\tCoffeeBaseValue Does Not Support typeof: "{typeof(newValue)}";\n>\tAll supported Types:\n>\t{supportedTypesDebugMessage};`)

		local previousValue = self._Value
		self._Value = newValue
		self.Changed:Fire(previousValue, newValue)
	else
		rawset(self, key, newValue)
	end
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
	self.Destroying:Fire()
	self.Destroying:DisconnectAll()
	self.Changed:DisconnectAll()
	setmetatable(self, nil)
end

-- Creates a new Value instance with a default value, mimicking Roblox BaseValue instances.
-- @param defaultValue The initial value for the Value instance. Must be one of SupportedTypesList.
-- @return A Value instance with properties Value, Changed, and Destroy.
function CoffeeBaseValue.new(defaultValue : SupportedTypesList)
	return Value.new(defaultValue)
end

-- Validates whether a given object is a valid Value instance.
-- @param v The object to validate.
-- @return True if the object is a Value instance, false otherwise.
function CoffeeBaseValue.validateClass(v)
	return getmetatable(v) == Value
end

function CoffeeBaseValue.validateUnlinkedClass(v)
	return type(v) == "table"
		and	v["_Value"] ~= nil
		and	v["Changed"] ~= nil
		and v["Destroying"] ~= nil
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
-- is intended behavior in the V2.0.0, unlike the V1.0.0.

-- Handles the assignment of new children to the Folder.
-- Automatically wraps raw tables in CoffeeFolders and supported primitives in CoffeeBaseValues.
-- @param key The key/index for the new child.
-- @param newValue The value to store. If nil, the child is removed and destroyed.
function Folder:__newindex(key : string | number, newValue : CoffeeBaseValue | CoffeeFolder | SupportedTypesList | PrimitiveTable)
	--print("new index inside", self)
	--print("kv:", key, newValue)
	local data = rawget(self, "_data")

	local oldItem = rawget(data, key)

	if oldItem then
		if newValue == nil then
			rawset(data, key, nil)
			self.ChildRemoved:Fire(key)
			
			if oldItem["Destroy"] then oldItem:Destroy() end

			return -- same as return nil
		else
			if oldItem["Destroy"] then oldItem:Destroy() end
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
	if itemToStore["Destroying"] then
		itemToStore["Destroying"]:Connect(function()
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
function Folder:__index(key : string | number)
	return rawget(self._data, key)
end

-- Allows the folder to be used in generic 'for' loops (e.g.: for key, child in folder do ... end).
function Folder:__iter()
	return next, rawget(self, "_data")
end

-- Returns the count of children if the folder is an array.
-- Note: This will return 0 for dictionary-like folders.
function Folder:__len()
	return #rawget(self, "_data")
end


-- Creates a new CoffeeFolder instance, mimicking a Roblox Folder Instance.
-- @param data Optional initial table to populate the folder with.
-- @return A CoffeeFolder instance with ChildAdded, ChildRemoved, and tree-traversal methods.
function CoffeeFolder.new(data) : CoffeeFolder
	local self = setmetatable({}, Folder)
	rawset(self, "_data", {})
	rawset(self, "ChildAdded", Signal.new())
	rawset(self, "ChildRemoved", Signal.new())
	rawset(self, "Destroying", Signal.new())
	rawset(self, "_IsArrayORTuple", IsArrayORTupleMethod)
	rawset(self, "Insert", InsertMethod)
	rawset(self, "GetPath", GetPathMethod)
	rawset(self, "GetChildren", GetChildrenMethod)
	rawset(self, "Destroy", DestroyMethod)

	if not data or type(data) ~= "table" then
		return self
	end

	--print("Adding", data, "into a coffeefolder")
	for k, v in pairs(data) do
		self[k] = v -- newindex will handle this
	end

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
		and	v["_data"] ~= nil
		and	v["ChildAdded"] ~= nil
		and	v["ChildRemoved"] ~= nil
		and v["Destroying"] ~= nil
end

return module