--[[--
    Quick Start and API can be found at
    https://github.com/Coffilhg/Useful-Modules/tree/FirstPersonDetector

    FirstPersonDetector
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

    Full License & Notices: https://github.com/Coffilhg/Useful-Modules/tree/FirstPersonDetector
    Module Version: 1.0.0
--]]--
--!strict

local RunS = game:GetService(`RunService`)
local Players = game:GetService(`Players`)
local WS = game:GetService(`Workspace`)
local Signal = require(script.Parent.PerfectSignal)

local HumanoidCameraOffsetController = require(script.Parent.HumanoidCameraOffsetController)



local player = Players.LocalPlayer :: Player
local camera = WS.CurrentCamera :: Camera

local character : Model = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild(`Humanoid`) :: Humanoid
local HRP = character:WaitForChild(`HumanoidRootPart`) :: Part?

local IsDead : boolean = false
local IsInFirstPersonView : boolean = false
local OnChange : Signal.Signal<boolean> = Signal.new()



-- 0.5 is the base, however there is a small Epsilon so
-- the distance in first person to HRP is a bit more than 0.5
-- huge Epsilon of 0.1 makes the module feel much more instant
local FirstPersonEnterMinDistance : number = 0.5 + 0.1

local ChangeDetectionThreshold : number = 0
local ChangeDetectedStart : number? = nil

local RunServiceDefaultRenderPriority : number = Enum.RenderPriority.Last.Value + 3
local RunServiceRenderPriority : number = RunServiceDefaultRenderPriority
local RunServiceRenderStepName : string = `FirstPersonDetector`

local DebugEnabled : boolean = false



local function ConnectHumanoid()
	--print(player.Name, "Humanoid Connected")
	humanoid.Died:Once(function()
		--print(player.Name, "Died")
		IsDead = true
		HRP = nil
	end)
end
ConnectHumanoid()

player.CharacterAdded:Connect(function(respawnedCharacter : Model)
	character = respawnedCharacter

	humanoid = character:WaitForChild(`Humanoid`) :: Humanoid
	ConnectHumanoid()

	HRP = character:WaitForChild(`HumanoidRootPart`) :: Part?

	IsDead = false
	--print(player.Name, "Revived and retrieved allthat")
end)

local FirstPersonDetector = {
	OnPersonViewChanged = OnChange,
	IsInFirstPersonView = false :: boolean,
}
export type FirstPersonDetector = typeof(FirstPersonDetector)

-- debug piece #1
local DebugPart : Part? = nil


local function Update() : nil | any | CFrame
	if IsDead then
		return
	end
	if not HRP then
		return
	end

	local offsetVector3RelativeToHead : Vector3 = HumanoidCameraOffsetController:GetCameraOffset()

	-- the idea is to count distance between HumanoidRootPart and Camera; but as if Camera was 1.5 studs down.
	-- however camera has an offset (offsetVector3RelativeToHead) so
	-- you have to revert offsetVector3RelativeToHead; Basically doing camera - offsetVector3RelativeToHead
	-- then we also have that our animations offset our head, but at least HRP stays in the center
	-- so we compare to HRP
	-- that shall be `camera - offsetVector3RelativeToHead + 0, -1.5, 0`

	local cameraWithoutOffset = camera.CFrame * CFrame.new(offsetVector3RelativeToHead):Inverse()
	local effectiveCamCFrame = CFrame.new(cameraWithoutOffset.Position + Vector3.new(0, -1.5, 0))

	local distance = (HRP.Position - effectiveCamCFrame.Position).Magnitude
	--print(string.format("%.3f", distance))
	local isInFirstPersonView = distance < FirstPersonEnterMinDistance
	--print("First Person =", isInFirstPersonView)

	if isInFirstPersonView == IsInFirstPersonView then
		ChangeDetectedStart = nil
		return effectiveCamCFrame
	end
	
	
	-- do not bother doing the checks if ChangeDetectionThreshold is 0 or negative
	if ChangeDetectionThreshold > 0 then
		local now = time()
		
		if not ChangeDetectedStart then
			-- first iteration detecting a change
			ChangeDetectedStart = now
			return effectiveCamCFrame
		end

		if now - ChangeDetectedStart < ChangeDetectionThreshold then -- 		(below threshold)
			-- one of the iterations after the initial detection, but not enough time has passed
			return effectiveCamCFrame
		end
	end

	IsInFirstPersonView = isInFirstPersonView
	FirstPersonDetector.IsInFirstPersonView = isInFirstPersonView
	OnChange:Fire(isInFirstPersonView)
	
	return effectiveCamCFrame
