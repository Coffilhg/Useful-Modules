--[[--
    GUICompatibility V2.0.0
    Copyright © 2026 Coffilhg (Roblox UserId 517222346)

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/.

    GitHub Repository/Branch with latest version, documentation, etc:
    https://github.com/Coffilhg/Useful-Modules/tree/GUICompatibility
    Stars are appreciated!
--]]--

--!strict
--!optimize 2

local Players = game:GetService(`Players`)
local WS = game:GetService(`Workspace`)

--- Dependencies (By @Coffilhg) ---

-- Reaction's Source Repository: https://github.com/Coffilhg/Useful-Modules/tree/Reaction
local Reaction = require(`./Reaction`) -- or wherever it's located and whatever it's named
local V, O, rmV = Reaction.V, Reaction.O, Reaction.rmV

--- /E Dependencies (By @Coffilhg) ---

local player = Players.LocalPlayer :: Player
local camera = WS.CurrentCamera :: Camera
local PG = player.PlayerGui

-- Seconds after the last camera.ViewportSize change until everything is read (the GUI isn't laid out right away)
local UpdateDelay = 0.3



local someGUI = Instance.new("ScreenGui")
someGUI.Name = "AbsoluteSizeGUI"
someGUI.IgnoreGuiInset = true
someGUI.ClipToDeviceSafeArea = true
someGUI.SafeAreaCompatibility = Enum.SafeAreaCompatibility.FullscreenExtension
someGUI.ResetOnSpawn = false
someGUI.Parent = PG

local cloneGUI = someGUI:Clone()
cloneGUI.Name = `Cloned{someGUI.Name}`
cloneGUI.IgnoreGuiInset = false
cloneGUI.ResetOnSpawn = false
cloneGUI.Parent = someGUI.Parent

-- camera.ViewportSize is actually same as someGUI.AbsoluteSize



-- The size reserved by Roblox TopBar (in pixels / offset)
local GuiInsetSize: Reaction.V<number> = V(0)
local FullscreenAbsoluteSize: Reaction.V<Vector2> = V(camera.ViewportSize)
local SafeInsetsSize: Reaction.V<Vector2> = V(Vector2.zero)



--- Trackers ---
const TrackedProperties = {`AbsolutePosition`, `AbsoluteSize`, `ScreenInsets`}
local Tracker = {}
Tracker.__index = Tracker

export type Tracker<T> = typeof(setmetatable({} :: {
	ScreenGui: ScreenGui,
	Value: Reaction.V<T>,
	_unsee: Reaction.Ou,
}, Tracker))

type Tracked = {
	offset: Reaction.V<Vector2>,
	trackers: {Tracker<any>},
	connections: {RBXScriptConnection},
}
local TrackedScreenGuis: {[ScreenGui]: Tracked} = {}

local function updateTracked(screenGui: ScreenGui, tracked: Tracked)
	local offset = -screenGui.AbsolutePosition
	if offset == tracked.offset() then
		return
	end
	tracked.offset(offset)
end

local function untrack(screenGui: ScreenGui)
	local tracked = TrackedScreenGuis[screenGui]
	if not tracked then
		return
	end
	for _, tracker in table.clone(tracked.trackers) do
		tracker:Untrack()
	end
end

local function untrackTracker<T>(self: Tracker<T>, isDestroyed: boolean)
	local tracked = TrackedScreenGuis[self.ScreenGui]
	local index = tracked and table.find(tracked.trackers, self)
	if not tracked or not index then
		return
	end
	table.remove(tracked.trackers, index)
	self._unsee()

	if #tracked.trackers == 0 then
		TrackedScreenGuis[self.ScreenGui] = nil
		for _, connection in tracked.connections do
			connection:Disconnect()
		end
		rmV(tracked.offset)
	end

	if not isDestroyed then
		rmV(self.Value)
	end
end

-- Stops updating the tracker's Value and rmV's it; the ScreenGui's last tracker stops tracking the ScreenGui
function Tracker.Untrack<T>(self: Tracker<T>)
	untrackTracker(self, false)
end

function Tracker.IsTracking<T>(self: Tracker<T>): boolean
	local tracked = TrackedScreenGuis[self.ScreenGui]
	return tracked ~= nil and table.find(tracked.trackers, self) ~= nil
end

local function track<T>(screenGui: ScreenGui, isUDim2: boolean): (Reaction.V<T>, Tracker<T>)
	if typeof(screenGui) ~= `Instance` or not screenGui:IsA(`ScreenGui`) then
		error(`GUICompatibility:TrackInputOffset "screenGui" misinput: expected ScreenGui, got {screenGui} of type {typeof(screenGui)}`)
	end

	local tracked = TrackedScreenGuis[screenGui]
	if tracked then
		updateTracked(screenGui, tracked)
	else
		const newTracked: Tracked = {
			offset = V(-screenGui.AbsolutePosition),
			trackers = {},
			connections = {},
		}
		tracked = newTracked
		TrackedScreenGuis[screenGui] = newTracked

		const function update()
			updateTracked(screenGui, newTracked)
		end
		-- AbsolutePosition doesn't always fire on a device switch, the scheduled update covers that
		for _, propertyName in TrackedProperties do
			table.insert(newTracked.connections, screenGui:GetPropertyChangedSignal(propertyName):Connect(update))
		end
		table.insert(newTracked.connections, screenGui.Destroying:Connect(function()
			untrack(screenGui)
		end))
	end
	local trackedNow = tracked :: Tracked

	const initialValue = trackedNow.offset()
	local value = V(if isUDim2 then UDim2.fromOffset(initialValue.X, initialValue.Y) else initialValue)
	const unsee = O(
		trackedNow.offset,
		if isUDim2 then
			function(v: Vector2)
				value(UDim2.fromOffset(v.X, v.Y))
			end
			else
			function(v: Vector2)
				value(v)
			end
	)
	local tracker: Tracker<T> = setmetatable({
		ScreenGui = screenGui,
		Value = value,
		_unsee = unsee,
	}, Tracker)
	table.insert(trackedNow.trackers, tracker)

	-- rmV(tracker.Value) untracks the tracker too
	O(value :: any, function(_, isDestroyed)
		if isDestroyed then
			untrackTracker(tracker, true)
		end
	end)

	return value, tracker
end

--- /E Trackers ---



-- Returns the difference in size between DeviceSafeInsets vs None Safe Insets
local function getSafeInsetsSize(): Vector2
	someGUI.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	local safeSize = someGUI.AbsoluteSize
	someGUI.ScreenInsets = Enum.ScreenInsets.None
	local fullscreenSize = someGUI.AbsoluteSize
	local diff = fullscreenSize - safeSize
	return Vector2.new(math.abs(diff.X), math.abs(diff.Y))
end

local function updateAll()
	local newValue = math.abs(camera.ViewportSize.Y - cloneGUI.AbsoluteSize.Y)
	
	if GuiInsetSize() ~= newValue then
		GuiInsetSize(newValue)
	end
	
	if FullscreenAbsoluteSize() ~= camera.ViewportSize then
		FullscreenAbsoluteSize(camera.ViewportSize)
	end
	
	local safeInsetsSize = getSafeInsetsSize()
	if SafeInsetsSize() ~= safeInsetsSize then
		SafeInsetsSize(safeInsetsSize)
	end
	
	for screenGui, tracked in TrackedScreenGuis do
		updateTracked(screenGui, tracked)
	end
end

updateAll()
if not game:IsLoaded() then
	task.spawn(function()
		repeat
			task.wait()
		until game:IsLoaded()
		
		updateAll()
	end)
end


local ScheduledUpdate: thread? = nil
camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	if ScheduledUpdate then
		task.cancel(ScheduledUpdate)
	end
	ScheduledUpdate = task.delay(UpdateDelay, function()
		ScheduledUpdate = nil
		updateAll()
	end)
end)
--cloneGUI:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateAll)

