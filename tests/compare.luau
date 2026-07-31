-- Test script for CoffeeParser: Encode and Decode with all supported types
-- Run this in Roblox Studio console

local HttpService = game:GetService("HttpService")

local CoffeeParser = require(path.to.CoffeeParser)

-- Divider for the code and output
print(table.concat(table.create(1000, "\n"), ""))
print("Start execution")





const Tolerance : number = 1e-5
const Color3Tolerance : number = 1/255
local TypeofsWithFuzzyEqMethod = {
	["CFrame"] = true,
	["Vector2"] = true,
	["Vector3"] = true
}
local function CompareNumber(a: number, b: number, tolerance: number?)
	if type(tolerance) ~= "number" then
		tolerance = Tolerance
	end
	
	if a == b then
		-- just equal numbers (no difference)
		return true
	end
	if a ~= a and b ~= b then
		-- Both NaN (no difference)
		return true
	end

	return math.abs(a - b) < tolerance
end
local function CompareUserdata<T>(original: T, copy: T)
	local oTypeof = typeof(original)
	local cTypeof = typeof(copy)
	
	if oTypeof ~= cTypeof then
		return	false, {
			["!!!Reason"] = "typeof() Mismatch",
			["Details"] = {
				["Original Value"] = original,
				["Original Typeof"] = oTypeof,
				["Copy Value"] = copy,
				["Copy Typeof"] = cTypeof,
			},
		}
	end
	
	local isEqual = original == copy
	if isEqual then
		return true
	end
	
	if TypeofsWithFuzzyEqMethod[oTypeof] then
		isEqual = (original :: CFrame | Vector2 | Vector3):FuzzyEq(copy, Tolerance)
	elseif oTypeof == "Color3" then
		isEqual = CompareNumber(original.R, copy.R, Color3Tolerance) and
			CompareNumber(original.G, copy.G, Color3Tolerance) and
			CompareNumber(original.B, copy.B, Color3Tolerance)
	end
	
	if not isEqual then
		return false, {
			["!!!Reason"] = "Userdata Value Mismatch",
			["Details"] = {
				["Original Value"] = original,
				["Original Typeof"] = oTypeof,
				["Copy Value"] = copy,
				["Copy Typeof"] = cTypeof,
			},
		} 
	end
	
	return isEqual
end
local function DeepCompareBuffer(original: buffer, copy: buffer)
	if buffer.len(original) ~= buffer.len(copy) then return false end
	return buffer.tostring(original) == buffer.tostring(copy)
	--[[
	local oLen = buffer.len(original)
	local cLen = buffer.len(copy)

	local isEqual = oLen == cLen
	if not isEqual then
		return isEqual
	end

	local nextByteToRead = 0
	while nextByteToRead < oLen and isEqual do
		local remainingBytes = oLen - nextByteToRead

		local readOperation = buffer.readu8
		if remainingBytes >= 4 then
			readOperation = buffer.readu32
		elseif remainingBytes >= 2 then
			readOperation = buffer.readu16
		end

		isEqual = readOperation(original, nextByteToRead) == readOperation(copy, nextByteToRead)
		nextByteToRead += remainingBytes >= 4 and 4 or remainingBytes >= 2 and 2 or 1
	end

	return isEqual
	--]]
end
local function ReadBinary(readFromBuffer: buffer, startBit: number, endBit: number) : string
	if startBit == endBit then
		return tostring(buffer.readbits(readFromBuffer, startBit, 1))
	end
	if startBit > endBit then
		local initialEndBit = endBit
		endBit = startBit
		startBit = initialEndBit
	end

	local bits = {}
	for i = startBit, endBit do
		table.insert(bits, tostring(buffer.readbits(readFromBuffer, i, 1)))
	end

	return table.concat(bits, "")
