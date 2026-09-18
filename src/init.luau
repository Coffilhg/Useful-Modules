--[[--
    EasySmoothDamp V1.0.4
    Copyright © 2026 Coffilhg (Roblox UserId 517222346)

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/.

    GitHub Repository/Branch with latest version, documentation, etc:
    https://github.com/Coffilhg/Useful-Modules/tree/EasySmoothDamp
    Stars are appreciated!
--]]--
--!strict

local TS = game:GetService(`TweenService`)

local EPSILONDEFAULT = 1e-3
-- EPSILON must be <= 0.1 as per the FuzzyEq error: "The eps value provided to FuzzyEq should be a small positive value <= 0.1"
local EPSILON: number = math.min(math.abs(EPSILONDEFAULT), 0.1)

local Vector2Zero = Vector2.zero
local Vector3Zero = Vector3.zero
local CFrameIdentity = CFrame.identity

local Vector2FuzzyEq = Vector2Zero.FuzzyEq
local Vector3FuzzyEq = Vector3Zero.FuzzyEq
local CFrameFuzzyEq = CFrameIdentity.FuzzyEq

local IsFinishedCallbacks = {
	["number"] = function(self: SmoothDamper<number>)
		return math.abs(self.CurrentValue - self.CurrentGoal) < EPSILON
			and math.abs(self.CurrentSpeed) < EPSILON
	end,
	["Vector2"] = function(self: SmoothDamper<Vector2>)
		return Vector2FuzzyEq(self.CurrentValue, self.CurrentGoal, EPSILON)
			and Vector2FuzzyEq(self.CurrentSpeed, Vector2Zero, EPSILON)
	end,
	["Vector3"] = function(self: SmoothDamper<Vector3>)
		return Vector3FuzzyEq(self.CurrentValue, self.CurrentGoal, EPSILON)
			and Vector3FuzzyEq(self.CurrentSpeed, Vector3Zero, EPSILON)
	end,
	["CFrame"] = function(self: SmoothDamper<CFrame>)
		return CFrameFuzzyEq(self.CurrentValue, self.CurrentGoal, EPSILON)
			and CFrameFuzzyEq(self.CurrentSpeed, CFrameIdentity, EPSILON)
	end,
}
local CurrentSpeedDefaults = {
	["number"] = 0,
	["Vector2"] = Vector2Zero,
	["Vector3"] = Vector3Zero,
	["CFrame"] = CFrameIdentity,
}
export type SmoothDampSupported = number | Vector2 | Vector3 | CFrame
export type SmoothDamper<T = SmoothDampSupported> = {
	CurrentValue : T,
	CurrentGoal : T,
	CurrentSpeed : T,
	SmoothTime : number,
	MaxSpeed : number,
	_LastUpdateTime : number,
	--_InitialType : "number" | "Vector2" | "Vector3" | "CFrame",
	IsReturnIsFinishedStateOnUpdateEnabled : boolean,
	IsFinished : (self : SmoothDamper<T>) -> (boolean),
	Update : (self : SmoothDamper<T>, deltaTime : number?) -> (T, boolean?),
	ResetInternalTime : (self : SmoothDamper<T>) -> (),
	_CurrentValue : T,
	_CurrentGoal : T,
	_CurrentSpeed : T,
	_SmoothTime : number,
	_MaxSpeed : number,
	_IsReturnIsFinishedStateOnUpdateEnabled : boolean,
}
local SmoothDamperMetatable = {}
function SmoothDamperMetatable.Update(self: SmoothDamper, deltaTime : number?)
	local now = time()
	deltaTime = type(deltaTime) == "number" and deltaTime or now - self._LastUpdateTime

	self._LastUpdateTime = now

	local currentValue, currentSpeed = TS:SmoothDamp(
		self._CurrentValue,
		self._CurrentGoal,
		self._CurrentSpeed,
		self._SmoothTime,
		self._MaxSpeed,
		deltaTime
	)

	self._CurrentValue, self._CurrentSpeed = currentValue, currentSpeed

	if self._IsReturnIsFinishedStateOnUpdateEnabled then
		return currentValue, self:IsFinished()
	end

	return currentValue
