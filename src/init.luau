--[[--
    FirstPersonView V1.0.0
    Copyright © 2026 Coffilhg (Roblox UserId 517222346)

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/.

    GitHub Repository/Branch with latest version, documentation, etc:
    https://github.com/Coffilhg/Useful-Modules/tree/FirstPersonView
    Stars are appreciated!
--]]--
--!strict

local Players = game:GetService(`Players`)
local RunS = game:GetService(`RunService`)

local FirstPersonDetector = require(script.Parent.FirstPersonDetector)
local HumanoidCameraOffsetController = require(script.Parent.HumanoidCameraOffsetController)

--- Constants / Runtime Variables
local player = Players.LocalPlayer :: Player

local character : Model = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild(`Humanoid`) :: Humanoid

local IsDead : boolean = false
local ChildAddedConnection : RBXScriptConnection?



local RunServiceRenderStepNameForLTMChanges : string = "FirstPersonView"

--- Customizable Settings (with defaults)
local WhitelistedChildrenBasePartNames = {
	["Left Arm"] = true,
	["Left Leg"] = true,
	["Right Arm"] = true,
	["Right Leg"] = true,
}
local LTMRenderPriority : number = Enum.RenderPriority.Last.Value + 1
local FirstPersonHumanoidCameraOffset : Vector3? = Vector3.new(0, 0, -0.3)
local ThirdPersonHumanoidCameraOffset : Vector3? = Vector3.zero

local Whitelist : {BasePart} = {}

local function ApplyLTM()
	for _, basePart in ipairs(Whitelist) do
		basePart.LocalTransparencyModifier = 0
	end
end

local function Reconnect(isInFirstPersonView : boolean)
    RunS:UnbindFromRenderStep(RunServiceRenderStepNameForLTMChanges)

    if isInFirstPersonView then
		-- Priority > Last (1000) so this runs AFTER Roblox's first-person LTM system.
		-- Roblox sets LTM=1 on all body parts when zoomed in; we undo that for
		-- everything except the head, so arms/legs/torso stay visible.
		RunS:BindToRenderStep(RunServiceRenderStepNameForLTMChanges, LTMRenderPriority, ApplyLTM)
		
        if typeof(FirstPersonHumanoidCameraOffset) ~= `Vector3` then
            return
        end
		HumanoidCameraOffsetController:SetCameraOffset(FirstPersonHumanoidCameraOffset)
		return
	end
	
	-- Reset camera offset if enabled
    if typeof(ThirdPersonHumanoidCameraOffset) ~= `Vector3` then
        return
    end
    HumanoidCameraOffsetController:SetCameraOffset(ThirdPersonHumanoidCameraOffset)
end
FirstPersonDetector.OnPersonViewChanged:Connect(Reconnect)



local function AddToWhitelistIfEligible(child : Instance)
	if IsDead then
		return
	end
	
	if child:IsA("BasePart") and WhitelistedChildrenBasePartNames[child.Name] then
		table.insert(Whitelist, child)
	end
end

local function ConnectHumanoid()
	--print(player.Name, "Humanoid Connected")
	humanoid.Died:Once(function()
		--print(player.Name, "Died")
		IsDead = true
		Whitelist = {}
	end)
end
ConnectHumanoid()

local function CatchCharacterChildren()
	if typeof(ChildAddedConnection) == "RBXScriptConnection" and ChildAddedConnection.Connected then
		ChildAddedConnection:Disconnect()
	end
	for _, c in ipairs(character:GetChildren()) do
		AddToWhitelistIfEligible(c)
	end
	ChildAddedConnection = character.ChildAdded:Connect(AddToWhitelistIfEligible)
end
CatchCharacterChildren()

player.CharacterAdded:Connect(function(respawnedCharacter : Model)
	character = respawnedCharacter

	humanoid = character:WaitForChild(`Humanoid`) :: Humanoid
	ConnectHumanoid()

	IsDead = false
	CatchCharacterChildren()
	--print(player.Name, "Revived and retrieved allthat")
end)






