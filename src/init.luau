--[[
    CameraController
    Copyright © 2026 Coffilhg (Roblox UserId 517222346)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version. "Version 3 or later".

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.



    Quick Start and API / Full License & Notices:
	https://github.com/Coffilhg/Useful-Modules/tree/CameraController
    Module Version: 1.0.0
--]]
--!strict

--- Services
local Players = game:GetService("Players")
local TS = game:GetService("TweenService")
local WS = game:GetService("Workspace")
local RunS = game:GetService("RunService")
--- Constants / Runtime Variables

local EasySmoothDamp = require(script.Parent.EasySmoothDamp)

local player = Players.LocalPlayer :: Player
local camera = WS.CurrentCamera :: Camera
local mouse : Mouse = player:GetMouse()
local CFrameIdentity : CFrame = CFrame.identity

--local LastBoundToPartEverSet = false
local LastBoundToPart : BasePart --= Instance.new("Part")
local RunServicePostSimulationConnection : RBXScriptConnection? -- UpdateUndind
local RunServicePreSimulationConnection : RBXScriptConnection? -- UpdateBind
local UnbindElapsed : number = 0
local IsBound : boolean = false
--local GoalCFrame : CFrame = CFrameIdentity
-- SmoothDamp related (Bind Camera To Part)
--local CurrentCFrame : CFrame = CFrameIdentity
--local CurrentVelocity : Vector3 = Vector3.zero

-- required for the code dancing with core Roblox scripts
-- learn more in the "Camera manipulation" official Roblox Tutorial
-- https://www.youtube.com/watch?v=Iht0ddcLWFU
-- https://www.youtube.com/watch?v=Iht0ddcLWFU&t=343		(around 5:43)
local CurrentPlayerCameraCFrame : CFrame = CFrameIdentity