end
function SmoothDamperMetatable.ResetInternalTime(self: SmoothDamper)
	self._LastUpdateTime = time()
end
function SmoothDamperMetatable:__index(key : string)
	if type(key) ~= "string" then
		return nil
	end

	local underscoreKey = `_{key}`

	return rawget(self :: any, underscoreKey) or SmoothDamperMetatable[key]
end
function SmoothDamperMetatable:__newindex(key, value)
	if type(key) ~= "string" then
		return
	end

	local underscoreKey = `_{key}`

	if key == "CurrentValue" or key == "CurrentGoal" or key == "CurrentSpeed" then
		if typeof(self[underscoreKey]) ~= typeof(value) then
			warn(`Can not dynamically adjust Smooth Damp type!`)
			return
		end

		rawset(self, underscoreKey, value)
		return
	end

	if key == "SmoothTime" or key == "MaxSpeed" then
		if type(value) ~= "number" then
			warn(`[{key}] must be a number!`)
			return
		end

		rawset(self, underscoreKey, value)
		return
	end

	if key == "IsReturnIsFinishedStateOnUpdateEnabled" then
		rawset(self :: any, underscoreKey, not not value) -- ensures a boolean
		return
	end

	--if type(self[underscoreKey]) ~= nil then
	--	warn(`[{key}] is read/use only!`)
	--end
end



local EasySmoothDamp = {}
export type EasySmoothDamp = typeof(EasySmoothDamp)

function EasySmoothDamp.new<T>(
	CurrentValue : T & SmoothDampSupported,
	CurrentGoal : T & SmoothDampSupported,
	CurrentSpeed : (T & SmoothDampSupported)?,
	SmoothTime : number?,
	MaxSpeed : number?
) : SmoothDamper<T>
	local typeofCurrentValue = typeof(CurrentValue)

	local isFinishedCallback = IsFinishedCallbacks[typeofCurrentValue]
	local currentSpeedDefault = CurrentSpeedDefaults[typeofCurrentValue]

	if not (isFinishedCallback and currentSpeedDefault) then
		error(`Expected one of the supported types, got: {typeofCurrentValue}`, 2)
	end
	if typeofCurrentValue ~= typeof(CurrentGoal) then
		error(`Type mismatch: typeof(CurrentValue) must be equal to typeof(CurrentGoal)`, 2)
	end
	if typeofCurrentValue ~= typeof(CurrentSpeed) then
		CurrentSpeed = currentSpeedDefault
	end

	local self = setmetatable({
		_CurrentValue = CurrentValue,
		_CurrentGoal = CurrentGoal or CurrentValue,
		_CurrentSpeed = CurrentSpeed,
		_SmoothTime = type(SmoothTime) == "number" and SmoothTime or 0.3,
		_MaxSpeed = type(MaxSpeed) == "number" and MaxSpeed or 100,
		_LastUpdateTime = time(),
		--_InitialType = typeofCurrentValue,
		_IsReturnIsFinishedStateOnUpdateEnabled = true,
		IsFinished = isFinishedCallback,
	}, SmoothDamperMetatable) :: SmoothDamper<T>

	return self
end

-- Default EPSILON is 1e-3 (0.001)
-- type newEPSILONValue ~= number -> EPSILON is set to the default
-- otherwise EPSILON is set to min(|newEPSILONValue|, 0.1)
-- 0 (zero) is a valid input, but it is generally recommended to use a value greater than zero
function EasySmoothDamp.SetEPSILON(newEPSILONValue : number?)
	EPSILON = math.min(
		math.abs(
			type(newEPSILONValue) == "number" and newEPSILONValue or EPSILONDEFAULT
		),
		0.1
	)
end

return EasySmoothDamp