--- Module Settings API
local ModuleSettings = {} :: ModuleSettings
export type ModuleSettings = {
	["LTMSettings"]: LTMSettings,
	["CameraSettings"]: CameraSettings,
}

local LTMSettings = {}
export type LTMSettings = typeof(LTMSettings)

--- LTM means LocalTransparencyModifier
--- Sets which body parts should be visible in first person view
--- Defaults to {["Left Arm"] = true, ["Left Leg"] = true, ["Right Arm"] = true, ["Right Leg"] = true}
--- Applies immediately by rescanning character children for whitelisted parts
function LTMSettings.SetWhitelistedParts(
	self : LTMSettings,
	whitelistedParts : {[string]: boolean}?
) : ModuleSettings
	if typeof(whitelistedParts) ~= "table" then
		whitelistedParts = {
			["Left Arm"] = true,
			["Left Leg"] = true,
			["Right Arm"] = true,
			["Right Leg"] = true,
		}
	end
	WhitelistedChildrenBasePartNames = whitelistedParts :: {[string]: boolean}
    if not IsDead then
        CatchCharacterChildren()
    end
	
	return ModuleSettings
end

--- Sets the render priority for LocalTransparencyModifier updates
--- Defaults to Enum.RenderPriority.Last.Value + 1
--- Applies immediately by reconnecting the render step with the new priority
function LTMSettings.SetRenderPriority(
	self : LTMSettings,
	renderPriority : number?
) : ModuleSettings
	if type(renderPriority) ~= "number" then
		renderPriority = Enum.RenderPriority.Last.Value + 1
	end
    if renderPriority == LTMRenderPriority then
        return ModuleSettings
    end
	LTMRenderPriority = renderPriority :: number

    Reconnect(FirstPersonDetector.IsInFirstPersonView)
	
	return ModuleSettings
end

local CameraSettings = {}
export type CameraSettings = typeof(CameraSettings)

--- Sets the HumanoidCameraOffset when in first person view
--- Defaults to Vector3.new(0, 0, -0.3) if not nil. Setting to nil blocks camera offset updates for first person view.
--- Applies immediately if currently in first person view, otherwise on next view change to first person.
--- Note: Setting nil does not reset the camera offset; previously set offsets persist until explicitly changed
function CameraSettings.SetFirstPersonOffset(
	self : CameraSettings,
	offset : (Vector3 | nil)?
) : ModuleSettings
    if type(offset) ~= `nil` and typeof(offset) ~= `Vector3` then
        offset = Vector3.new(0, 0, -0.3)
    end

    FirstPersonHumanoidCameraOffset = offset
    Reconnect(FirstPersonDetector.IsInFirstPersonView)
	
	return ModuleSettings
end

--- Sets the HumanoidCameraOffset when in third person view
--- Defaults to Vector3.zero if not nil. Setting to nil blocks camera offset updates for third person view.
--- Applies immediately if currently in third person view, otherwise on next view change to third person.
--- Note: Setting nil does not reset the camera offset; previously set offsets persist until explicitly changed
function CameraSettings.SetThirdPersonOffset(
	self : CameraSettings,
	offset : (Vector3 | nil)?
) : ModuleSettings
    if type(offset) ~= `nil` and typeof(offset) ~= `Vector3` then
        offset = Vector3.zero
    end

    ThirdPersonHumanoidCameraOffset = offset
    Reconnect(FirstPersonDetector.IsInFirstPersonView)
	
	return ModuleSettings
end

ModuleSettings = {
	LTMSettings = LTMSettings,
	CameraSettings = CameraSettings,
}

local FirstPersonView = {}
export type FirstPersonView = typeof(FirstPersonView)

FirstPersonView.ModuleSettings = ModuleSettings :: ModuleSettings

return FirstPersonView