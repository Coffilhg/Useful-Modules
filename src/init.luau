--[[--
    GreatUIButton V0.0.0
    Copyright © 2026 Coffilhg (Roblox UserId 517222346)

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/.

    GitHub Repository/Branch with latest version, documentation, etc:
    https://github.com/Coffilhg/Useful-Modules/tree/GreatUIButton
    Stars are appreciated!
--]]--
--!strict

local TS = game:GetService(`TweenService`)

-- local EnumUserInputTypeTouch = Enum.UserInputType.Touch -- unused
local LemonSignal = require(script.Parent.LemonSignal)
local DefaultTweenInfo : TweenInfo = TweenInfo.new(0.36, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0)
local LastUnhoverCallback : () -> () = function() end -- if a button is hovered on, that means all others are not hovered!

--export type AppearanceInput = ({
--	[string]: (any | AppearanceInput)?
--} & {
--	TweenInfo: TweenInfo,
--	Callback: ((Instance) -> ())?,
--})
export type AppearanceInput = ({
	TweenInfo: TweenInfo,
	Callback: ((Instance) -> ())?,
	[string]: (any | AppearanceInput)?,
})
export type AppearanceStructure = {
	Goal: {[string]: any}, -- Latest Goal used by BuildTweens
	GoalSize: number,
	Children: Children,
	TweenInfo: TweenInfo,
	Callback: ((Instance) -> ())?,
}
export type Children = {
	[Instance]: AppearanceStructure
}
export type SavedTweensStructure = {
	[AppearanceType]: AppearanceStructure,
}
export type InstanceTweenPairs = {
	[Instance]: Tween
}
export type InstanceCallbackPairs = { -- shall always be Weak-Keyed
	[Instance]: (Instance) -> ()
}
export type BuildTweens = {
	[AppearanceType]: InstanceTweenPairs
}
export type BuildCallbacks = {
	[AppearanceType]: InstanceCallbackPairs
}
export type AppearanceInputs = {[AppearanceType]: AppearanceInput}
export type UIButton = (TextButton | ImageButton | GuiButton)

--- AppearanceTypes
export type AppearanceType = "Default" | "Hover" | "Press" | "Disabled" | "Click" |
"!Default" | "!Hover" | "!Press" | "!Disabled" | "!Click"

local ValidAppearanceTypes : {[string]: AppearanceType} = {
	default = `Default`, -- default button state and looks
	hover = `Hover`, -- how button looks when MouseEnter or SelectionGained
	press = `Press`, -- how button looks when MouseButton1Down started
	disabled = `Disabled`, -- how button should look like when self.IsEventVisuallyResponsive = false
	click = `Click`, -- where button tweens to after a click detected via .Activated
	-- exclude (everything except the specified AppearanceType in `!{AppearanceType}`)
	[`!default`] = `!Default`, -- default button state and looks
	[`!hover`] = `!Hover`, -- how button looks when MouseEnter or SelectionGained
	[`!press`] = `!Press`, -- how button looks when MouseButton1Down started
	[`!disabled`] = `!Disabled`, -- how button should look like when self.IsEventVisuallyResponsive = false
	[`!click`] = `!Click`, -- where button tweens to after a click detected via .Activated
}
local DefaultAppearanceType : AppearanceType = `Default`
local function ResolveAppearanceType(v : AppearanceType?) : AppearanceType
	if type(v) ~= `string` then
		return DefaultAppearanceType
	end
	
	local appearanceType = ValidAppearanceTypes[v:lower()]
	if appearanceType then
		return appearanceType
	end

	return DefaultAppearanceType
end
local ExceptReturns : {[string]: {AppearanceType}} = {
	default = {
		`!Hover`,
		`!Press`,
		`!Disabled`,
		`!Click`,
	},
	hover = {
		`!Default`,
		`!Press`,
		`!Disabled`,
		`!Click`,
	},
	press = {
		`!Default`,
		`!Hover`,
		`!Disabled`,
		`!Click`,
	},
	disabled = {
		`!Default`,
		`!Hover`,
		`!Press`,
		`!Click`,
	},
	click = {
		`!Default`,
		`!Hover`,
		`!Press`,
		`!Disabled`,
	},
}
local function GetAllExcept(v : AppearanceType) : {AppearanceType}
	if type(v) ~= `string` then
		return {}
	end
	
	return ExceptReturns[v:lower()] or {}
end

