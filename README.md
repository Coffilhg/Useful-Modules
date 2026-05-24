# HumanoidCameraOffsetController
This module lets you set the LocalPlayer' **[Humanoid.CameraOffset](<https://create.roblox.com/docs/reference/engine/classes/Humanoid#CameraOffset>)** reliably and smoothly. Useful for making a custom shiftlock or movement system!



## Available Here!
- **[This repository](src/init.luau) ~ [src/init.luau](src/init.luau)**
- **[Wally](<https://wally.run/package/coffilhg/humanoidcameraoffsetcontroller>)**

    ```toml
    HumanoidCameraOffsetController = "coffilhg/humanoidcameraoffsetcontroller@1.0.1"
    ```
- **Rotriever**

    ```toml
    HumanoidCameraOffsetController = "github.com/Coffilhg/Useful-Modules@HumanoidCameraOffsetController/1.0.1"
    ```

<!-- **[Creator Store](<https://create.roblox.com/store/category/gameplay?creatorName=coffilhg>)** ~ **[HumanoidCameraOffsetController](<https://create.roblox.com/store/asset/123456789/HumanoidCameraOffsetController>)**-->

---

## Features
- Smoothly updates the LocalPlayer' `Humanoid.CameraOffset`.
- Read the current smoothed offset any time.
- Start, stop, and tune the internal damper directly.

---

## Installation

Use the "*Available Here!*" section to obtain the Module.

Require the module:
```lua
local HumanoidCameraOffsetController = require(PathToModule)
```

---

## Basic Usage

```lua
-- e.g. classic value used for custom shiftlock
HumanoidCameraOffsetController:SetCameraOffset(Vector3.new(2, 0, 0))

task.wait(0.3)
-- read the current value anytime (mid interpolation too)
local currentOffset = HumanoidCameraOffsetController:GetCameraOffset()
print(currentOffset)

task.wait(0.3)
-- abort anytime (mid interpolation too)
HumanoidCameraOffsetController:Stop()
```

This module updates `Humanoid.CameraOffset` on `RunService.PreRender`. `SetCameraOffset()` begins smoothing automatically.

---

## API

### `HumanoidCameraOffsetController:SetCameraOffset(cameraOffset)`
- `CameraOffset` must be a `Vector3`.
- Sets the target `Humanoid.CameraOffset` and begins smooth interpolation.
- If nil, falls back to `Vector3.zero`, not a Vector3 or nil - yields a warning and ignores the call.

### `HumanoidCameraOffsetController:GetCameraOffset()`
- Returns the current interpolated offset.

### `HumanoidCameraOffsetController:Start()`
- Begins the internal `RunService.PreRender` update loop.
- Use this to resume updates after `Stop()`. Manually.

### `HumanoidCameraOffsetController:Stop()`
- Stops the internal update loop.
- Halts interpolation until `Start()` or `SetCameraOffset()` is called again.

### `HumanoidCameraOffsetController.Damper`
- Exposes the internal `EasySmoothDamp` instance.
- Advanced users can tune:
  - `Damper.CurrentValue`
  - `Damper.CurrentGoal`
  - `Damper.CurrentSpeed`
  - `Damper.SmoothTime`
  - `Damper.MaxSpeed`

---

## Notes

- `Stop()` disconnects the update loop; it does not reset the current offset or goal.
- Require this module from client-side scripts only.
- Want to set the camera offset instantly? Do `:SetCameraOffset(desiredValue)` (this sets `.Damper.CurrentGoal = desiredValue -- and starts the update loop`) and `.Damper.CurrentValue = desiredValue`

---

## DEPENDENCIES

- [EasySmoothDamp](<https://github.com/Coffilhg/Useful-Modules/tree/EasySmoothDamp>)

---

## License / License & Attribution

Licensed under the Apache License, Version 2.0.

You may use, modify, and redistribute this module freely, provided that the original copyright notice and license header at the top of the file are preserved.

See the [Apache License 2.0](LICENSE) for full terms.

Attribution to all dependencies is included in [Notice](NOTICE)

© 2026 Coffilhg