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