--- TweenBaseMethods -- unused
-- export type TweenBaseMethod = "Cancel" | "Pause" | "Play"
-- local ValidTweenBaseMethods : {[string]: TweenBaseMethod} = {
-- 	cancel = `Cancel`,
-- 	pause = `Pause`,
-- 	play = `Play`,
-- }
-- local DefaultTweenBaseMethod : TweenBaseMethod = `Play`
-- local function ResolveTweenBaseMethod(v : TweenBaseMethod?) : TweenBaseMethod
-- 	if type(v) ~= `string` then
-- 		return DefaultTweenBaseMethod
-- 	end

-- 	local returnValue = ValidTweenBaseMethods[v:lower()]
-- 	if returnValue then
-- 		return returnValue
-- 	end

-- 	return DefaultTweenBaseMethod
-- end

--- IsPropertyAvailableForInstance

-- This function is not error proof, it exists solely to optimize memory usage for frequent calls of IsPropertyAvailableForInstance!
local function Instance_IsPropertyModified_PropertyName(instance: Instance, propertyName: string)
	return instance:IsPropertyModified(propertyName)
end

-- Check whether a property named <strong>propertyName</strong> exists for the given <strong>instance</strong>
local function IsPropertyAvailableForInstance(instance: Instance, propertyName: string) : boolean
	if type(propertyName) ~= `string` then
		error(`IsPropertyAvailableForInstance "propertyName" misinput: expected string, got {propertyName} of type {type(propertyName)}`)
	end
	if typeof(instance) ~= `Instance` then
		error(`IsPropertyAvailableForInstance "instance" misinput: expected Instance, got {instance} of typeof {typeof(instance)}`)
	end

	-- thanks to type casting, we can cut off all return values of a pcall except the isSuccess
	-- this means no need for temporary variables or unnecessary return values (error message)
	return pcall(Instance_IsPropertyModified_PropertyName, instance, propertyName) :: boolean 
end


--- GetChildByPathFromInstance
local function GetChildByPathFromInstance(instance: Instance, path: string): Instance?
	if type(path) ~= `string` then
		error(`GetChildByPathFromInstance "path" misinput: expected string, got {path} of type {type(path)}`)
	end
	if typeof(instance) ~= `Instance` then
		error(`GetChildByPathFromInstance "instance" misinput: expected Instance, got {instance} of typeof {typeof(instance)}`)
	end
	
	for _, name in ipairs(path:split(`.`)) do
		if not instance then
			break
		end
		instance = instance:FindFirstChild(name) :: Instance -- hide the strict and reuse the variable
	end
	
	return instance
end


local HitboxManager = {}
HitboxManager.__index = HitboxManager

export type HitboxManager = typeof(HitboxManager)

function HitboxManager.Disconnect(self : HitboxManager)
	for _, conn : RBXScriptConnection? in ipairs(self._Connections or {}) do
		if typeof(conn) ~= `RBXScriptConnection` then
			continue
		end
		
		conn:Disconnect()
	end
	
	self._Connections = nil :: ({[number] : RBXScriptConnection} | nil)
end

