--[[--
?? 	CoffeeBaseValue | V1 (15/10/2025)
?? 	@Coffilhg
	Replicates Roblox BaseValue behavior for supported types.
	Somewhat Accurate: You only get .Value and .Changed;
	
	.Changed Example:
		-- Create a Color3 Value
		local MyValue = CoffeeBaseValue.new(Color3.fromRGB(255, 255, 255))
		-- Connect the Event
		local MyValueConnection = MyValue.Changed:Connect(function(oldValue, newValue)
			print("MyValue Changed from", oldValue, "to", newValue)
		end)
		-- Change the Value to make event Fire
		MyValue.Value = Color3.fromRGB(21, 21, 21)
		-- Disconnect
		MyValueConnection:Disconnect()
--]]--

type SupportedTypesList = string | number | boolean |
BrickColor | CFrame | Color3 |
ColorSequence | Content | EnumItem |
Font | NumberRange | NumberSequence |
Ray | Rect | UDim | UDim2 | Vector2 | Vector3

--- For Validation O(1) ---
local supportedTypes = {
	string = true, number = true, boolean = true,
	BrickColor = true, CFrame = true, Color3 = true,
	ColorSequence = true, Content = true, EnumItem = true,
	Font = true, NumberRange = true, NumberSequence = true,
	Ray = true, Rect = true, UDim = true, UDim2 = true, Vector2 = true, Vector3 = true,
}
--- For Debug Messages ---
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



--- Main ---
local CoffeeBaseValue = {}

--- Replicate The Way BaseValue Instances Work  ---




-- Creates a signal object for handling event callbacks, similar to Roblox's RBXScriptSignal.
-- @return A signal object with Connect, _Fire, and DisconnectAll methods.
local function createSignal()
	local signal = { _callbacks = {}, _total = 0 }

	-- Connects a callback function to the signal, which will be called when the signal is fired.
	-- @param callback The function to call when the signal is fired. Must be a function.
	-- @return A connection object with a Disconnect method to remove the callback.
	function signal:Connect(callback)
		assert(type(callback) == "function", "Callback must be a function")
		
		self._total += 1
		local index = tostring(self._total)
		self._callbacks[index] = callback
		
		local returnTable = {}
		function returnTable:Disconnect()
			self._callbacks[index] = nil
		end
		return returnTable
	end
	
	-- Fires the signal, calling all connected callbacks with the provided arguments.
	-- @param ... Arguments to pass to each connected callback.
	function signal:_Fire(...)
		for _, callback in pairs(self._callbacks) do
			callback(...)
		end
	end
	
	-- Disconnects all callbacks from the signal, clearing the callback list.
	function signal:DisconnectAll()
		self._callbacks = {}
		self._total = 0
	end

	return signal
end



local Value = {}
Value.__index = Value

-- Creates a new Value instance with a default value, mimicking Roblox BaseValue instances (Limited To Supported Types; Supports Some, That BaseValues Don't).
-- @param defaultValue The initial value for the Value instance. Must be one of SupportedTypesList.
-- @return A Value instance with properties Value, Changed, and Destroy.
function Value.new(defaultValue : SupportedTypesList) : {
		["Value"]: SupportedTypesList,
		["Changed"]: typeof(createSignal()),
		["Destroy"]: () -> (),
	}
	assert(supportedTypes[typeof(defaultValue)], `\n>\tCoffeeBaseValue Does Not Support typeof: "{typeof(defaultValue)}";\n>\tAll supported Types:\n>\t{supportedTypesDebugMessage};`)
	
	local self = setmetatable({}, Value)
	self._Value = defaultValue
	self.Changed = createSignal()
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
		self.Changed:_Fire(previousValue, newValue)
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
function CoffeeBaseValue.validateValueClass(v)
	return getmetatable(v) == Value
end
function CoffeeBaseValue.validateUnlinkedValueClass(v)
	return type(v) == "table"
		and	v["_Value"] ~= nil
		and	v["Changed"] ~= nil
end

return CoffeeBaseValue