--- Customizable Constants / Runtime Variables
--local RunServiceRenderStepNameForBind : string = "CameraController_BindCameraToPart"
local RunServiceRenderStepNameForUnbind : string = "CameraController_UnbindCamera"
-- Camera Back to Character
local TransitionTime : number = 0.9
local TransitionEasingStyle : Enum.EasingStyle = Enum.EasingStyle.Circular
local TransitionEasingDirection : Enum.EasingDirection = Enum.EasingDirection.InOut
-- Mouse Follow
local MaxTilt : number = 9
local XClampPercent : number = 1 -- Up/Down
local YClampPercent : number = 1 -- Left/Right
-- SmoothDamp related (Bind Camera To Part)
--local SmoothTime : number = 0.1
--local MaxSpeed : number = 120
local BindCameraToPartDamper : EasySmoothDamp.SmoothDamper<CFrame> = EasySmoothDamp.new(
	CFrameIdentity,
	CFrameIdentity,
	nil,
	0.1,
	120
)
-- FOV Control
local DefaultFOV : number = 70
local FOVTransitionTweenInfo : TweenInfo = TweenInfo.new(0.72, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local FOVTween : Tween?



--- Utility
-- Coffilhgs Enum Good Lookup ~ CameraType
export type CameraTypeAcceptable = Enum.CameraType | "Fixed" | "Attach" | "Watch" | "Track" | "Follow" | "Custom" | "Scriptable" | "Orbital"
local CameraTypeLookup = {
	["track"] = Enum.CameraType.Track,
	["orbital"] = Enum.CameraType.Orbital,
	["custom"] = Enum.CameraType.Custom,
	["fixed"] = Enum.CameraType.Fixed,
	["attach"] = Enum.CameraType.Attach,
	["watch"] = Enum.CameraType.Watch,
	["follow"] = Enum.CameraType.Follow,
	["scriptable"] = Enum.CameraType.Scriptable,
}
local DefaultCameraTypeResolveValue = Enum.CameraType.Custom
local function ResolveCameraType(v : CameraTypeAcceptable?) : Enum.CameraType
	if typeof(v) == "EnumItem" and v.EnumType == Enum.CameraType then
		return v
	elseif type(v) == "string" then
		return (CameraTypeLookup[v:lower()] :: any) or DefaultCameraTypeResolveValue
	end
	return DefaultCameraTypeResolveValue
end

-- Coffilhgs Enum Good Lookup ~ EasingStyle
export type EasingStyleAcceptable = Enum.EasingStyle | "Linear" | "Sine" | "Back" | "Quad" | "Quart" | "Quint" | "Bounce" | "Elastic" | "Exponential" | "Circular" | "Cubic"
local EasingStyleLookup = {
	["sine"] = Enum.EasingStyle.Sine,
	["elastic"] = Enum.EasingStyle.Elastic,
	["quad"] = Enum.EasingStyle.Quad,
	["back"] = Enum.EasingStyle.Back,
	["quart"] = Enum.EasingStyle.Quart,
	["linear"] = Enum.EasingStyle.Linear,
	["cubic"] = Enum.EasingStyle.Cubic,
	["circular"] = Enum.EasingStyle.Circular,
	["exponential"] = Enum.EasingStyle.Exponential,
	["bounce"] = Enum.EasingStyle.Bounce,
	["quint"] = Enum.EasingStyle.Quint,
}
local DefaultEasingStyleResolveValue = Enum.EasingStyle.Circular
local function ResolveEasingStyle(v : EasingStyleAcceptable?) : Enum.EasingStyle
	if typeof(v) == "EnumItem" and v.EnumType == Enum.EasingStyle then
		return v
	elseif type(v) == "string" then
		return (EasingStyleLookup[v:lower()] :: any) or DefaultEasingStyleResolveValue
	end
	return DefaultEasingStyleResolveValue
end

-- Coffilhgs Enum Good Lookup ~ EasingDirection
export type EasingDirectionAcceptable = Enum.EasingDirection | "In" | "Out" | "InOut"
local EasingDirectionLookup = {
	["in"] = Enum.EasingDirection.In,
	["inout"] = Enum.EasingDirection.InOut,
	["out"] = Enum.EasingDirection.Out,
}
local DefaultEasingDirectionResolveValue = Enum.EasingDirection.InOut
local function ResolveEasingDirection(v : EasingDirectionAcceptable?) : Enum.EasingDirection
	if typeof(v) == "EnumItem" and v.EnumType == Enum.EasingDirection then
		return v
	elseif type(v) == "string" then
		return (EasingDirectionLookup[v:lower()] :: any) or DefaultEasingDirectionResolveValue
	end
	return DefaultEasingDirectionResolveValue
end



local BreakLatestSetCameraType : ( () -> () )?
local function SetCameraType(cam : Camera, cameraType : CameraTypeAcceptable?)
	if type(BreakLatestSetCameraType) == "function" then
		BreakLatestSetCameraType()
		BreakLatestSetCameraType = nil
	end
	
	cameraType = ResolveCameraType(cameraType)
	if cam.CameraType == cameraType then
		return
	end
	
	cam.CameraType = cameraType :: Enum.CameraType
	if cam.CameraType ~= cameraType then
		local stop = false
		BreakLatestSetCameraType = function()
			stop = true
		end
		repeat
			task.wait()
			cam.CameraType = cameraType :: Enum.CameraType
		until cam.CameraType == cameraType or stop
	end
end



--- Core

local function RestorePlayerCameraCFramePostSimulation()
	if typeof(RunServicePostSimulationConnection) == "RBXScriptConnection" then --and RunServicePostSimulationConnection.Connected then
		return
	end
	
	RunServicePostSimulationConnection = RunS.PostSimulation:Connect(function()
		--print("Reset!")
		camera.CFrame = CurrentPlayerCameraCFrame
	end)
end
local function CleanupUnbind()
	if typeof(RunServicePostSimulationConnection) == "RBXScriptConnection" and RunServicePostSimulationConnection.Connected then
		RunServicePostSimulationConnection:Disconnect()
		RunServicePostSimulationConnection = nil
	end
	
	RunS:UnbindFromRenderStep(RunServiceRenderStepNameForUnbind)
end
local function UpdateUnbindTween(dt : number)
	if IsBound then
		CleanupUnbind()
		return
	end
	
	-- Will be the actual current Player camera CFrame if it was erased (set to CFrame.identity) PostSimulation
	--print("Reading!")
	--local currentPlayerCameraCFrame = camera.CFrame
	CurrentPlayerCameraCFrame = camera.CFrame

	UnbindElapsed += dt
	if UnbindElapsed >= TransitionTime then
		UnbindElapsed = TransitionTime
		CleanupUnbind()
		return
	end

	-- number from 0 to 1
	local value = TS:GetValue(
		UnbindElapsed / TransitionTime,
		TransitionEasingStyle,
		TransitionEasingDirection
	)
	
	-- CurrentCFrame is the LatestCFrame reached on the way to the
	-- GoalCFrame, since when IsBound is false, CurrentCFrame is no more updated.
	--camera.CFrame = CurrentCFrame:Lerp(currentPlayerCameraCFrame, value)
	camera.CFrame = BindCameraToPartDamper.CurrentValue:Lerp(CurrentPlayerCameraCFrame, value)
	--print("Updated!")
end

local function UnbindCamera()
	if not IsBound then
		return
	end
	IsBound = false
	-- back to player default camera
	
	UnbindElapsed = 0
	
	SetCameraType(camera, "Custom")

	RestorePlayerCameraCFramePostSimulation()

	RunS:BindToRenderStep(
		RunServiceRenderStepNameForUnbind,
		Enum.RenderPriority.Camera.Value + 1,
		UpdateUnbindTween
	)
	
end


local function CleanupBind()
	if typeof(RunServicePreSimulationConnection) == "RBXScriptConnection" and RunServicePreSimulationConnection.Connected then
		RunServicePreSimulationConnection:Disconnect()
	end
end
local function UpdateBindTween(dt : number)
	if not IsBound then
		CleanupBind()
		return
	end
	
	
	local mouseViewSizeY = mouse.ViewSizeY
	local mouseViewSizeX = mouse.ViewSizeX
	local mouseY = mouse.Y
	local mouseX = mouse.X
	
	local tiltX = math.rad((((mouseY - mouseViewSizeY / 2) / mouseViewSizeY)) * -MaxTilt * XClampPercent)
	local tiltY = math.rad((((mouseX - mouseViewSizeX / 2) / mouseViewSizeX )) * -MaxTilt * YClampPercent)
	
	--GoalCFrame = LastBoundToPart.CFrame * CFrame.Angles(tiltX, tiltY, 0)
	BindCameraToPartDamper.CurrentGoal = LastBoundToPart.CFrame * CFrame.Angles(tiltX, tiltY, 0)
	
	--[[
	CurrentCFrame, CurrentVelocity = TS:SmoothDamp(
		CurrentCFrame,
		GoalCFrame,
		CurrentVelocity,
		SmoothTime,
		MaxSpeed,
		dt
	)
	--]]
	
	--print("CurrentCFrame Updated!")
	-- update happens internally inside EasySmoothDamp
	camera.CFrame = BindCameraToPartDamper:Update(dt)
end

local function BindCamera()
	if IsBound then
		return
	end
    -- ensure no race conditions by cleaning up
	CleanupUnbind()
    -- IsBound change here auto-triggers CleanupUnbind(),
    -- however it might lead to up to 1 frame race conditions
	IsBound = true
	
	SetCameraType(camera, "Scriptable")
	
	--warn("CurrentCFrame Updated!")
	--CurrentCFrame = camera.CFrame
	--BindCameraToPartDamper.CurrentValue = CurrentCFrame
	BindCameraToPartDamper.CurrentValue = camera.CFrame
	
	RunServicePreSimulationConnection = RunS.PreRender:Connect(UpdateBindTween)
end



--- Public Module API
local CameraController = {}
export type CameraController = typeof(CameraController)

-- defaults to unbinding Camera - moves the Camera back to Character
function CameraController.BindToPart(
	self : CameraController,
	part : BasePart?
) : CameraController
	
	if typeof(part) ~= "Instance" then
		UnbindCamera()
		return self
	end
	if not part:IsA("BasePart") then
		UnbindCamera()
		return self
	end
	
	--[[
	if not LastBoundToPartEverSet then
		LastBoundToPartEverSet = true
		LastBoundToPart:Destroy()
	end
	--]]
	LastBoundToPart = part
	BindCamera()
	
	return self
end

-- defaults to default FOV of 70 or a customly set one
function CameraController.SetFOV(
	self : CameraController,
	newFOV : number?
)
	if not (
		type(newFOV) == "number" and
			newFOV == newFOV and -- nan invalidation
			newFOV ~= math.huge and
			newFOV ~= -math.huge
		) then
		newFOV = DefaultFOV
	end
	
	if typeof(FOVTween) == "Tween" then
		FOVTween:Cancel()
		FOVTween:Destroy()
	end
	
	local newFOVTween = TS:Create(
		camera,
		FOVTransitionTweenInfo,
		{
			FieldOfView = newFOV
		}
	)
	newFOVTween:Play()
	FOVTween = newFOVTween
	
end

local ModuleSettings = {} :: ModuleSettings
export type ModuleSettings = {
	["CameraBackToCharacter"]: CameraBackToCharacter,
	["MouseFollow"]: MouseFollow,
	["BindCameraToPartDamper"]: EasySmoothDamp.SmoothDamper<CFrame>,
	["FOVControl"]: FOVControl,
}


local CameraBackToCharacter = {}
export type CameraBackToCharacter = typeof(CameraBackToCharacter)

-- defaults to 0.9 and only positive numbers
function CameraBackToCharacter.SetTransitionTime(
	self : CameraBackToCharacter,
	transitionTime : number?
) : ModuleSettings
	if type(transitionTime) ~= "number" then
		transitionTime = 0.9
	end
	TransitionTime = math.abs(transitionTime :: number)
	
	return ModuleSettings
end

-- defaults to Enum.EasingStyle.Circular
function CameraBackToCharacter.SetTransitionEasingStyle(
	self : CameraBackToCharacter,
	transitionEasingStyle : EasingStyleAcceptable?
) : ModuleSettings
	TransitionEasingStyle = ResolveEasingStyle(transitionEasingStyle)
	
	return ModuleSettings
end

-- defaults to Enum.EasingDirection.InOut
function CameraBackToCharacter.SetTransitionEasingDirection(
	self : CameraBackToCharacter,
	transitionEasingDirection : EasingDirectionAcceptable?
) : ModuleSettings
	TransitionEasingDirection = ResolveEasingDirection(transitionEasingDirection)

	return ModuleSettings
end



local MouseFollow = {}
export type MouseFollow = typeof(MouseFollow)

-- defaults to 9 and only positive numbers
function MouseFollow.SetMaxTiltDegrees(
	self : MouseFollow,
	maxTilt : number?
) : ModuleSettings
	if type(maxTilt) ~= "number" then
		maxTilt = 9
	end
	MaxTilt = math.abs(maxTilt :: number)

	return ModuleSettings
end

-- defaults to 1;
-- Basically the multiplier for Up/Down mouse movement interactions
function MouseFollow.SetXClampPercent(
	self : MouseFollow,
	xClampPercent : number?
) : ModuleSettings
	if type(xClampPercent) ~= "number" then
		xClampPercent = 1
	end
	XClampPercent = xClampPercent :: number

	return ModuleSettings
end

-- defaults to 1;
-- Basically the multiplier for Left/Right mouse movement interactions
function MouseFollow.SetYClampPercent(
	self : MouseFollow,
	yClampPercent : number?
) : ModuleSettings
	if type(yClampPercent) ~= "number" then
		yClampPercent = 1
	end
	YClampPercent = yClampPercent :: number

	return ModuleSettings
end



local FOVControl = {}
export type FOVControl = typeof(FOVControl)

-- defaults to 70
-- If you set negative or big numbers make sure such FOV is supported by Roblox
-- does not auto apply the FOV! Do CameraController:SetFOV()
function FOVControl.SetDefaultFOV(
	self : FOVControl,
	defaultFOV : number?
) : ModuleSettings
	if type(defaultFOV) ~= "number" then
		defaultFOV = 70
	end
	DefaultFOV = defaultFOV :: number

	return ModuleSettings
end

-- defaults to TweenInfo.new(0.72, Enum.EasingStyle.Quad, Enum.EasingDirection.In) if nil
-- If you set negative or big numbers make sure such FOV is supported by Roblox
-- does not auto apply the FOV! Do CameraController:SetFOV()
function FOVControl.SetFOVTransitionTweenInfo(
	self : FOVControl,
	newFOVTransitionTweenInfo : TweenInfo?
) : ModuleSettings
	if typeof(newFOVTransitionTweenInfo) ~= "TweenInfo" then
		newFOVTransitionTweenInfo = TweenInfo.new(0.72, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end
	FOVTransitionTweenInfo = newFOVTransitionTweenInfo :: TweenInfo

	return ModuleSettings
end




ModuleSettings = {
	CameraBackToCharacter = CameraBackToCharacter,
	MouseFollow = MouseFollow,
	BindCameraToPartDamper = BindCameraToPartDamper,
	FOVControl = FOVControl,
}

CameraController.ModuleSettings = ModuleSettings :: ModuleSettings

return CameraController