function HitboxManager.Reconnect(self : HitboxManager)
	-- cleanup before creating new
	if self._Connections then
		self:Disconnect()
	end
	
	-- abort if button was :Destroy()'ed
	local hitbox = self._Button
	if not hitbox then
		return
	end
	
	local connections : {[number] : RBXScriptConnection} = {}
	
	local greatUIButton = self._Subject
	local onHover = greatUIButton.OnHover
	local onUnhover = greatUIButton.OnUnhover
	local onPressStart = greatUIButton.OnPressStart
	local onPressEnd = greatUIButton.OnPressEnd
	local onClick = greatUIButton.OnClick
	
	-- local debouncePerApperanceType = greatUIButton.DebouncePerApperanceType -- unused
	
	-- Order of events when clicking on
	--
	-- Mobile	|	Desktop		|	Console (Or UI Navigation Toggle)
	-- started		enter?!			enter?!
	-- enter		started			started
	-- ended		ended			ended
	-- click		click			click
	-- leave		...leave		...leave
	--
	-- ! first click guarantees it will be fired
	-- ? optional 
	-- ... = can appear between any event or not appear at all
	--
	-- with this in mind we can have priorities for override
	
	-- click - highest priority, overrides all other events,
	-- any other events called must wait at least 0.3 seconds since
	-- the last click call before applying their own appearance
	-- click can override a previous click and reset the timer
	
	-- started and ended - middle priority - can override each other
	-- (whichever was called as the latest)
	
	-- enter and leave - lower priority - can only override each other
	-- (whichever was called as the latest)
	
	-- default - lowest, yet fundamental priority
	
	-- thought click shall be overridden by started
	
	-- no, actually. Let's have multiple internal states
	-- (fixing faulty fallback to default after each click)
	-- IsHovering, IsHolding (Pressing)
	-- if none of the above is true and click was complete
	-- fallback to default apperance
	
	
	
	local function leave() -- unhover
		--print("Leave")
		greatUIButton.isHovering = false
		greatUIButton:ApplyAppearance(--[[`Default`]])
		if greatUIButton.IsEventFiringEnabled then
			onUnhover:Fire(greatUIButton)
		end
	end
	local function enter() -- hover
		--print("Enter")
		greatUIButton.isHovering = true
		greatUIButton:ApplyAppearance(--[[`Hover`]])
		if greatUIButton.IsEventFiringEnabled then
			onHover:Fire(greatUIButton)
		end
		
		if LastUnhoverCallback ~= leave then
			LastUnhoverCallback()
			LastUnhoverCallback = leave
		end
	end
	
	local function started(x : number, y : number)
		--print("Started")
		greatUIButton.isHolding = true
		greatUIButton:ApplyAppearance(--[[`Press`]])
		if greatUIButton.IsEventFiringEnabled then
			onPressStart:Fire(greatUIButton, x, y)
		end
	end
	local function ended(x : number, y : number)
		--print("Ended")
		greatUIButton.isHolding = false
		greatUIButton:ApplyAppearance(--[[`Default`]])
		if greatUIButton.IsEventFiringEnabled then
			onPressEnd:Fire(greatUIButton, x, y)
		end
	end
	
	local function activated(inputObject : InputObject)
		--print("Click")
		greatUIButton:ApplyAppearance(`Click`)
		if greatUIButton.IsEventFiringEnabled then
			onClick:Fire(greatUIButton, inputObject)
		end
	end
	
	
	
	
	-- console hovers
	table.insert(connections, hitbox.SelectionGained:Connect(enter))
	table.insert(connections, hitbox.SelectionLost:Connect(leave))
	-- everything else hovers
	table.insert(connections, hitbox.MouseEnter:Connect(enter))
	table.insert(connections, hitbox.MouseLeave:Connect(leave))
	--- works for all devices
	-- click
	table.insert(connections, hitbox.Activated:Connect(activated))
	-- up/down
	table.insert(connections, hitbox.MouseButton1Down:Connect(started))
	table.insert(connections, hitbox.MouseButton1Up:Connect(ended))
	
	-- mobile
	--[[--
	table.insert(connections, hitbox.InputBegan:Connect(function(input : InputObject)
		if input.UserInputType == EnumUserInputTypeTouch then
			started()
		end
	end))
	table.insert(connections, hitbox.InputEnded:Connect(function(input : InputObject)
		if input.UserInputType == EnumUserInputTypeTouch then
			ended()
		end
	end))
	--]]--
	
	self._Connections = connections
end


function HitboxManager.new(
	subject : GreatUIButton,
	buttonHitbox : UIButton
) : HitboxManager
	local self = setmetatable({}, HitboxManager) :: HitboxManager
	
	self._Subject = subject
	self._Button = buttonHitbox
	self:Reconnect()
	
	return self
end


--- Class ---
local GreatUIButton = {}
GreatUIButton.__index = GreatUIButton

--- Types ---
export type GreatUIButton = typeof(GreatUIButton)

--- Methods ---



-- Fully internal for the purpose of safety (error-proofness),
-- AddHitbox Method does the validation first!
local function ConnectHitbox(
	self : GreatUIButton,
	buttonHitbox : UIButton
)
	-- do it safer tahn just self.Hitboxes[buttonHitbox] = HitboxManager.new(self, buttonHitbox)
	local hitboxes = self[`Hitboxes`]
	if type(hitboxes) ~= `table` then
		hitboxes = setmetatable({} :: {[UIButton]: HitboxManager}, {__index = function()
			return HitboxManager
		end,})
		self.Hitboxes = hitboxes
	end
	hitboxes[buttonHitbox] = HitboxManager.new(self, buttonHitbox)
end

function GreatUIButton.AddHitbox(
	self : GreatUIButton,
	buttonHitbox : ({UIButton} | UIButton)?
) : GreatUIButton
	if type(buttonHitbox) == "table" then
		for _, hitbox in pairs(buttonHitbox) do
			if typeof(hitbox) ~= "Instance" then
				continue
			end

			if hitbox:IsA("TextButton") or hitbox:IsA("ImageButton") then
				ConnectHitbox(self, hitbox)
			end
		end
		return self
	end
	if type(buttonHitbox) == "nil" then
		return self
	end
	if typeof(buttonHitbox) == "Instance" and 
		(buttonHitbox:IsA("TextButton") or buttonHitbox:IsA("ImageButton"))
	then
		ConnectHitbox(self, buttonHitbox)
		return self
	end
	
	warn("buttonHitbox MUST be any GuiObject Instance (e.g.: Frame, ImageLabel, ScrollingFrame, TextLabel, etc.)")
	return self