local GUICompatibility = {}

-- This module has already loaded the game.Workspace.CurrentCamera - just take it from here!
function GUICompatibility.GetCamera(self: GUICompatibility)
	return camera
end

-- Returns a Reaction V of camera.ViewportSize
function GUICompatibility.GetFullscreenAbsoluteSize(self: GUICompatibility) : Reaction.V<Vector2>
	return FullscreenAbsoluteSize
end

-- Returns a Reaction V, call it to get the amount of pixels(offset), that the Roblox topbar takes: GuiInsetSize()
-- This should be used to get accurate position of players mouse, e.g.:
-- game:GetService("UserInputService"):GetMouseLocation() - Vector2.new(0, module:GetGuiInsetSize()())
-- this is mostly useful for ScreenGuis with IgnoreGuiInset property set to true
function GUICompatibility.GetGuiInsetSize(self: GUICompatibility) : Reaction.V<number>
	return GuiInsetSize --math.abs(someGUI.AbsoluteSize.Y - cloneGUI.AbsoluteSize.Y)
end

-- Updates everything provided by this module right away (instead of 0.3 seconds after the last camera.ViewportSize change)
function GUICompatibility.Update(self: GUICompatibility)
	updateAll()
end

-- Returns a Reaction V of the difference in size between DeviceSafeInsets vs None Safe Insets
-- This is useful for scaling Gui, that has to be accurately 100% of the screen width - just set it's Size property to UDim2.new(1, module:GetSafeInsetsSize()().X, 0.1, 0)
function GUICompatibility.GetSafeInsetsSize(self: GUICompatibility) : Reaction.V<Vector2>
	return SafeInsetsSize
end

-- Returns a new Reaction V of the offset to add to InputObject.Position, so a GuiObject parented to the screenGui lands under the pointer,
-- and its Tracker: local offset, tracker = module:TrackInputOffsetUDim2(screenGui)
-- pointer.Position = UDim2.fromOffset(input.Position.X, input.Position.Y) + offset()
-- tracker:Untrack(), rmV(offset), :UntrackInputOffset(screenGui) or screenGui.Destroying stop it
function GUICompatibility.TrackInputOffset(self: GUICompatibility, screenGui: ScreenGui): (Reaction.V<Vector2>, Tracker<Vector2>)
	return track<<Vector2>>(screenGui, false)
end

function GUICompatibility.TrackInputOffsetUDim2(self: GUICompatibility, screenGui: ScreenGui): (Reaction.V<UDim2>, Tracker<UDim2>)
	return track<<UDim2>>(screenGui, true)
end

-- Untracks every tracker of the screenGui
function GUICompatibility.UntrackInputOffset(self: GUICompatibility, screenGui: ScreenGui)
	untrack(screenGui)
end

function GUICompatibility.IsTracked(self: GUICompatibility, screenGui: ScreenGui): boolean
	return TrackedScreenGuis[screenGui] ~= nil
end

table.freeze(GUICompatibility)
export type GUICompatibility = typeof(GUICompatibility)
return GUICompatibility