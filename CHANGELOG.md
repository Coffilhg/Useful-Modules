# v2.0.0

**Breaking:** [CoffeeObjects](https://github.com/Coffilhg/Useful-Modules/tree/CoffeeObjects) was replaced with the more lightweight [Reaction](https://github.com/Coffilhg/Useful-Modules/tree/Reaction). `:GetGuiInsetSize()`, `:GetSafeInsetsSize()` and `:GetFullscreenAbsoluteSize()` now return a Reaction `V`, so they update automatically:
```luau
local inset: number = GUICompatibility:GetGuiInsetSize().Value -- before
local inset: number = GUICompatibility:GetGuiInsetSize()() -- after

local safeInsetsSize: Vector2 = GUICompatibility:GetSafeInsetsSize() -- before
local safeInsetsSize: Vector2 = GUICompatibility:GetSafeInsetsSize()() -- after
```

**Breaking:** `:UpdateAndGetGuiInsetSize()` was renamed to `:Update()`: it updates everything right away (not only the GuiInsetSize) and returns nothing:
```luau
local inset: number = GUICompatibility:UpdateAndGetGuiInsetSize().Value -- before
GUICompatibility:Update() -- after
local inset: number = GUICompatibility:GetGuiInsetSize()()
```

### Added
- `:TrackInputOffset(screenGui)` / `:TrackInputOffsetUDim2(screenGui)` return a new `V` and its `Tracker`. The `V` holds `-screenGui.AbsolutePosition`, the offset to add to `InputObject.Position` to put a GuiObject under the pointer, for any combination of `ScreenInsets` / `IgnoreGuiInset`:
  ```luau
  local offset, tracker = GUICompatibility:TrackInputOffsetUDim2(screenGui)
  pointer.Position = UDim2.fromOffset(input.Position.X, input.Position.Y) + offset()
  ```
  Stop a tracker with `tracker:Untrack()` or `rmV(offset)`; Or stop every tracker of a ScreenGui with `:UntrackInputOffset(screenGui)` and `screenGui.Destroying`
- `:IsTracked(screenGui)`, `tracker:IsTracking()`
- An Example place (`rojo serve test.project.json`), see the README

### Changed
- Everything is re-read 0.3 seconds after the last `Camera.ViewportSize` change instead of right away, when the GUI isn't laid out yet (e.g. in v1.0.0 switching iPhone -> iPad read a 490 px TopBar instead of 58 px)
- Type annotations

# v1.0.0

Initial wally & rotriever publish.
This version is slightly different from the initial commit in this repository:
- added `table.freeze` for safety
- set `ResetOnSpawn = false`
- small writing style and type definition changes

# before wally-publish
Relicensed from Apache-2.0 to MPL-2.0