end

local function ConvertAppearanceInputToStructure(
	self : GreatUIButton,
	main : GuiObject | UIButton, -- self.Main (just faster access)
	subject : Instance,
	appearance : AppearanceInput
) : AppearanceStructure
	local goal = {}
	local children : Children = {}
	local goalSize = 0
	local result = {
		Goal = goal,
		Children = children,
		TweenInfo = appearance[`TweenInfo`] or DefaultTweenInfo,
	}
	
	for k, v in pairs(appearance) do
		if k == `TweenInfo` then
			continue
		end
		if type(v) == `table` then
			-- no property is a table, so we know this must be an appearance
			-- k is the path to child either
			--		absolute from self.Main + "path.to.child"
			--		relative from current subject + "path.to.child"
			-- we use simple k:split("."), that means you shall never have a child name contain a "." character!
			-- 
			-- this could be replaced with checking IsPropertyAvailableForInstance for all keys
			-- the current implementation is good too, kinda more predictable (syntax-oriented)
			if type(k) ~= `string` then
				-- invalid path format
				continue
			end

			local child = GetChildByPathFromInstance(subject, k) -- relative (from current table of appearance)
			if not child then
				child = GetChildByPathFromInstance(main, k) -- absolute
			end

			if child then
				children[child] = ConvertAppearanceInputToStructure(self, main, child, v)
			end

			continue
		end

		-- check if the property exists! And has the correct typeof value!
		if IsPropertyAvailableForInstance(subject, k) then
			local expectedTypeof = typeof((subject::any)[k]) -- any is here to nolint the message:
			-- `Attempting a dynamic property access on type '...' is unsafe and may cause exceptions at runtime`
			if typeof(v) ~= expectedTypeof then
				continue
			end

			goal[k] = v
			goalSize += 1
		end
	end
	
	self:_Track(main)
	
	result.GoalSize = goalSize
	result.Callback = appearance.Callback

	return result
end

local EmptyPlaceholderReadOnlyTable = table.freeze({})

local function RebuildTween(
	buildCache : InstanceTweenPairs, -- where to log the result?
	subject : GuiObject | UIButton | Instance, -- whats the key?
	currentAppearanceStructure : AppearanceStructure, -- where to find infos for creating the Tween?
	isWipedAlready : boolean? -- bother to check and cleanup at all?
)
	if not isWipedAlready then
		local tween : Tween = buildCache[subject]
		if typeof(tween) == `Instance` then
			tween:Destroy()
		end
	end
	
	local tween : Tween = TS:Create(
		subject,
		currentAppearanceStructure[`TweenInfo`] or DefaultTweenInfo,
		currentAppearanceStructure[`Goal`] or EmptyPlaceholderReadOnlyTable :: {[string]: any}
	)
	
	buildCache[subject] = tween
end

local function BuildTweensRecursively(
	buildCache : InstanceTweenPairs, -- the GreatUIButton (self) ._Build[AppearanceType] that is currently evaluated
	callbacksCache : InstanceCallbackPairs, -- for .Callback if any is provided within the currentAppearanceStructure : AppearanceStructure
	subject : GuiObject | UIButton | Instance, -- the subject
	currentAppearanceStructure : AppearanceStructure, -- subject appearance
	previousAppearanceStructure : AppearanceStructure? -- previous subject appearance
)
	if type(previousAppearanceStructure) ~= `table` then
		previousAppearanceStructure = EmptyPlaceholderReadOnlyTable :: AppearanceStructure -- nolint
	end
	-- handle children first
	local children = currentAppearanceStructure[`Children`]
	if type(children) == `table` then
		local prevChildren : Children = (previousAppearanceStructure :: AppearanceStructure)[`Children`] -- nolint
		if type(prevChildren) ~= `table` then
			prevChildren = EmptyPlaceholderReadOnlyTable :: Children -- nolint
		end


		for child, childAppearance in pairs(children) do
			local prevAppearance : AppearanceStructure? = prevChildren[child]

			BuildTweensRecursively(
				buildCache,
				callbacksCache,
				child,
				childAppearance,
				prevAppearance
			)
		end
	end
	
	
	-- add callback if any
	local callback = currentAppearanceStructure[`Callback`]
	if type(callback) == `function` then
		callbacksCache[subject] = callback
	end


	-- check whether the Goal of currentAppearanceStructure and previousAppearanceStructure is the same
	-- fast early-out before doing any value comparison
	if currentAppearanceStructure.GoalSize ~= (previousAppearanceStructure :: AppearanceStructure).GoalSize then -- nolint
		-- GoalSize makes it possible to avoid using pairs loop twice!
		-- (smarter way to detect if at least 1 key was removed/added between the two)
		-- rebuild
		RebuildTween(buildCache, subject, currentAppearanceStructure)
		return
	else
		local previousAppearanceStructureGoal = previousAppearanceStructure.Goal
		if type(previousAppearanceStructureGoal) ~= `table` then
			previousAppearanceStructureGoal = EmptyPlaceholderReadOnlyTable
		end
		
		local rebuildCalled = false
		for k, v in pairs(currentAppearanceStructure.Goal) do
			if previousAppearanceStructureGoal[k] ~= v then
				-- rebuild
				RebuildTween(buildCache, subject, currentAppearanceStructure)
				rebuildCalled = true
				break
			end
		end
		if rebuildCalled then
			return
		end
	end

	-- only rebuild if missing!
	local tween : Tween = buildCache[subject]
	if typeof(tween) ~= `Instance` or not tween:IsA(`Tween`) then
		RebuildTween(buildCache, subject, currentAppearanceStructure, true)
	end
