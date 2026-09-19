--[[--
    GUICompatibility V1.0.0
    Copyright © 2026 Coffilhg (Roblox UserId 517222346)

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/.

    GitHub Repository/Branch with latest version, documentation, etc:
    https://github.com/Coffilhg/Useful-Modules/tree/GUICompatibility
    Stars are appreciated!
--]]--

local Players = game:GetService("Players")
local WS = game:GetService("Workspace")

--- Dependencies (By @Coffilhg) ---

-- CoffeeObjects's Source Repository: https://github.com/Coffilhg/Useful-Modules/tree/CoffeeObjects
local CoffeeObjects = require(script.CoffeeObjects) -- or wherever it's located and whatever it's named
local CoffeeBaseValue = CoffeeObjects.CoffeeBaseValue

--- /E Dependencies (By @Coffilhg) ---

local player = Players.LocalPlayer
local camera = WS.CurrentCamera
local PG = player.PlayerGui



local someGUI = Instance.new("ScreenGui", PG)
someGUI.Name = "AbsoluteSizeGUI"
someGUI.IgnoreGuiInset = true
someGUI.ClipToDeviceSafeArea = true
someGUI.SafeAreaCompatibility = Enum.SafeAreaCompatibility.FullscreenExtension

local cloneGUI = someGUI:Clone()
cloneGUI.Name = `Cloned{someGUI.Name}`
cloneGUI.IgnoreGuiInset = false
cloneGUI.Parent = someGUI.Parent

-- camera.ViewportSize is actually same as someGUI.AbsoluteSize



-- The size reserved by Roblox TopBar (in pixels / offset)
local GuiInsetSize = CoffeeBaseValue.new(0)

local function updateGuiInsetSizeValue()
	local newValue = math.abs(camera.ViewportSize.Y - cloneGUI.AbsoluteSize.Y)
	
	if GuiInsetSize.Value ~= newValue then
		GuiInsetSize.Value = newValue
	end
end

updateGuiInsetSizeValue()
if not game:IsLoaded() then
	task.spawn(function()
		repeat
			task.wait()
		until game:IsLoaded()
		
		updateGuiInsetSizeValue()
	end)
end


camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateGuiInsetSizeValue)
--cloneGUI:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateGuiInsetSizeValue)

local module = {}

-- This module has already loaded the game.Workspace.CurrentCamera - just take it from here!
function module:GetCamera()
	return camera
end

function module:GetFullscreenAbsoluteSize()
	return camera.ViewportSize or someGUI.AbsoluteSize
end

-- Returns a CoffeeBaseValue, which .Value field is equal the amount of pixels(offset), that the Roblox topbar takes.
-- This should be used to get accurate position of players mouse, e.g.:
-- game:GetService("UserInputService"):GetMouseLocation() - Vector2.new(0, module:GetGuiInsetSize().Value)
-- this is mostly useful for ScreenGuis with IgnoreGuiInset property set to true
function module:GetGuiInsetSize() : CoffeeObjects.CoffeeBaseValue
	return GuiInsetSize --math.abs(someGUI.AbsoluteSize.Y - cloneGUI.AbsoluteSize.Y)
end

function module:UpdateAndGetGuiInsetSize() : CoffeeObjects.CoffeeBaseValue
	updateGuiInsetSizeValue()
	return module:GetGuiInsetSize()
end

-- Returns the difference in size between DeviceSafeInsets vs None Safe Insets
-- This is useful for scaling Gui, that has to be accurately 100% of the screen width - just set it's Size property to UDim2.new(1, module:GetSafeInsetsSize().X, 0.1, 0)
function module:GetSafeInsetsSize()
	someGUI.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	local safeSize = someGUI.AbsoluteSize
	someGUI.ScreenInsets = Enum.ScreenInsets.None
	local fullscreenSize = someGUI.AbsoluteSize
	local diff = fullscreenSize - safeSize
	return Vector2.new(math.abs(diff.X), math.abs(diff.Y))
end

return module