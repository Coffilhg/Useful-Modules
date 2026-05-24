--[[--
    Quick Start and API can be found at
    https://github.com/Coffilhg/Useful-Modules/tree/HumanoidCameraOffsetController

    HumanoidCameraOffsetController
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

    Full License & Notices: https://github.com/Coffilhg/Useful-Modules/tree/HumanoidCameraOffsetController
    Module Version: 1.0.1
--]]--
--!strict

local RunS = game:GetService(`RunService`)
local Players = game:GetService(`Players`)

--- Dependencies ---

-- EasySmoothDamp Source Repository: https://github.com/Coffilhg/Useful-Modules/tree/EasySmoothDamp
local EasySmoothDamp = require(script.Parent.EasySmoothDamp) -- or wherever it's located and whatever it's named

--- /E Dependencies ---

local player = Players.LocalPlayer :: Player
local Vector3Zero : Vector3 = Vector3.zero

local character : Model = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild(`Humanoid`) :: Humanoid

local IsDead : boolean = false
local CameraOffsetDamper : EasySmoothDamp.SmoothDamper<Vector3> = EasySmoothDamp.new(Vector3Zero, Vector3Zero, nil, 0.36, 12)
local Connection : RBXScriptConnection?

-- Disconnect the RunService connection.
local function Cleanup()
	if typeof(Connection) == "RBXScriptConnection" and Connection.Connected then
		Connection:Disconnect()
	end
end

local function UpdateCameraOffset(dt : number)
	if IsDead or not humanoid then
		return
	end
	
	local currentOffset, isFinished = CameraOffsetDamper:Update(dt)
	humanoid.CameraOffset = currentOffset
	
	if isFinished then
		Cleanup()
	end
end

-- Connect to RunService.PreRender for updating the CameraOffset
-- Automatically stops once the goal CameraOffset is reached!
-- Calls the Stop() before connecting.
local function Start()
	Cleanup()
	Connection = RunS.PreRender:Connect(UpdateCameraOffset)
end


local function ConnectHumanoid()
	humanoid.Died:Once(function()
		IsDead = true
	end)
end
ConnectHumanoid()

player.CharacterAdded:Connect(function(respawnedCharacter : Model)
	character = respawnedCharacter

	humanoid = character:WaitForChild(`Humanoid`) :: Humanoid
	ConnectHumanoid()

	IsDead = false
	Start()
	--print(player.Name, "Revived and retrieved allthat")
end)








local HumanoidCameraOffsetController = {
	Damper = CameraOffsetDamper,
	Start = Start,
	Stop = Cleanup,
}
export type HumanoidCameraOffsetController = typeof(HumanoidCameraOffsetController)



function HumanoidCameraOffsetController.SetCameraOffset(
	self : HumanoidCameraOffsetController,
	cameraOffset : Vector3?
)
	if type(cameraOffset) ~= `nil` and typeof(cameraOffset) ~= `Vector3` then
		warn(`cameraOffset must be a Vector3 or nil!`)
		return
	end
	--print("New goal:", cameraOffset)
	
	CameraOffsetDamper.CurrentGoal = cameraOffset or Vector3Zero
	Start()
end

function HumanoidCameraOffsetController.GetCameraOffset(self : HumanoidCameraOffsetController) : Vector3
	return CameraOffsetDamper.CurrentValue
end

return HumanoidCameraOffsetController