end
-- Deep compare function with floating-point tolerance and Roblox datatype support
local function DeepCompare(original: {}, copy: {})
	local differentKeys = {}
	local isEqual = true
	
	for k, v in pairs(original) do
		
		local OvType = type(v)
		local Cv = copy[k]
		local CvType = type(Cv)
		
		if OvType ~= CvType then
			isEqual = false
			differentKeys[k] = {
				["!!!Reason"] = "type() Mismatch",
				["Details"] = {
					["Original Value"] = v,
					["Original Type"] = OvType,
					["Copy Value"] = Cv,
					["Copy Type"] = CvType,
				},
			}
			continue
		end
		
		
		
		if OvType == "table" then
			local isInnerEqual, innerDifferentKeys = DeepCompare(v, Cv)
			
			if not isInnerEqual then
				isEqual = false
				differentKeys[k] = {
					["!!!Reason"] = "DeepComparison detected differences in this inner table",
					["Details"] = innerDifferentKeys,
				}
			end
			
			continue
		end
		
		if OvType == "userdata" then
			local isUserdataEqual, differenceDetails = CompareUserdata(v, Cv)
			
			if not isUserdataEqual then
				isEqual = false
				differentKeys[k] = differenceDetails
			end
			
			continue
		end
		
		if OvType == "number" then
			local isNumberApproximatelyEqual = CompareNumber(v, Cv)
			
			if not isNumberApproximatelyEqual then
				isEqual = false
				differentKeys[k] = {
					["!!!Reason"] = "Numbers are different!",
					["Details"] = {
						["Original Value"] = v,
						["Original Type"] = OvType,
						["Copy Value"] = Cv,
						["Copy Type"] = CvType,
					},
				}
			end
			continue
		end
		
		if OvType == "buffer" then
			local isBufferEqual = DeepCompareBuffer(v, Cv)
			if not isBufferEqual then
				isEqual = false
				differentKeys[k] = {
					["!!!Reason"] = "Buffers are different!",
					["Details"] = {
						["Original Value"] = v,
						["Original Type"] = OvType,
						["Copy Value"] = Cv,
						["Copy Type"] = CvType,
						["buffer.tostring() (May not display)"] = {
							["Orig"] = buffer.tostring(v),
							["Copy"] = buffer.tostring(Cv :: buffer),
						},
						["Binary (May Be Very LONG)"] = {
							["Orig"] = ReadBinary(v, 0, buffer.len(v) * 8 - 1),
							["Copy"] = ReadBinary(Cv, 0, buffer.len(Cv :: buffer) * 8 - 1),
						},
					},
				}
			end
			
			continue
		end
		
		-- remaining types (string and boolean)
		
		if v ~= Cv then
			isEqual = false
			differentKeys[k] = {
				["!!!Reason"] = "Different Values of a type: "..OvType,
				["Details"] = {
					["Original Value"] = v,
					["Original Type"] = OvType,
					["Copy Value"] = Cv,
					["Copy Type"] = CvType,
				},
			}
		end
	end
	
	return isEqual, differentKeys
end

-- Test table with all supported types, including edge cases
local testData = {
	-- Primitives
	emptyBuffer = buffer.create(3),
	meaningfulBuffer = buffer.writeu8(buffer.create(1), 0, 164),
	stringNormal = "hello world",
	stringEmpty = "",
	stringSpecial = "special: _C-Vector3(1|2|3)",  -- Test potential conflicts
	numberZero = 0,
	numberPositive = 42,
	numberNegative = -42,
	numberFloat = 3.14159,
	numberHuge = math.huge,
	numberNegHuge = -math.huge,
	numberNaN = 0/0,  -- NaN
	booleanTrue = true,
	booleanFalse = false,

	-- Roblox datatypes
	brickColor = BrickColor.new(194),  -- Red
	cframe = CFrame.new(1, 2, 3) * CFrame.Angles(0, math.pi/2, 0),
	color3 = Color3.new(1, 0.5, 0),  -- Orange
	white = Color3.fromRGB(255, 255, 255), -- this one shall be optimized to FFF
	colorSequence = ColorSequence.new(Color3.new(1,0,0), Color3.new(0,1,0)),  -- Red to Green
	content = Content.fromUri("rbxassetid://123456789"),  -- Example asset ID
	enumItem = Enum.FontWeight.Bold,
	font = Font.new("rbxasset://fonts/Arial.ttf", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
	numberRange = NumberRange.new(5, 10),
	numberSequence = NumberSequence.new(0.5),  -- Simple case
	ray = Ray.new(Vector3.new(0,0,0), Vector3.new(1,0,0)),
	rect = Rect.new(0, 0, 100, 100),
	udim = UDim.new(0.5, 10),
	udim2 = UDim2.new(0.5, 10, 0.25, 20),
	vector2 = Vector2.new(1, 2),
	vector3 = Vector3.new(1, 2, 3),

	keypoints = {
		num = NumberSequenceKeypoint.new(0, 1),
		numEnvelope = NumberSequenceKeypoint.new(0, 1, 0.5),
		col = ColorSequenceKeypoint.new(-1, Color3.fromRGB(25, 86, 255))
	},

	-- Nested table
	nested = {
		innerString = "inner",
		innerNumber = 99,
		innerNaN = 0/0,
		innerTable = {
			deepString = "deep",
			deepHuge = math.huge,
		},
		innerColor3 = Color3.new(0,1,1),  -- Cyan
	},

	-- Array-like table
	array = {1, "two", true, Vector3.new(4,5,6), math.huge, 0/0},
}

-- Encode
local encoded = CoffeeParser.Encode(testData)
print("Encoded data:")
local JSONEncode = HttpService:JSONEncode(encoded)
print("Encoded by CoffeeParser =", encoded)
print("HttpService:JSONEncode(Encoded by CoffeeParser) = (made into a table to prevent output clutter)", {
	["lenght"] = #JSONEncode,
	["result"] = JSONEncode,
})

-- Decode
local decoded = CoffeeParser.Decode(encoded)
print("Decoded data:")
print(decoded)

-- Compare with tolerance
local isEqual, difference = DeepCompare(testData, decoded)
print("Data preserved after encode/decode:", isEqual)

if isEqual then
	print("Data preserved perfectly! (Given that some values were rounded and are slightly different from original)")
else
	print("Mismatch or multiple detected! Please review:")
	print(difference)
end