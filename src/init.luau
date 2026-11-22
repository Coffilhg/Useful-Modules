--[[--
    GreatUIDrag V2.1.0
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

const UIS = game:GetService("UserInputService")
const RunS = game:GetService("RunService")
const GuiS = game:GetService("GuiService")

--- Dependencies (Not By @Coffilhg) ---

-- _Spring Obtained from (Toolbox) https://create.roblox.com/store/asset/71132874095126/Spring-Module
-- by @crusherfire (https://www.roblox.com/users/80102935/profile)
const Spring = require(`@self/_Spring`) -- or wherever it's located and whatever it's named

-- LemonSignal's Source Repository: https://github.com/Data-Oriented-House/LemonSignal
const Signal = require(`./LemonSignal`) -- or wherever it's located and whatever it's named

--- /E Dependencies (Not By @Coffilhg) ---





--- Default Side Padding for when Dragging ---
const Padding : UDim = UDim.new(0, 30)


--- Utilities ---

-- Safe Get Number
const function sgn(value : number | any, default : number) : number
	return type(value) == "number" and value or default
end

type UDimConvertable = UDim | number | any
type PaddingConverterCallbackKeys = "0" | "1" | "2" | "3" | "4"
type PaddingConverterCallbacks = {
	[PaddingConverterCallbackKeys]: (({[number]: UDimConvertable} | {})) -> (UDim, UDim, UDim, UDim),
}

const function toUDim(v : UDimConvertable) : UDim
	if typeof(v) == "UDim" then
		return v :: UDim
	end

	if type(v) == "number" then
		return UDim.new(0, v)
	end

	return Padding
end

const cbs: PaddingConverterCallbacks = {
	["0"] = function()
		return Padding, Padding, Padding, Padding
	end,
	["1"] = function(padding)
		const p = toUDim(padding[1])
		return p, p, p, p
	end,
	["2"] = function(padding)
		const xp = toUDim(padding[2])
		const yp = toUDim(padding[1])
		return yp, xp, yp, xp
	end,
	["3"] = function(padding)
		const xp = toUDim(padding[2])
		return toUDim(padding[1]), xp, toUDim(padding[3]), xp
	end,
	["4"] = function(padding)
		return toUDim(padding[1]), toUDim(padding[2]), toUDim(padding[3]), toUDim(padding[4])
	end,
}

const function normalizePadding(p : (number | UDim | {[number]: UDimConvertable} | {})?)
	p = type(p) == "table" and p or (p and {p} or {})

	const k = `{math.min(#p, 4)}` :: PaddingConverterCallbackKeys
	const t, r, b, l = cbs[k](p)

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
const NoDragElement : DragElement = {Stop = function() end,} :: DragElement
local LastDragElement : DragElement = NoDragElement

const EndedUserInputTypes: {[Enum.UserInputType]: true} = {
	[Enum.UserInputType.MouseButton1] = true,
	[Enum.UserInputType.Touch] = true,
}
const MovedUserInputTypes: {[Enum.UserInputType]: true} = {
	[Enum.UserInputType.MouseMovement] = true,
	[Enum.UserInputType.Touch] = true,
}

--- UIS Connections ---

UIS.InputEnded:Connect(function(input : InputObject)
	if not LastDragElement["_isActive"] then
		return
	end
	
	if not EndedUserInputTypes[input.UserInputType] then
		return
	end
	
	LastDragElement:Stop()
end)
UIS.InputChanged:Connect(function(input : InputObject)
    const last = LastDragElement -- cache the DragElement
	if not last["_isActive"] then -- skip the NoDragElement
		return
	end

	-- MouseWheel, Gamepad thumbsticks, etc. also fire InputChanged, their Position isn't the pointer
	-- not MovedUserInputTypes[input.UserInputType], where MovedUserInputTypes[input.UserInputType] = true?
	if not MovedUserInputTypes[input.UserInputType] then
		return
	end

	if time() - (last._startTime or 0) < last["_delay"] then
		return
	end

	if not last["_contactConfirmed"] then
		last["_contactConfirmed"] = true
		last.OnDragStarted:Fire(last._lastTriggerHandle)
	end

	-- InputObject.Position is already in absolute space
	last._position.Target = Vector2.new(input.Position.X, input.Position.Y)

	last:Reposition()
end)



--- DragElement definition ---

const DragElement = {}
DragElement.__index = DragElement

export type DragElement = typeof(DragElement)
export type DragHandle = (TextButton | ImageButton | GuiButton)

-- Finds the ScreenGui the element lives in and listens to its AbsoluteSize/AbsolutePosition,
-- which change on viewport resizes, device switches and IgnoreGuiInset/ScreenInsets changes alike
function DragElement._AdjustScreenGui(self : DragElement)
	const screenConnections = self._screenConnections
	for _, connection in screenConnections do
		connection:Disconnect()
	end
	table.clear(screenConnections)



	const screenGui = self._dragElement:FindFirstAncestorOfClass("ScreenGui")
	self._screenGui = screenGui

	if not screenGui then
		self._blocked = true
		return
	end

	self._blocked = nil

	-- the ScreenGui's AbsoluteSize/AbsolutePosition are already final when these fire
	const function onScreenChanged()
		self:_Refit()
	end
	table.insert(screenConnections, screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(onScreenChanged))
	table.insert(screenConnections, screenGui:GetPropertyChangedSignal("AbsolutePosition"):Connect(onScreenChanged))

	self:_Recalculate()
end
function DragElement._UpdateAnchorPoint(self : DragElement)
	self._anchorX = self._dragElement.AnchorPoint.X
	self._anchorY = self._dragElement.AnchorPoint.Y
end
-- Absolute position where the element's Position offset (0, 0) is
function DragElement._GetParentOrigin(self : DragElement) : Vector2
	const parent = self._dragElement.Parent
	if parent and parent:IsA("GuiBase2d") then
		if parent:IsA("ScrollingFrame") then
			return parent.AbsolutePosition - parent.CanvasPosition
		end
		return parent.AbsolutePosition
	end

	-- e.g. a Folder in between, GuiObjects then render relative to the ScreenGui
	const screenGui = self._screenGui
	return if screenGui then screenGui.AbsolutePosition else Vector2.zero
end
-- Bounds (for the element's top-left corner) in absolute space: the ScreenGui's rectangle minus the padding
function DragElement._Recalculate(self : DragElement)
	const screenGui = self._screenGui
	if not screenGui then
		return
	end

	const origin = screenGui.AbsolutePosition
	const size = screenGui.AbsoluteSize
	const oX, oY = origin.X, origin.Y
	const sX, sY = size.X, size.Y
	const absoluteSize = self._absoluteSize
	const p = self._rawPadding
	const left, right, top, bottom = p.left, p.right, p.top, p.bottom

	const x1 = oX + left.Scale * sX + left.Offset --- left
	const x2 = oX + size.X - absoluteSize.X - (right.Scale * sX + right.Offset) --- right
	self._minInputX = math.min(x1, x2)
	self._maxInputX = math.max(x1, x2)

	const y1 = oY + top.Scale * sY + top.Offset --- top
	const y2 = oY + size.Y - absoluteSize.Y - (bottom.Scale * sY + bottom.Offset) --- bottom
	self._minInputY = math.min(y1, y2)
	self._maxInputY = math.max(y1, y2)

end
-- Re-clamps the element into the (possibly new) bounds
function DragElement._Refit(self : DragElement)
	if self:IsDestroyed() or self["_blocked"] then
		return
	end
	-- Never been dragged yet: leave it where the developer put it
	if not self._startObjectPos then
		return
	end

	self._absoluteSize = self._dragElement.AbsoluteSize

	-- Resting element: re-anchor to where it is now, since the last drag's
	-- start positions may belong to a screen that doesn't exist anymore
	if not self._isActive and self._position:IsAtRest() then
		self._startObjectPos = self._dragElement.AbsolutePosition
		self._startMousePos = self._position.Position
	end

	self:_Recalculate()
	self:Reposition()
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
		const isActive = self._isActive
		if self._position:IsAtRest() and not isActive then
			(self._springConnection :: RBXScriptConnection):Disconnect()
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
	const startObjectPos = self._startObjectPos
	const startMousePos = self._startMousePos
	if not (startObjectPos and startMousePos) then
		return
	end

	const currentSpringState = self._position.Position

	const sensibility = self._sensibility
	const absoluteSize = self._absoluteSize

	-- absolute space position of the element's AnchorPoint
	const absoluteX = math.clamp(
		startObjectPos.X + (currentSpringState.X - startMousePos.X) * sensibility,
		self._minInputX,
		self._maxInputX
	) + absoluteSize.X
		*	self._anchorX

	const absoluteY = math.clamp(
		startObjectPos.Y + (currentSpringState.Y - startMousePos.Y) * sensibility,
		self._minInputY,
		self._maxInputY
	) + absoluteSize.Y
		*	self._anchorY

	-- Position offsets start where the parent starts
	const parentOrigin = self:_GetParentOrigin()
	const offsetX = absoluteX - parentOrigin.X
	const offsetY = absoluteY - parentOrigin.Y

	self.OnPositionChanged:Fire(offsetX, offsetY)

	self._dragElement.Position = UDim2.fromOffset(
		offsetX,
		offsetY
	)

	-- Only keep the spring loop alive while something is still moving.
	-- A plain re-clamp (viewport resize, IgnoreGuiInset change) must not start a loop,
	-- otherwise it would fire OnDragCompleted for a drag that never happened.
	const isActive = self._isActive
	if isActive or not self._position:IsAtRest() then
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
	self:_StartFrom(self._dragElement.AbsolutePosition)
end

-- Puts the start of a (new) drag at startObjectPos (absolute top-left corner of the element) and the current pointer
function DragElement._StartFrom(
	self : DragElement,
	startObjectPos : Vector2
)
	-- GetMouseLocation starts at the very top of the screen, absolute space starts below the TopBar
	const startMousePos = UIS:GetMouseLocation() - GuiS:GetGuiInset()

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

	const previouslyBlocked = self["_blocked"]
	self["_blocked"] = true

	if typeof(newDragElementPosition) == "UDim2" then
		self._dragElement.Position = newDragElementPosition
	else
		const mouseLocation = UIS:GetMouseLocation() - GuiS:GetGuiInset() - self:_GetParentOrigin()
		self._dragElement.Position = UDim2.fromOffset(mouseLocation.X, mouseLocation.Y)
	end

	self:_StartFrom(self._dragElement.AbsolutePosition)

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
    const connections = self._connections
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
				const function init()
					self:InitDrag(handle)
				end
				-- MouseButton1Down fires for touches too; TouchTap is not used, it never fired on a phone in testing
				table.insert(
                    connections,
                    handle.MouseButton1Down:Connect(init) -- For Desktop & Mobiles
                )
			end
		end
	elseif typeof(dragHandle) == "Instance" then
		assert(dragHandle:IsA("GuiButton"), "dragHandle MUST be a TextButton or an Imagebutton (or a GuiButton) Instance")

		const function init()
			self:InitDrag(dragHandle)
		end
		-- MouseButton1Down fires for touches too (see above why TouchTap is not used)
		table.insert(
            connections,
            dragHandle.MouseButton1Down:Connect(init) -- For Desktop & Mobiles
        )
	end
end

function DragElement.Destroy(self : DragElement)
	const connections = self._connections
	if not connections then return end -- already destroyed

	self._connections = nil -- IsDestroyed() is true from here on
	self._blocked = true    -- no more Reposition()
	self._isActive = false  -- an active drag is cancelled silently
	if LastDragElement == self then
		LastDragElement = NoDragElement
	end


	if self["_springConnection"] then
		self._springConnection:Disconnect()
		self._springConnection = nil
	end
	for _, connection in self._screenConnections do
		connection:Disconnect()
	end
	table.clear(self._screenConnections)

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

-- (Viewport resizes are handled per element by _AdjustScreenGui, through its ScreenGui's AbsoluteSize)



table.freeze(DragElement)

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

	const self = setmetatable({}, DragElement) :: DragElement

    const connections: {RBXScriptConnection} = {}
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
	--:Connect(function(offsetX : number, offsetY : number) --[[your code]]-- end)
	self.OnPositionChanged = Signal.new() :: Signal.Signal<number, number> -- fires on Reposition / UIS.InputChanged while used;

	--- Dynamic
	--self._init = init -- init (self:InitDrag()) shortcut for runtime added drag handles

	--- types compliance
	self._blocked = nil :: boolean?
	self._screenGui = nil :: ScreenGui?
	self._screenConnections = {} :: {RBXScriptConnection}
	self._anchorX = dragElement.AnchorPoint.X
	self._anchorY = dragElement.AnchorPoint.Y
	self._minInputX = 0
	self._maxInputX = 0
	self._minInputY = 0
	self._maxInputY = 0
    -- self._startMousePos = nil :: Vector2?
	-- self._startObjectPos = nil :: Vector2?
	self._springConnection = nil :: RBXScriptConnection?

    --self._startMousePos = Vector2.zero :: Vector2
	--self._startObjectPos = Vector2.zero :: Vector2

    -- NOTE: _startMousePos and _startObjectPos are intentionally NOT initialized here.
	-- They stay nil until the first drag/SetPosition, and :Reposition() relies on that
	-- to skip repositioning before the element was ever dragged.



	self:_AdjustScreenGui()
	table.insert(
        connections,
        -- AncestryChanged (not only Parent): moving an ancestor into another ScreenGui counts too
        dragElement.AncestryChanged:Connect(function()
            self:_AdjustScreenGui()
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

	return self
end