end

function GreatUIButton.BuildTweens(
	self : GreatUIButton
) : GreatUIButton
	
	local build : BuildTweens = self[`_Build`]
	if type(build) ~= `table` then
		build = {}
		self._Build = build
	end
	local callbacks : BuildCallbacks = self[`_Callbacks`]
	if type(callbacks) ~= `table` then
		callbacks = {}
		self._Callbacks = callbacks
	end
	
	
	local apperanceInputs : AppearanceInputs = self[`_AppearanceInputs`]
	if type(apperanceInputs) ~= `table` then
		apperanceInputs = {}
		self._AppearanceInputs = apperanceInputs
		-- nothing inputted - do a cleanup
		for _ : AppearanceType, instanceTweenPairs : InstanceTweenPairs in pairs(build) do
			for _ : Instance, tween : Tween in pairs(instanceTweenPairs) do
				if typeof(tween) == `Instance` then
					tween:Destroy()
				end
			end
		end
		self._Tweens = {}
		table.clear(build)
		table.clear(callbacks)
		return self
	end
	
	local main = self.Main
	local savedTweens : SavedTweensStructure = self[`_Tweens`]
	if type(savedTweens) ~= `table` then
		savedTweens = {}
		self._Tweens = savedTweens
	end
	
	
	
	-- unchanged inputAppearanceTypes are left unchanged (those that received no input)
	for inputAppearanceType : AppearanceType, apperance : AppearanceInput in pairs(apperanceInputs) do
		-- before I continue writing the code, is it actually better to
		--		remove ProcessChildren entirely
		--		create a table specifically for the latest Goal Child written, removing Tween from it?
		--		create a table specifically for {[AppearanceType]: setmetatable<{[Instance]: Tween}, typeof(WeakKeysMetatable)>}
		--		change ApplyAppearance to simply call that new table, pretty mcuh almost an array and no recurive calls or additional validations, except making sure the tween is a tween
		-- ?
		
		-- the written above is what I did, exactly.
		local buildCache : InstanceTweenPairs = build[inputAppearanceType]
		if type(buildCache) ~= `table` then
			buildCache = {} :: InstanceTweenPairs -- nolint
			build[inputAppearanceType] = buildCache
		end
		
		local callbacksCache : InstanceCallbackPairs = callbacks[inputAppearanceType]
		if type(callbacksCache) ~= `table` then
			callbacksCache = {} :: InstanceCallbackPairs -- nolint
			callbacks[inputAppearanceType] = callbacksCache
		end
		
		
		local currentAppearanceStructure : AppearanceStructure = ConvertAppearanceInputToStructure(
			self,
			main,
			main,
			apperance
		)
		local previousAppearanceStructure : AppearanceStructure = savedTweens[inputAppearanceType]
		
		BuildTweensRecursively(
			buildCache,
			callbacksCache,
			main,
			currentAppearanceStructure,
			previousAppearanceStructure
		)
		
		savedTweens[inputAppearanceType] = currentAppearanceStructure
	end 
	
	table.clear(apperanceInputs)
	
	return self
end

function CallInstanceCallbacks(instanceCallbackPairs : InstanceCallbackPairs)
	if type(instanceCallbackPairs) ~= `table` then
		return
	end
	for instance : Instance, callback : ((Instance) -> ()) in pairs(instanceCallbackPairs) do
		callback(instance)
	end
end
function PlayInstanceTweenTable(tweensToPlay : InstanceTweenPairs)
	if type(tweensToPlay) ~= `table` then
		return
	end
	
	for _, tween : Tween in pairs(tweensToPlay) do
		if typeof(tween) ~= `Instance` or not tween:IsA(`Tween`) then
			continue
		end
		tween:Play()
	end