end

local function DebugUpdate()
	if not DebugPart then
		warn(`Debug Part does not exist; Maybe something is broken.`)
		return
	end
	
	local effectiveCamCFrame = Update()

	if not effectiveCamCFrame then
		return
	end
	
	-- debug piece #2
	DebugPart.CFrame = effectiveCamCFrame
end

local function RenderPriorityOrDebugEnabledChanged()
	RunS:UnbindFromRenderStep(RunServiceRenderStepName)
	
	if DebugEnabled then
		if not DebugPart then
			local DebugPartInstance = Instance.new("Part")
			DebugPartInstance.Anchored = true
			DebugPartInstance.CanCollide = false
			DebugPartInstance.Size = Vector3.new(1, 1, 1)
			DebugPartInstance.Shape = Enum.PartType.Ball
			DebugPartInstance.Color = Color3.fromRGB(255, 60, 60)
			DebugPartInstance.Parent = WS

			Instance.new("Highlight", DebugPartInstance).DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			
			DebugPart = DebugPartInstance
		end
		RunS:BindToRenderStep(RunServiceRenderStepName, RunServiceRenderPriority, DebugUpdate)
	else
		if DebugPart then
			DebugPart:Destroy()
		end
		RunS:BindToRenderStep(RunServiceRenderStepName, RunServiceRenderPriority, Update)
	end
end



-- defaults to RunServiceDefaultRenderPriority (Enum.RenderPriority.Last.Value + 3)
function FirstPersonDetector.SetRenderPriority(
	self : FirstPersonDetector,
	runServiceRenderPriority : number?
)
	
	if type(runServiceRenderPriority) ~= `number` then
		runServiceRenderPriority = RunServiceDefaultRenderPriority
	end
	
	if runServiceRenderPriority == RunServiceRenderPriority then
		-- no need for an update (re-initializing the loop)
		return
	end
	
	RunServiceRenderPriority = runServiceRenderPriority :: number
	RenderPriorityOrDebugEnabledChanged()
end

-- defaults to false
function FirstPersonDetector.SetDebugEnabled(
	self : FirstPersonDetector,
	isDebugEnabled : boolean?
)

	isDebugEnabled = not not isDebugEnabled -- convert to boolean

	if isDebugEnabled == DebugEnabled then
		-- no need for an update (re-initializing the loop)
		return
	end

	DebugEnabled = isDebugEnabled
	RenderPriorityOrDebugEnabledChanged()
end

-- defaults to 0
function FirstPersonDetector.SetChangeDetectionThreshold(
	self : FirstPersonDetector,
	changeDetectionThreshold : number?
)
	if type(changeDetectionThreshold) ~= `number` then
		changeDetectionThreshold = 0
	end

	ChangeDetectionThreshold = changeDetectionThreshold :: number
end

-- defaults to 0.5 + 0.1
function FirstPersonDetector.SetFirstPersonEnterMinDistance(
	self : FirstPersonDetector,
	firstPersonEnterMinDistance : number?
)
	if type(firstPersonEnterMinDistance) ~= `number` then
		firstPersonEnterMinDistance = 0.5 + 0.1
	end

	FirstPersonEnterMinDistance = firstPersonEnterMinDistance :: number
end

RenderPriorityOrDebugEnabledChanged() -- init

return FirstPersonDetector