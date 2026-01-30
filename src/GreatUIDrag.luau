--[[--
    Quick Start and API can be found at
    https://github.com/Coffilhg/Useful-Modules/tree/GreatUIDrag

    GreatUIDrag
    Copyright © 2026 Coffilhg (Roblox UserId 517222346)
    
    

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    Full License & Notices: https://github.com/Coffilhg/Useful-Modules/tree/GreatUIDrag
    Module Version: 1.0.0
--]]--

local UIS = game:GetService("UserInputService")
local RunS = game:GetService("RunService")




--- Dependencies (By @Coffilhg) ---

-- GUICompatibility's Source Repository: https://github.com/Coffilhg/Useful-Modules/tree/GUICompatibility
local GUICompatibility = require(script.GUICompatibility) -- or wherever it's located and whatever it's named

-- CoffeeObjects's Source Repository: https://github.com/Coffilhg/Useful-Modules/tree/CoffeeObjects
local CoffeeObjects = require(script.CoffeeObjects) -- or wherever it's located and whatever it's named
local CoffeeBaseValue = CoffeeObjects.CoffeeBaseValue

--- /E Dependencies (By @Coffilhg) ---

--- Dependencies (Not By @Coffilhg) ---

-- _Spring Obtained from (Toolbox) https://create.roblox.com/store/asset/71132874095126/Spring-Module
-- by @crusherfire (https://www.roblox.com/users/80102935/profile)
local Spring = require(script._Spring) -- or wherever it's located and whatever it's named

--- /E Dependencies (Not By @Coffilhg) ---




local GUIInsetZero = CoffeeBaseValue.new(0)
local GUIInsetZeroVector = CoffeeBaseValue.new(Vector2.new(0, 0))
local GUIInsetSize = GUICompatibility:GetGuiInsetSize()
local GUIInsetSizeVector = CoffeeBaseValue.new(Vector2.new(0, GUIInsetSize.Value))
GUIInsetSize.Changed:Connect(function(_, newValue)
	GUIInsetSizeVector.Value = Vector2.new(0, newValue)
end)
local camera = GUICompatibility:GetCamera()



--- Default Side Padding for when Dragging ---
local Padding = UDim.new(0, 30)

local function toUDim(v)
	if typeof(v) == "UDim" then
		return v
	end
	
	if type(v) ~= "number" then
		return Padding
	end
	
	return UDim.new(0, v or 0)
end

local cbs = {
	["0"] = function()
		return Padding, Padding, Padding, Padding
	end,
	["1"] = function(padding)
		local p = toUDim(padding[1])
		return p, p, p, p
	end,
	["2"] = function(padding)
		local xp = toUDim(padding[2])
		local yp = toUDim(padding[1])
		return yp, xp, yp, xp
	end,
	["3"] = function(padding)
		local xp = toUDim(padding[2])
		return toUDim(padding[1]), xp, toUDim(padding[3]), xp
	end,
	["4"] = function(padding)
		return toUDim(padding[1]), toUDim(padding[2]), toUDim(padding[3]), toUDim(padding[4])
	end,
}

local function normalizePadding(p : {[number]: number | UDim}?)
	p = p or {}
	
	local t, r, b, l = cbs[`{math.min(#p, 4)}`](p)

	return {
		top = t,
		right = r,
		bottom = b,
		left = l,
	}
end



--- Global Variables ---
local LastDragElement = {Stop = function() end,}

UIS.InputEnded:Connect(function(input)
	if not LastDragElement["_isActive"] then
		return
	end
	
	local userInputType = input.UserInputType
	if not (userInputType == Enum.UserInputType.MouseButton1 or userInputType == Enum.UserInputType.Touch) then
		return
	end
	
	LastDragElement:Stop()
end)
UIS.InputChanged:Connect(function(input)
	if not LastDragElement["_isActive"] then
		return
	end
	
	LastDragElement._position.Target = Vector2.new(input.Position.X, input.Position.Y + LastDragElement._InputInset.Value)
	
	LastDragElement:Reposition()
end)



local DragElement = {}
DragElement.__index = DragElement

function DragElement:_AdjustInsets()
	if self["_ancestorConnection"] then
		self._ancestorConnection:Disconnect()
	end
	
	
	
	local screenGui = self._dragElement:FindFirstAncestorOfClass("ScreenGui")
	
	if not screenGui then
		self._blocked = true
		return
	end

	self._blocked = nil

	local function updateInsets(skipReposition)
		if screenGui.IgnoreGuiInset then
			self._InputInset = GUIInsetSize
			self._InitInsetVector = GUIInsetSizeVector

			self._GUIInset = GUIInsetZero
			self._GUIInsetVector = GUIInsetZeroVector
		else
			self._InputInset = GUIInsetZero
			self._InitInsetVector = GUIInsetZeroVector

			self._GUIInset = GUIInsetSize
			self._GUIInsetVector = GUIInsetSizeVector
		end
		if not skipReposition then
			self:Reposition()
		end
	end

	updateInsets(true)

	self._ancestorConnection = screenGui:GetPropertyChangedSignal("IgnoreGuiInset"):Connect(updateInsets)

end
function DragElement:_UpdateAnchorPoint()
	self._anchorX = self._dragElement.AnchorPoint.X
	self._anchorY = self._dragElement.AnchorPoint.Y
end
function DragElement:_Recalculate()

	GUICompatibility:UpdateAndGetGuiInsetSize()
	
	local viewport = camera.ViewportSize
	local p = self._rawPadding
	
	local x1 = (p.left.Scale * viewport.X + p.left.Offset) --- left
	local x2 = viewport.X - self._absoluteSize.X - (p.right.Scale * viewport.X + p.right.Offset) --- right
	self._minInputX = math.min(x1, x2)
	self._maxInputX = math.max(x1, x2)

	local y1 = (p.top.Scale * viewport.Y + p.top.Offset) --- top
	if p.top.Scale < 0 or p.top.Offset < 0 then
		-- this one is only the case when top padding is negative (and IgnoreGuiInsets is off)
		y1 -= self._GUIInset.Value * (math.min(p.top.Scale, 0) + math.min(p.top.Offset, 0)/viewport.Y)
	end
	local y2 = viewport.Y - self._absoluteSize.Y - self._GUIInset.Value - (p.bottom.Scale * (viewport.Y - self._GUIInset.Value) + p.bottom.Offset) --- bottom
	self._minInputY = math.min(y1, y2)
	self._maxInputY = math.max(y1, y2)
	
end
function DragElement:_KeepAlive(calledByReposition : boolean)
	
	if self["_springConnection"] then
		if calledByReposition then
			return
		end
		self._springConnection:Disconnect()
	end
	
	self._springConnection = RunS.Heartbeat:Connect(function()
		if Spring.IsAtRest(self._position) and not self._isActive then
			self._springConnection:Disconnect()
			self._springConnection = nil
		end

		self:Reposition()
	end)
	
end
function DragElement:Reposition()
	
	if self["_blocked"] then
		self:Stop()
		return
	end
	
	local startObjectPos = self._startObjectPos
	local currentSpringState = self._position.Position
	local startMousePos = self._startMousePos
	
	local sensibility = self._sensibility
	local absoluteSize = self._absoluteSize
	
	self._dragElement.Position = UDim2.new(
		0,
		math.clamp(
			startObjectPos.X + (currentSpringState.X - startMousePos.X) * sensibility,
			self._minInputX,
			self._maxInputX
		) + absoluteSize.X*self._anchorX,
		0,
		math.clamp(
			startObjectPos.Y + (currentSpringState.Y - startMousePos.Y) * sensibility,
			self._minInputY,
			self._maxInputY
		) + absoluteSize.Y*self._anchorY
	)

	self:_KeepAlive(true)
	
end

function DragElement:InitDrag()
	if self["_isActive"] then return end
	LastDragElement:Stop()
	self._isActive = true
	
	
	
	local startObjectPos = self._dragElement.AbsolutePosition + self._InitInsetVector.Value --only when IgnoreGuiInset == true+ GUIInsetSizeVector.Value
	local startMousePos = UIS:GetMouseLocation() - self._GUIInsetVector.Value
	
	self._startMousePos = startMousePos
	self._startObjectPos = startObjectPos
	
	self._absoluteSize = self._dragElement.AbsoluteSize
	self:_Recalculate()
	
	self._position.Position = startMousePos
	self._position.Target = startMousePos
	
	
	
	LastDragElement = self
end
function DragElement:Stop()
	self._isActive = false
	self:_KeepAlive()
end

local DragElements = {}
camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	for _, dragElement in ipairs(DragElements) do
		dragElement:_Recalculate()
		dragElement:Reposition()
	end
end)



