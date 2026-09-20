--[[--
    GreatUIDrag V2.0.0
    Copyright © 2026 Coffilhg (Roblox UserId 517222346)

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/.

    GitHub Repository/Branch with latest version, documentation, etc:
    https://github.com/Coffilhg/Useful-Modules/tree/GreatUIDrag
    Stars are appreciated!
--]]--
--!strict
--!optimize 2

local UIS = game:GetService("UserInputService")
local RunS = game:GetService("RunService")




--- Dependencies (By @Coffilhg) ---

-- GUICompatibility's Source Repository: https://github.com/Coffilhg/Useful-Modules/tree/GUICompatibility
local GUICompatibility = require(`./GUICompatibility`) -- or wherever it's located and whatever it's named

-- CoffeeObjects's Source Repository: https://github.com/Coffilhg/Useful-Modules/tree/CoffeeObjects
local CoffeeObjects = require(`./CoffeeObjects`) -- or wherever it's located and whatever it's named
local CoffeeBaseValue = CoffeeObjects.CoffeeBaseValue

type sVal<T> = CoffeeObjects.CoffeeBaseValueStrict<T>

--- /E Dependencies (By @Coffilhg) ---

--- Dependencies (Not By @Coffilhg) ---

-- _Spring Obtained from (Toolbox) https://create.roblox.com/store/asset/71132874095126/Spring-Module
-- by @crusherfire (https://www.roblox.com/users/80102935/profile)
local Spring = require(`@self/_Spring`) -- or wherever it's located and whatever it's named

-- LemonSignal's Source Repository: https://github.com/Data-Oriented-House/LemonSignal
local Signal = require(`./LemonSignal`) -- or wherever it's located and whatever it's named

--- /E Dependencies (Not By @Coffilhg) ---




local GUIInsetZero : sVal<number> = CoffeeBaseValue.strictNew(0)
local GUIInsetZeroVector : sVal<Vector2> = CoffeeBaseValue.strictNew(Vector2.new(0, 0))
local GUIInsetSize : sVal<number> = GUICompatibility:GetGuiInsetSize() :: sVal<number>
local GUIInsetSizeVector : sVal<Vector2> = CoffeeBaseValue.strictNew(Vector2.new(0, GUIInsetSize.Value))

GUIInsetSize.Changed:Connect(function(_, newValue)
	GUIInsetSizeVector.Value = Vector2.new(0, newValue)
end)
local camera = GUICompatibility:GetCamera()



--- Default Side Padding for when Dragging ---
local Padding : UDim = UDim.new(0, 30)

--- Utilities ---

-- Safe Get Number
local function sgn(value : number | any, default : number) : number
	return type(value) == "number" and value or default
end

type UDimConvertable = UDim | number | any

local function toUDim(v : UDimConvertable) : UDim
	if typeof(v) == "UDim" then
		return v :: UDim
	end

	if type(v) == "number" then
		return UDim.new(0, v)
	end

	return Padding
end

local cbs : {
	["0" | "1" | "2" | "3" | "4"]: (({[number]: UDimConvertable} | {})) -> (UDim, UDim, UDim, UDim),
} = {
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

local function normalizePadding(p : (number | UDim | {[number]: UDimConvertable} | {})?)
	p = type(p) == "table" and p or (p and {p} or {})

	local k = `{math.min(#p, 4)}` :: "0" | "1" | "2" | "3" | "4"
	local t, r, b, l = cbs[k](p)

	return {
		top = t,
		right = r,
		bottom = b,
		left = l,
	}
end



--- Global Variables ---
--[[
--	Stop is required here to handle the first ever
--	DragElement.InitDrag call; Afterwards the
--	LastDragElement is guaranteed to be a valid,
--	complete DragElement object; Represents the
--	Latest/lastest DragElement that was ever used
--]]
local NoDragElement : DragElement = {Stop = function() end,} :: DragElement
local LastDragElement : DragElement = NoDragElement

local DragElements = {} :: {[number]: DragElement}

--- UIS Connections ---

UIS.InputEnded:Connect(function(input : InputObject)
	if not LastDragElement["_isActive"] then
		return
	end
	
	local userInputType = input.UserInputType
	if not (userInputType == Enum.UserInputType.MouseButton1 or userInputType == Enum.UserInputType.Touch) then
		return
	end
	
	LastDragElement:Stop()
end)
UIS.InputChanged:Connect(function(input : InputObject)
    local last = LastDragElement -- cache the DragElement
	if not last["_isActive"] then -- skip the NoDragElement
		return
	end

	if time() - (last._startTime or 0) < last["_delay"] then
		return
	end

	if not last["_contactConfirmed"] then
		last["_contactConfirmed"] = true
		last.OnDragStarted:Fire(last._lastTriggerHandle)
	end

	last._position.Target = Vector2.new(input.Position.X, input.Position.Y + last._InputInset.Value)

	last:Reposition()
end)



--- DragElement definition ---

local DragElement = {}
DragElement.__index = DragElement

export type DragElement = typeof(DragElement)
export type DragHandle = (TextButton | ImageButton | GuiButton)

function DragElement._AdjustInsets(self : DragElement)
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
			self._InputInset = GUIInsetSize :: sVal<number>
			self._InitInsetVector = GUIInsetSizeVector :: sVal<Vector2>

			self._GUIInset = GUIInsetZero :: sVal<number>
			self._GUIInsetVector = GUIInsetZeroVector :: sVal<Vector2>
		else
			self._InputInset = GUIInsetZero :: sVal<number>
			self._InitInsetVector = GUIInsetZeroVector :: sVal<Vector2>

			self._GUIInset = GUIInsetSize :: sVal<number>
			self._GUIInsetVector = GUIInsetSizeVector :: sVal<Vector2>
		end
		if not skipReposition then
			self:Reposition()
		end
	end

	updateInsets(true)

	self._ancestorConnection = screenGui:GetPropertyChangedSignal("IgnoreGuiInset"):Connect(updateInsets)

end
function DragElement._UpdateAnchorPoint(self : DragElement)
	self._anchorX = self._dragElement.AnchorPoint.X
	self._anchorY = self._dragElement.AnchorPoint.Y
end
function DragElement._Recalculate(self : DragElement)

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
function DragElement._KeepAlive(
	self : DragElement,
	calledByReposition : boolean?
)

    if self:IsDestroyed() then
        return
    end

	if self["_springConnection"] then
		if calledByReposition then
			return
		end
		self._springConnection:Disconnect()
	end

	self._springConnection = RunS.Heartbeat:Connect(function()
		if self._position:IsAtRest() and not self._isActive then
			self._springConnection:Disconnect()
			self._springConnection = nil

			self.OnDragCompleted:Fire(self._position.Target, self._contactConfirmed, self._lastTriggerHandle)
			return
		end

		self:Reposition()
	end)

end
function DragElement.Reposition(self : DragElement)

    if self:IsDestroyed() then
        return
    end

	if self["_blocked"] then
		self:Stop()
		return
	end
	
	-- Never been dragged yet: nothing to reposition
	if not (self._startObjectPos and self._startMousePos) then
		return
	end

	local startObjectPos = self._startObjectPos
	local currentSpringState = self._position.Position
	local startMousePos = self._startMousePos

	local sensibility = self._sensibility
	local absoluteSize = self._absoluteSize

	local absoluteX = math.clamp(
		startObjectPos.X + (currentSpringState.X - startMousePos.X) * sensibility,
		self._minInputX,
		self._maxInputX
	) + absoluteSize.X
		*	self._anchorX

	local abosluteY = math.clamp(
		startObjectPos.Y + (currentSpringState.Y - startMousePos.Y) * sensibility,
		self._minInputY,
		self._maxInputY
	) + absoluteSize.Y
		*	self._anchorY

	self.OnPositionChanged:Fire(absoluteX, abosluteY)

	self._dragElement.Position = UDim2.fromOffset(
		absoluteX,
		abosluteY
	)

	-- Only keep the spring loop alive while something is still moving.
	-- A plain re-clamp (viewport resize, IgnoreGuiInset change) must not start a loop,
	-- otherwise it would fire OnDragCompleted for a drag that never happened.
	if self._isActive or not self._position:IsAtRest() then
		self:_KeepAlive(true)
        return
	end

    --print("Not keeping alive")

end

-- Necessary for correct calculation of position;
-- In the first version it was exclusive to be executed internally for :InitDrag Method
function DragElement._OnDragInit(
	self : DragElement
)
	local startObjectPos = self._dragElement.AbsolutePosition + self._InitInsetVector.Value :: Vector2 --only when IgnoreGuiInset == true+ GUIInsetSizeVector.Value
	local startMousePos = UIS:GetMouseLocation() - self._GUIInsetVector.Value :: Vector2

	self._startMousePos = startMousePos :: Vector2
	self._startObjectPos = startObjectPos :: Vector2

	self._absoluteSize = self._dragElement.AbsoluteSize
	self:_Recalculate()

	self._position.Position = startMousePos
	self._position.Target = startMousePos
end

-- Immediately sets the Position of the DragElement and resets it's target
-- If no position is given takes current players mouse position
function DragElement.SetPosition(
	self : DragElement,
	newDragElementPosition : UDim2?
)

    if self:IsDestroyed() then
        return
    end

	local previouslyBlocked = self["_blocked"]
	self["_blocked"] = true

	if typeof(newDragElementPosition) == "UDim2" then
		self._dragElement.Position = newDragElementPosition
	else
		local mouseLocation = UIS:GetMouseLocation() - self._GUIInsetVector.Value
		self._dragElement.Position = UDim2.fromOffset(mouseLocation.X, mouseLocation.Y)
	end

	self:_OnDragInit()

	self["_blocked"] = previouslyBlocked
end

function DragElement.InitDrag(
	self : DragElement,
	triggerHandle : DragHandle
)

    if self:IsDestroyed() then
        return
    end

	if self["_isActive"] then return end
	LastDragElement:Stop()
	self._startTime = time()
	self._lastTriggerHandle = triggerHandle
	self._isActive = true
	self._contactConfirmed = nil -- clear "_contactConfirmed" so it can be confirmed again



	self:_OnDragInit()



    -- assign before OnDragContact, so that even if
    -- OnDragContact does :Destroy, the LastDragElement
    -- the LastDragElement doesn't become a Destroyed
    -- DragElement (self in this case)
	LastDragElement = self



	self.OnDragContact:Fire(self._lastTriggerHandle)
end
function DragElement.Stop(self : DragElement)
	--warn(`Trying to stop DragElement with self["_isActive"] = {self["_isActive"]}`)
	if self["_isActive"] ~= true then return end -- prevent double stop (prevents OnDragReleased from firing twice)
	--warn(`STOPPING DragElement with self["_isActive"] = {self["_isActive"]}`)

	self._isActive = false
	self:_KeepAlive()

	self.OnDragReleased:Fire(self._position.Target, self._contactConfirmed, self._lastTriggerHandle)
end

function DragElement.AddHandle(
	self : DragElement,
	dragHandle : ( DragHandle | {DragHandle} )?
)
    local connections = self._connections
    -- equivalent of self:IsDestroyed(), we just want it cached (as upvalue)
    if connections == nil then
        return
    end

	if type(dragHandle) == "table" then
		for _, handle in pairs(dragHandle) do
			if typeof(handle) ~= "Instance" then
				continue
			end

			if handle:IsA("GuiButton") then
				local function init()
					self:InitDrag(handle)
				end
                table.insert(
                    connections,
                    handle.TouchTap:Connect(init) -- For Mobiles
                )
				table.insert(
                    connections,
                    handle.MouseButton1Down:Connect(init) -- For Desktop
                )
			end
		end
	elseif typeof(dragHandle) == "Instance" then
		assert(dragHandle:IsA("GuiButton"), "dragHandle MUST be a TextButton or an Imagebutton (or a GuiButton) Instance")

		local function init()
			self:InitDrag(dragHandle)
		end
        table.insert(
            connections,
            dragHandle.TouchTap:Connect(init) -- For Mobiles
        )
		table.insert(
            connections,
            dragHandle.MouseButton1Down:Connect(init) -- For Desktop
        )
	end
end

function DragElement.Destroy(self : DragElement)
	local connections = self._connections
	if not connections then return end -- already destroyed

	self._connections = nil -- IsDestroyed() is true from here on
	self._blocked = true    -- no more Reposition()
	self._isActive = false  -- an active drag is cancelled silently
	if LastDragElement == self then
		LastDragElement = NoDragElement
	end

	local index = table.find(DragElements, self)
	if index then
		table.remove(DragElements, index)
	end

	if self["_springConnection"] then
		self._springConnection:Disconnect()
		self._springConnection = nil
	end
    if self["_ancestorConnection"] then
		self._ancestorConnection:Disconnect()
		self._ancestorConnection = nil
	end

	for _, connection in connections do
		connection:Disconnect()
	end

	self.OnDragContact:DisconnectAll()
	self.OnDragStarted:DisconnectAll()
	self.OnDragReleased:DisconnectAll()
	self.OnDragCompleted:DisconnectAll()
	self.OnPositionChanged:DisconnectAll()
end

function DragElement.IsDestroyed(self : DragElement) : boolean
	return self._connections == nil
end

camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    for i = #DragElements, 1, -1 do
		local dragElement = DragElements[i]
		if not dragElement then
            continue
		end

        -- don't check :IsDestroyed, that's redundant
        -- _Recalculate doesn't care
        -- Reposition does this anyways

        dragElement:_Recalculate()
		dragElement:Reposition()
	end
end)



-- paddingOptions matches the css syntax: {paddingX, paddingY} or {top, right, bottom, left}
-- each padding value can be either a Number or a UDim
return function(
	dragElement : GuiObject,
	dragHandle : ( DragHandle | {DragHandle} )?,
	damping : number?,
	speed : number?,
	paddingOptions : (number | UDim | {number | UDim})?,
	sensibilityMultiplier : number?,
	dragStartDelay : number?
) : DragElement

	assert(dragElement:IsA("GuiObject"), "dragElement MUST be any GuiObject Instance (e.g.: Frame, ImageLabel, ScrollingFrame, TextLabel, etc.)")

	local self = setmetatable({}, DragElement) :: DragElement

    local connections: {RBXScriptConnection} = {}
    self._connections = connections :: {RBXScriptConnection}? -- nil after Destroyed

	self:AddHandle(dragHandle)


	self._rawPadding = normalizePadding(paddingOptions)
	self._dragElement = dragElement
	self._absoluteSize = dragElement.AbsoluteSize
	self._position = Spring.new(dragElement.AbsolutePosition, sgn(damping, 1), sgn(speed, 27 / sgn(sensibilityMultiplier, 1)) ) :: Spring.Spring<Vector2>
	self._isActive = false
	self._sensibility = sgn(sensibilityMultiplier, 1)
	self._delay = sgn(dragStartDelay, 0.24)
	self._startTime = time()
	self._contactConfirmed = nil :: boolean?
	self._lastTriggerHandle = nil :: DragHandle?

	--- events (GoodSignal)
	--:Connect(function(triggerHandle) --[[your code]]-- end)
	self.OnDragContact = Signal.new() :: Signal.Signal<DragHandle?> -- first contact with the dragElement made;
	self.OnDragStarted = Signal.new() :: Signal.Signal<DragHandle?> -- fires after OnDragContact and dragStartDelay if not OnDragReleased;
	--:Connect(function(finalGoal, IsDragStartFiredBeforeReleased, triggerHandle) --[[your code]]-- end)
	self.OnDragReleased = Signal.new() :: Signal.Signal<Vector2, boolean?, DragHandle?> -- fires after dragElement gets released or another dragElement is starting, continues moving towards the final goal;
	self.OnDragCompleted = Signal.new() :: Signal.Signal<Vector2, boolean?, DragHandle?> -- fires after the final goal was reached;
	--:Connect(function(currentAbsoluteX : number, currentAbsoluteY : number) --[[your code]]-- end)
	self.OnPositionChanged = Signal.new() :: Signal.Signal<number, number> -- fires on Reposition / UIS.InputChanged while used;

	--- Dynamic
	--self._init = init -- init (self:InitDrag()) shortcut for runtime added drag handles

	--- types compliance
	self._blocked = nil :: boolean?
	self._InputInset = GUIInsetSize :: sVal<number>
	self._InitInsetVector = GUIInsetSizeVector :: sVal<Vector2>
	self._GUIInset = GUIInsetZero :: sVal<number>
	self._GUIInsetVector = GUIInsetZeroVector :: sVal<Vector2>

    --self._startMousePos = Vector2.zero :: Vector2
	--self._startObjectPos = Vector2.zero :: Vector2

    -- NOTE: _startMousePos and _startObjectPos are intentionally NOT initialized here.
	-- They stay nil until the first drag/SetPosition, and :Reposition() relies on that
	-- to skip repositioning before the element was ever dragged.



	self:_AdjustInsets()
	table.insert(
        connections,
        dragElement:GetPropertyChangedSignal("Parent"):Connect(function()
            self:_AdjustInsets()
        end)
    )

    table.insert(
        connections,
        -- it's only :Once, but if :Destroy is used manually on DragElement, this must be in connections.
        dragElement.Destroying:Once(function()
            self:Destroy()
        end)
    )

	self:_UpdateAnchorPoint()
	table.insert(
        connections,
        dragElement:GetPropertyChangedSignal("AnchorPoint"):Connect(function()
            self:_UpdateAnchorPoint()
        end)
    )

	self:_Recalculate()
	table.insert(DragElements, self)

	return self
end