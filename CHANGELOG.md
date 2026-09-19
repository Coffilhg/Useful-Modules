# v1.0.0

Initial wally & rotriever publish.

This version is slightly different from the initial commit in this repository:
- `:_AdjustInsets()` now handles an edge case if the `_dragElement` is not a descendant of any `ScreenGui` Instance
- `:Reposition()` now handles an edge case if the element was never dragged once (missing `_startObjectPos` and `_startMousePos`)
- `:Stop()` now doesn't jump into an endless loop of `:Stop()` -> `:_KeepAlive()` -> `:Reposition()` -> `:Stop()` when `_blocked` is **true**

# before wally-publish
Relicensed from Apache-2.0 to MPL-2.0