-- paddingOptions matches the css syntax: {paddingX, paddingY} or {top, right, bottom, left}
-- each padding value can be either a Number or a UDim
return function(
	dragElement : GuiObject,
	dragHandle : (TextButton | ImageButton) | {(TextButton | ImageButton)},
	damping : number?,
	speed : number?,
	paddingOptions : {}?,
	sensibilityMultiplier : number?
)
	
	assert(dragElement:IsA("GuiObject"), "dragElement MUST be any GuiObject Instance (e.g.: Frame, ImageLabel, ScrollingFrame, TextLabel, etc.)")
	
	local self
	local function init()
		self:InitDrag()
	end

	if type(dragHandle) == "table" then
		local totalHandles = 0
		for _, handle in pairs(dragHandle) do
			if typeof(handle) ~= "Instance" then
				continue
			end

			if handle:IsA("TextButton") or handle:IsA("ImageButton") then
				handle.TouchTap:Connect(init) -- For Mobiles
				handle.MouseButton1Down:Connect(init) -- For Desktop
				totalHandles += 1
			end
		end
		assert(totalHandles > 0, "dragHandle MUST contain at least ONE TextButton or Imagebutton Instance")
	else
		assert(dragHandle:IsA("TextButton") or dragHandle:IsA("ImageButton"), "dragHandle MUST be a TextButton or an Imagebutton Instance")
		dragHandle.TouchTap:Connect(init) -- For Mobiles
		dragHandle.MouseButton1Down:Connect(init) -- For Desktop
	end
	
	self = setmetatable({
		_rawPadding = normalizePadding(paddingOptions),
		_dragElement = dragElement,
		_absoluteSize = dragElement.AbsoluteSize,
		_position = Spring.new(dragElement.AbsolutePosition, damping or 1, speed or (27 / (sensibilityMultiplier or 1))),
		_isActive = false,
		_sensibility = sensibilityMultiplier or 1,
	}, DragElement)
	
	
	self:_AdjustInsets()
	dragElement:GetPropertyChangedSignal("Parent"):Connect(function()
		self:_AdjustInsets()
	end)
	
	self:_UpdateAnchorPoint()
	dragElement:GetPropertyChangedSignal("AnchorPoint"):Connect(function()
		self:_UpdateAnchorPoint()
	end)
	
	self:_Recalculate()
	table.insert(DragElements, self)
	
	return self
end