end

function GreatUIButton._PlayAppearance(
	self : GreatUIButton,
	appearanceType : AppearanceType
)
	self.CurrentState = appearanceType
	
	local callbacks : BuildCallbacks = self[`_Callbacks`]
	if type(callbacks) ~= `table` then
		callbacks = {}
		self._Callbacks = callbacks
	else
		CallInstanceCallbacks(callbacks[appearanceType])
	end
	
	
	local build = self[`_Build`]
	if type(build) ~= `table` then
		return
	end
	
	local allExceptCurrent : {AppearanceType} = GetAllExcept(appearanceType)
	for _, exceptAppearanceType in ipairs(allExceptCurrent) do
		CallInstanceCallbacks(callbacks[exceptAppearanceType])
		PlayInstanceTweenTable(build[exceptAppearanceType])
	end
	

	local tweensToPlay : InstanceTweenPairs = build[appearanceType]
	if type(tweensToPlay) ~= `table` then
		--warn(`GreatUIButton:_PlayAppearance({appearanceType}) has no Compiled Tweens to play!`)
		return
	end
	--[[
	-- looks like cancelling isnt necessary, as roblox handles it better themselves
	for buildAppearanceType : AppearanceType, instanceTweenPairs : InstanceTweenPairs in pairs(build) do
		if buildAppearanceType == appearanceType then
			--tweensToPlay = instanceTweenPairs
			continue
		end

		for instance, tween : Tween in pairs(instanceTweenPairs) do
			if not tweensToPlay[instance] then
				-- dont cancel if no override happens anyways!
				continue
			end
			if typeof(tween) ~= `Instance` or not tween:IsA(`Tween`) then
				continue
			end
			if CancelIgnoredPlaybackStates[tween.PlaybackState] then
				continue
			end
			tween:Cancel()
		end
	end
	--]]

	for _, tween : Tween in pairs(tweensToPlay) do
		if typeof(tween) ~= `Instance` or not tween:IsA(`Tween`) then
			continue
		end
		tween:Play()
	end

	self.DisplayedState = appearanceType
end

--[[
function GreatUIButton.ApplyAppearance(
	self : GreatUIButton,
	appearanceType : AppearanceType?
) : GreatUIButton
	appearanceType = ResolveAppearanceType(appearanceType) :: AppearanceType

	self.PendingState = appearanceType

	-- Disabled overrides everything visually, but doesn't change PendingState logic
	local visualType : AppearanceType = appearanceType
	if not self.IsEventVisuallyResponsive then
		visualType = `Disabled`
	end

	-- Priority gate: if a higher-priority state is currently locked (debouncing),
	-- park this as PendingState and let the debounce callback resolve it later
	local priorityMap = self[`_AppearanceTypePriority`]
	if type(priorityMap) ~= `table` then
		priorityMap = {}
		self._AppearanceTypePriority = priorityMap
	end
	local currentPriority = priorityMap[self.DisplayedState] or 0
	local incomingPriority = priorityMap[visualType] or 0

	local debounce = self.DebouncePerApperanceType[self.DisplayedState]
	local isDebounceActive = self._DebounceActive

	if isDebounceActive and debounce and incomingPriority < currentPriority then
		-- Lower priority tried to interrupt a debouncing state — park it, bail out
		return self
	end

	-- Cancel any existing debounce task
	if self.DebounceAwaitCancelCallback then
		self.DebounceAwaitCancelCallback()
		self.DebounceAwaitCancelCallback = nil
		self._DebounceActive = false
	end

	-- Actually play the tweens
	self:_PlayAppearance(visualType)

	-- If this state has a debounce, schedule resolution to PendingState after delay
	local debounceTime = self.DebouncePerApperanceType[visualType]
	if debounceTime and debounceTime > 0 then
		self._DebounceActive = true

		local cancelled = false
		self.DebounceAwaitCancelCallback = function()
			cancelled = true
		end

		task.delay(debounceTime, function()
			if cancelled then
				return
			end
			self._DebounceActive = false
			self.DebounceAwaitCancelCallback = nil

			-- Resolve to whatever state is currently pending
			-- (PendingState may have updated while we were waiting)
			self:ApplyAppearance(self.PendingState)
		end)
	end

	return self
end
--]]
local function EvaluateActiveAppearanceType(self: GreatUIButton) : AppearanceType
	if self.isHolding then
		return `Press`
	elseif self.isHovering then
		return `Hover`
	end
	return `Default`
end

