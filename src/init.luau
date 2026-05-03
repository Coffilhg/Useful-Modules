--[[--
    Quick Start and API can be found at
    https://github.com/Coffilhg/Useful-Modules/tree/EasySmoothDamp

    EasySmoothDamp
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

    Full License & Notices: https://github.com/Coffilhg/Useful-Modules/tree/EasySmoothDamp
    Module Version: 1.0.0
--]]--
--!strict

local TS = game:GetService(`TweenService`)

local EPSILONDEFAULT = 1e-3
local EPSILON: number = EPSILONDEFAULT



local IsFinishedCallbacks = {
	["number"] = function(self: SmoothDamper<number>)
		return math.abs(self.CurrentValue - self.CurrentGoal) < EPSILON
			and math.abs(self.CurrentSpeed) < EPSILON
	end,
	["Vector2"] = function(self: SmoothDamper<Vector2>)
		return (self.CurrentValue - self.CurrentGoal).Magnitude < EPSILON
			and self.CurrentSpeed.Magnitude < EPSILON
	end,
	["Vector3"] = function(self: SmoothDamper<Vector3>)
		return (self.CurrentValue - self.CurrentGoal).Magnitude < EPSILON
			and self.CurrentSpeed.Magnitude < EPSILON
	end,
	["CFrame"] = function(self: SmoothDamper<CFrame>)
		local posDist = (self.CurrentValue.Position - self.CurrentGoal.Position).Magnitude
		local _, angle = (self.CurrentValue:ToObjectSpace(self.CurrentGoal)):ToAxisAngle()

		local linVel = self.CurrentSpeed.Position.Magnitude
		local _, angVel = self.CurrentSpeed:ToAxisAngle()

		return posDist < EPSILON 
			and math.abs(angle) < EPSILON 
			and linVel < EPSILON 
			and math.abs(angVel) < EPSILON
	end,
}
local CurrentSpeedDefaults = {
	["number"] = 0,
	["Vector2"] = Vector2.zero,
	["Vector3"] = Vector3.zero,
	["CFrame"] = CFrame.identity,
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
function SmoothDamperMetatable:Update(deltaTime : number?)
	local now = time()
	deltaTime = type(deltaTime) == "number" and deltaTime or now - self._LastUpdateTime :: number

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
function SmoothDamperMetatable:ResetInternalTime()
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
function EasySmoothDamp.SetEPSILON(newEPSILONValue : number?)
	EPSILON = type(newEPSILONValue) == "number" and newEPSILONValue or EPSILONDEFAULT
end

return EasySmoothDamp