# v3.0.0

### Added
- Setters for every option the constructor takes: `:SetDamping(damping)`, `:SetSpeed(speed)`, `:SetPadding(paddingOptions)`, `:SetSensibilityMultiplier(sensibilityMultiplier)` and `:SetDragStartDelay(dragStartDelay)`
    - If the value isn't a number (or valid padding options / expectd value type), the same default as on creation is applied, so e.g. `:SetSpeed()` restores the default speed
    - All of them return the `DragElement`, so they can be chained
    - `:SetPadding` re-fits the element into the new bounds right away
    - `:SetSensibilityMultiplier` can be used mid-drag without the element jumping

### Changed
- The default `speed` is now always `27`; it used to be `27 / sensibilityMultiplier`. The spring runs in pointer space and its settle time doesn't depend on the distance, so dividing the speed only made drags with a higher sensibility lag behind more. **If you passed a `sensibilityMultiplier` but no `speed`, the spring is now faster** (e.g. twice as fast with a sensibility of `2`); pass `27 / sensibilityMultiplier` as the `speed` to keep the old feel

# v2.1.0

- Removed the dependencies [GUICompatibility](<https://github.com/Coffilhg/Useful-Modules/tree/GUICompatibility>) and [CoffeeObjects](<https://github.com/Coffilhg/Useful-Modules/tree/CoffeeObjects>). Everything is now calculated in the space of `AbsolutePosition` and `InputObject.Position`, so no GUI inset values are needed anymore.

### Fixed
- Clicking an element (without dragging) moved it slightly to the left and/or up when the game was started in a mobile device (or emulation of)
- After switching the device during a playtest, the next drag was offset
- Elements inside a Frame or ScrollingFrame (not directly in the ScreenGui) were positioned relative to the ScreenGui
- Dragging on mobile no longer uses `TouchTap`, which never fired when tested on a phone; `MouseButton1Down` fires for touches too and is the only trigger now
- Gamepad thumbsticks, the mouse wheel and device motion no longer move a dragged element (`InputChanged` is limited to `MouseMovement` and `Touch`)
- Incompatibility with wally-package-types **[more info](<https://github.com/JohnnyMorganz/wally-package-types/issues/34>)**

### Changed
- Works with every `ScreenInsets` / `IgnoreGuiInset` / `SafeAreaCompatibility` combination; the bounds are the ScreenGui's own area
- Bounds are re-fitted when the ScreenGui's `AbsoluteSize` / `AbsolutePosition` changes (instead of listening to `Camera.ViewportSize` and `IgnoreGuiInset`); the values are already final when these signals fire, so no delayed re-fit like in **[GUICompatibility](<https://github.com/Coffilhg/Useful-Modules/blob/GUICompatibility/CHANGELOG.md#:~:text=Everything%20is%20re>)** is needed
- `OnPositionChanged` arguments renamed to `offsetX, offsetY` (they were always the offsets written to `Position`); now they are also fixed/correct for the cases where previous versions positioned the element wrong (see Fixed)
- The `DragElement` class table is frozen

# v2.0.1

- Found the cause of ``Type Error: (1,1) Type inference failed to complete, you may see some confusing types and type errors.`` and fixed it; ([More info and why](<https://github.com/luau-lang/luau/issues/2663>))
    - Also added more declarations in the ``types compliance`` part, because fixing the confusing type errors made this visible.

# v2.0.0

> This version was actually a fork of the before wally-publish version, it doesn't include changes from v1.0.0, but it has them covered in a different way

- The module is now fully `--!strict` typed
> It does however trigger type errors (most notably `Type Error: (1,1) Type inference failed to complete, you may see some confusing types and type errors.`) with the latest type solver. Those should be ignored because Luau LSP handles them and the newest type solver would handle them at the time the module was initially created (about 6 months ago).
- New Dependency - [LemonSignal](<https://github.com/Data-Oriented-House/LemonSignal>)

### Added
- Events: `OnDragContact`, `OnDragStarted`, `OnDragReleased`, `OnDragCompleted`, `OnPositionChanged`
- new argument `dragStartDelay`: movement is ignored for this many seconds after pressing + holding, so a quick click isn't treated as a drag (this is the 7th argument, all previously existing 6 retain the old order)
- `:AddHandle(dragHandle)`: add a handle or an array (table) of handles after creation
- `:SetPosition(newPosition: UDim2?)`: immediately places the element (at the mouse when no position is given)
- `:InitDrag(triggerHandle)` now records which handle started the drag and passes it to the events
- `:Destroy()`, which cancels an active drag silently, disconnects everything including the handle signals, and removes the element from the internal list. This is called automatically when the `dragElement` is destroyed (or anything that triggers `dragElement.Destroying`).
- `:IsDestroyed()` to check whether a DragElement was destroyed.
- `paddingOptions` now also accepts a single number or `UDim` (it is not required to wrap a single value in a table now)

### Changed
- **Behavior:** the default `dragStartDelay` is `0.24`, so drag movement is ignored for the first 0.24s after pressing. Pass `0` for the v1.0.0 behavior.
- `dragHandle` is now optional, and no longer asserts that at least one valid handle exists
- `:Stop()` does nothing when the element isn't being dragged (prevents `OnDragReleased` firing twice)

### v1.0.0 edge cases, covered differently
- Element not inside a `ScreenGui`: all inset fields are initialized in the constructor, so `_Recalculate` can't read `nil`
- Element never dragged: same guard as v1.0.0, `:Reposition()` returns early until a drag (or `:SetPosition` (indirectly)) has set `_startObjectPos` and `_startMousePos`
- `:Stop()` -> `:_KeepAlive()` -> `:Reposition()` -> `:Stop()` loop when `_blocked`: `:Stop()` now returns early when inactive, so the loop can't sustain itself

# v1.0.0

Initial wally & rotriever publish.

This version is slightly different from the initial commit in this repository:
- `:_AdjustInsets()` now handles an edge case if the `_dragElement` is not a descendant of any `ScreenGui` Instance
- `:Reposition()` now handles an edge case if the element was never dragged once (missing `_startObjectPos` and `_startMousePos`)
- `:Stop()` now doesn't jump into an endless loop of `:Stop()` -> `:_KeepAlive()` -> `:Reposition()` -> `:Stop()` when `_blocked` is **true**

# before wally-publish
Relicensed from Apache-2.0 to MPL-2.0