function GreatUIButton.ApplyAppearance(
	self : GreatUIButton,
	appearanceType : AppearanceType?
) : GreatUIButton
	-- 1. If an explicit override is requested (like 'Click' or 'Disabled'), use it.
	-- Otherwise, evaluate the physical mouse/touch state context automatically.
	local targetAppearance: AppearanceType = appearanceType and ResolveAppearanceType(appearanceType)
		or EvaluateActiveAppearanceType(self)
	
	if not self.IsVisuallyResponsive then
		targetAppearance = `Disabled`
	end
	
	if self.DisplayedState == targetAppearance then
		-- already in the desired state
		return self
	end

	self.PendingState = targetAppearance

	-- Disabled overrides everything visually, but doesn't alter underlying PendingState logic
	--local visualType : AppearanceType = targetAppearance
	--if not self.IsVisuallyResponsive then
	--	visualType = `Disabled`
	--end

	local priorityMap = self[`_AppearanceTypePriority`]
	if type(priorityMap) ~= `table` then
		priorityMap = {}
		self._AppearanceTypePriority = priorityMap
	end

	local currentPriority = priorityMap[self.DisplayedState] or 0
	local incomingPriority = priorityMap[targetAppearance] or 0

	local debounce = self.DebouncePerApperanceType[self.DisplayedState]
	local isDebounceActive = self._DebounceActive

	if isDebounceActive and debounce and incomingPriority < currentPriority then
		-- Lower priority cannot interrupt an active higher priority debounce task
		return self
	end

	-- Cancel pending debounce tasks since we are clearing or overriding
	if type(self.DebounceAwaitCancelCallback) == `function` then
		(self.DebounceAwaitCancelCallback :: () -> ())() -- nolint
		self.DebounceAwaitCancelCallback = nil
		self._DebounceActive = false
	end

	-- Run compiled tweens/callbacks
	self:_PlayAppearance(targetAppearance)

	-- Handle debouncing states (like Click = 0.3s)
	local debounceTime = self.DebouncePerApperanceType[targetAppearance]
	if debounceTime and debounceTime > 0 then
		self._DebounceActive = true

		local cancelled = false
		self.DebounceAwaitCancelCallback = function()
			cancelled = true
		end

		task.delay(debounceTime, function()
			if cancelled then
				return
			end
			self._DebounceActive = false
			self.DebounceAwaitCancelCallback = nil

			-- CRITICAL FIX: Evaluate current truth state context after the debounce expires
			-- Instead of blind falling back to a cached PendingState, check if the player
			-- is still hovering/holding right now!
			self:ApplyAppearance(nil) 
		end)
	end

	return self
end



function GreatUIButton.SetAppearance(
	self : GreatUIButton,
	appearanceType : AppearanceType?,
	appearance : AppearanceInput?,
	isTweenBuilderEnabled : boolean?
) : GreatUIButton
	appearanceType = ResolveAppearanceType(appearanceType)
	
	local apperanceInputs : AppearanceInputs = self[`_AppearanceInputs`]
	if type(apperanceInputs) ~= `table` then
		apperanceInputs = {}
		self._AppearanceInputs = apperanceInputs
	end
	
	-- no validation, no nothing, this is literally a method to accelerate the apperances
	-- or clear them if the apperance is e.g. nil
	apperanceInputs[appearanceType] = appearance
	
	if isTweenBuilderEnabled then
		self:BuildTweens()
	end
	
	return self
end

function GreatUIButton.SetDebounce(
	self : GreatUIButton,
	appearanceType : AppearanceType,
	debounceTime : number?
) : GreatUIButton
	appearanceType = ResolveAppearanceType(appearanceType)
	if type(debounceTime) ~= `number` then
		debounceTime = nil
	end
	
	local debouncePerApperanceType = self[`DebouncePerApperanceType`]
	if type(debouncePerApperanceType) ~= `table` then
		debouncePerApperanceType = {}
		self.DebouncePerApperanceType = debouncePerApperanceType
	end
	
	debouncePerApperanceType[appearanceType] = debounceTime
	
	return self
end



function GreatUIButton.SetIsEventFiringEnabled(
	self : GreatUIButton,
	isEventFiringEnabled : boolean?
) : GreatUIButton
	self.IsEventFiringEnabled = not not isEventFiringEnabled
	
	return self
end

function GreatUIButton._Track(self: GreatUIButton, instance: Instance)
	local trackedInstances = self[`_TrackedInstances`]
	if type(trackedInstances) ~= `table` then
		trackedInstances = {}
		self._TrackedInstances = trackedInstances
	end
	
	
	if trackedInstances[instance] then
		-- already added
		return
	end

	trackedInstances[instance] = true

	-- Listen for when this specific object gets wiped from the game
	local connection: RBXScriptConnection
	connection = instance.Destroying:Connect(function()
		connection:Disconnect()
		trackedInstances[instance] = nil
		self:_Untrack(instance)
	end)
