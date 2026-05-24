# FirstPersonView
Primitive Generic Viewmodel of the characters BodyParts

Designed for R6 by default, example for R15 can be found below

ModuleSettings are chainable



## Available Here!
- **[This repository](src/init.luau) ~ [src/init.luau](src/init.luau)**
- **[Wally](<https://wally.run/package/coffilhg/firstpersonview>)**

    ```toml
    FirstPersonView = "coffilhg/firstpersonview@1.0.0"
    ```
- **Rotriever**

    ```toml
    FirstPersonView = "github.com/Coffilhg/Useful-Modules@FirstPersonView/1.0.0"
    ```

<!-- **[Creator Store](<https://create.roblox.com/store/category/gameplay?creatorName=coffilhg>)** ~ **[FirstPersonView](<https://create.roblox.com/store/asset/123456789/FirstPersonView>)**-->

---

## Usage Example

```luau
--!strict
local Players = game:GetService(`Players`)
local RS = game:GetService(`ReplicatedStorage`)

local Packages = RS:WaitForChild(`Packages`)

local FirstPersonDetector = require(Packages.FirstPersonDetector)
FirstPersonDetector:SetFirstPersonEnterMinDistance(0.8) -- more than usually, because the usual setup still has a little of floating with R15 characters

local FirstPersonView = require(Packages.FirstPersonView)
local R15BodyPartsWhitelist = {
	["LeftFoot"] = true,
	["LeftHand"] = true,
	["LeftLowerArm"] = true,
	["LeftLowerLeg"] = true,
	["LeftUpperArm"] = true,
	["LeftUpperLeg"] = true,
	["LowerTorso"] = true,
	["RightFoot"] = true,
	["RightHand"] = true,
	["RightLowerArm"] = true,
	["RightLowerLeg"] = true,
	["RightUpperArm"] = true,
	["RightUpperLeg"] = true
}

local player = Players.LocalPlayer :: Player

local function OnCharAdded(char : Model)
	local hum = char:WaitForChild(`Humanoid`) :: Humanoid
	
	if hum.RigType == Enum.HumanoidRigType.R6 then
		-- default R6 config (all body parts except Torso and Head)
		FirstPersonView.ModuleSettings.LTMSettings:SetWhitelistedParts()
		return
	end
	-- otherwise an R15 config
	FirstPersonView.ModuleSettings.LTMSettings:SetWhitelistedParts(R15BodyPartsWhitelist)
end
OnCharAdded(player.Character or player.CharacterAdded:Wait())
player.CharacterAdded:Connect(OnCharAdded)

print("Local script loaded")
```

---

## To-Do

- [ ] Expand the README

---

## Dependencies

- [FirstPersonDetector](<https://github.com/Coffilhg/Useful-Modules/tree/FirstPersonDetector>)
- [HumanoidCameraOffsetController](<https://github.com/Coffilhg/Useful-Modules/tree/HumanoidCameraOffsetController>)

---

## License & Attribution

This module is licensed under the **Mozilla Public License 2.0 (MPL-2.0)**.

#### What this means for Roblox Developers:
* **Use & Modify:** You can freely use this module in any public, private, or commercial Roblox game.
* **File-Level Copyleft:** If you modify the source code of this module itself, you must make your modified version of the module publicly available under the MPL 2.0.
* **No Viral Code Leakage:** Including this module in your game does **not** force you to open-source your other game scripts, UI layouts, or proprietary codebase. 

See the full terms in the [LICENSE](LICENSE) file.

Attribution to all dependencies is included in [Notice](NOTICE)

Copyright © 2026 @Coffilhg (Roblox UserId 517222346)