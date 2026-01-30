# GreatUIDrag

Draggable UIs made easy!
Supports desktop and mobile, GUI insets, anchor points, viewport resizing, and CSS-like padding limits. Console support is untested but should work for cursor-based input.

---

## Features
- Smooth spring interpolation (no Tween spam, thx to @crusherfire)
- CSS-like padding
- Optionally multiple drag handles
- Sensibility, speed and damping control
- Automatically handles
    - IgnoreGuiInset changes
    - AnchorPoint
    - Viewport resizing (Non-fullscreen players and mobile players rotating their screen)

---

## Usage

Place the module and its dependencies somewhere accessible (e.g. `ReplicatedStorage`):
```
GreatUIDrag
├── GUICompatibility
├── CoffeeObjects
└── _Spring
```

Then require it:
``local GreatUIDrag = require(path.To.GreatUIDrag)``

---

## Quick Start

```
GreatUIDrag(
    Frame,          -- GuiObject to move
    Frame.Header    -- Drag handle (TextButton / ImageButton)
)
```

or more explicit

```
local drag = GreatUIDrag(
    Frame,                  -- GuiObject to move
    Frame.Header,           -- Drag handle (TextButton / ImageButton)
    1,                      -- Damping (Less = more like jelly)
    27,                     -- Speed (More = faster interpolation)
    {UDim.new(0.04, 8)},    -- Padding (Top, Right, Bottom, Left)
    1                       -- Sensibility (Useful for UI bigger than screen)
)
```

---

## API

```
GreatUIDrag(
    dragElement: GuiObject,
    dragHandle: TextButton | ImageButton | {TextButton | ImageButton},
    damping: number?,
    speed: number?,
    paddingOptions: {number | UDim}?,
    sensibilityMultiplier: number?
) -> DragElement
```

## Parameters

### `dragElement`
> The UI object that will move.

### `dragHandle`
> A `TextButton` or `ImageButton`
> OR a table of them (must contain at least ONE `TextButton` or `ImageButton`)

### `damping` (optional)
> Spring damping factor
> Default = `1`
>
> Lower = bouncier
> Higher = stiffer

### `speed` (optional)
> Spring speed
> Default = `27 / sensibilityMultiplier`

### `paddingOptions` (optional)
> CSS-like syntax:
| Input                      | Result                                                                       |
|----------------------------|------------------------------------------------------------------------------|
| Empty (`nil`) or `{}`      | Defaults to 30px padding on all sides                                        |
| `{x}`                      | All sides have `x` padding                                                   |
| `{y, x}`                   | Horizontal (top+bottom) padding is `y`; Vertical (right+left) padding is `x` |
| `{y1, x, y2}`              | Top padding = `y1`, sides (right+left) padding = `x`, Bottom padding = `y2`  |
| `top, right, bottom, left` | full control                                                                 |
> Each value can be an UDim or a number, which will be converted into UDim.new(0, number) (pixels)

### `sensibilityMultiplier` (optional)
> Drag sensitivity
> Default = `1`

## Returned Object (`DragElement`) Methods

```
local MyDragElement = GreatUIDrag(...)
```

### `MyDragElement:InitDrag()`
> Activates dragging (as if client started using one of the drag handles), if this `DragElement` isn't active already

### `MyDragElement:Reposition()`
> Immediately repositions the element to the current spring state
> (no arguments)

### `MyDragElement:Stop()`
> Stops active dragging (client input signals) but allows spring to reach the latest goal

---

## Notes
- Only one active drag is allowed at a time (intentional)
- Uses `RunService.Heartbeat` only while active or on-the-way to complete the latest goal
- Automatically updates bounds based on:
    - Viewport resize (`game.Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize")`)
    - AnchorPoint change (`dragElement:GetPropertyChangedSignal("AnchorPoint")`)
    - GuiInset change (`GUICompatibility:GetGuiInsetSize().Value`)

---

## Dependencies
- [GUICompatibility](https://github.com/Coffilhg/Useful-Modules/tree/GUICompatibility)
- [CoffeeObjects](https://github.com/Coffilhg/Useful-Modules/tree/CoffeeObjects)
- [_Spring](https://create.roblox.com/store/asset/71132874095126/Spring-Module) (by @crusherfire | https://www.roblox.com/users/80102935/profile)

## See [LICENSE](https://github.com/Coffilhg/Useful-Modules/tree/GreatUIDrag?tab=License-1-ov-file) and [NOTICE](https://github.com/Coffilhg/Useful-Modules/blob/GreatUIDrag/NOTICE) for details.