end

function GreatUIButton._Untrack(self: GreatUIButton, instance: Instance)
	-- 1. Remove the strong anchor reference
	--self._TrackedInstances[instance] = nil
	-- already in _Track so we dont need to re-access the self._TrackedInstances

	-- 2. Clean up compiled Tweens
	local build = self[`_Build`]
	if type(build) == `table` then
		for appearanceType, instanceTweenPairs in pairs(build) do
			local tween = instanceTweenPairs[instance]
			if typeof(tween) == "Instance" then
				tween:Destroy()
			end
			instanceTweenPairs[instance] = nil
		end
	end

	-- 3. Clean up Callbacks
	local callbacks = self[`_Callbacks`]
	if type(callbacks) == `table` then
		for appearanceType, callbackPairs in pairs(callbacks) do
			callbackPairs[instance] = nil
		end
	end

	-- 4. Clean up structural tracking data
	local tweens = self._Tweens
	if type(tweens) == `table` then
		for appearanceType, structure in pairs(tweens) do
			if type(structure) ~= `table` then
				continue
			end
			local children = structure[`Children`]
			if type(children) == `table` then
				children[instance] = nil
			end
		end
	end
end



return function(
	buttonElement : GuiObject | UIButton,
	buttonHitbox : ({UIButton} | UIButton)?,
	defaultAppearance : AppearanceInput?
) : GreatUIButton
	assert(buttonElement:IsA("GuiObject"), "buttonElement MUST be any GuiObject Instance (e.g.: Frame, ImageLabel, ScrollingFrame, TextLabel, etc.)")
	
	local self = setmetatable({}, GreatUIButton) :: GreatUIButton
	
	self.Main = buttonElement
	self.OnHover = LemonSignal.new() :: LemonSignal.Signal<GreatUIButton>
	self.OnUnhover = LemonSignal.new() :: LemonSignal.Signal<GreatUIButton>
	self.OnPressStart = LemonSignal.new() :: LemonSignal.Signal<GreatUIButton, number, number>
	self.OnPressEnd = LemonSignal.new() :: LemonSignal.Signal<GreatUIButton, number, number>
	self.OnClick = LemonSignal.new() :: LemonSignal.Signal<GreatUIButton, InputObject>
	-- whether the Signals (listed above) will be Fired
	self.IsEventFiringEnabled = true
	-- whether the UI is updated
	self.IsVisuallyResponsive = true
	
	self.CurrentState = `Default` :: AppearanceType -- current or previous "technically displayed" state
	self.DisplayedState = `Default` :: AppearanceType -- currently visually displayed state
	self.PendingState = `Default` :: AppearanceType -- current "technical" state; (the instant up to date one)
	-- e.g. CurrentState has changed to Click, now for the next 0.3s any new with a lower priority
	-- is pending and not applied instantly
	
	self.DebouncePerApperanceType = {} :: {[AppearanceType]: number}
	-- if an AppearanceType Debounce time is not specified, it is effectively 0
	self._DebounceActive = false
	
	self.DebounceAwaitCancelCallback = nil :: (() -> ())?
	-- cancel any delayed task that was awaiting

	self._AppearanceTypePriority = {
		Click    = 4,
		Press    = 3,
		Hover    = 2,
		Default  = 1,
		--Disabled = 0, -- handled separately, not priority-ranked
	} :: {[AppearanceType]: number}
	
	
	
	self._AppearanceInputs = {} :: AppearanceInputs -- inputs, cleared after each BuildTweens
	self._Tweens = {} :: SavedTweensStructure -- whatever was derived from inputs during the latest BuildTweens call
	-- is used to optimize future BuildTweens calls (e.g. Goal didn't change, so it wont Create a new Tween)
	self._Build = {} :: BuildTweens -- output of the BuildTweens to be used by ApplyAppearance
	-- can also be referred to as "CompiledTweens"
	self._Callbacks = {} :: BuildCallbacks
	
	self._TrackedInstances = {} :: {[Instance]: true}
	self.isHovering = false
	self.isHolding = false
	
	
	
	self.Hitboxes = setmetatable(
		{} :: {[UIButton]: HitboxManager},
		{
			--__mode = `k`,
			__index = function()
				return HitboxManager
			end,
		}
	)
	self:AddHitbox(buttonHitbox)
	self:SetAppearance(`Default`, defaultAppearance)
	self:ApplyAppearance(`Default`)
	
	
	
	return self
end