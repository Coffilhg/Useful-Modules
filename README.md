# GreatUIDrag

Draggable UIs made easy!
Supports desktop and mobile, GUI insets, anchor points, viewport resizing, and CSS-like padding limits. Console support is untested but should work for cursor-based input.



## Available Here!
- **[This repository](src/init.luau) ~ [src/init.luau](src/init.luau)**
- **[Wally](<https://wally.run/package/coffilhg/greatuidrag>)**

    ```toml
    GreatUIDrag = "coffilhg/greatuidrag@2.0.0"
    ```
- **[Rotriever](<https://github.com/Coffilhg/Useful-Modules/releases/tag/vGreatUIDrag/2.0.0>)**

    ```toml
    GreatUIDrag = "github.com/Coffilhg/Useful-Modules@GreatUIDrag/2.0.0"
    ```

<!-- **[Creator Store](<https://create.roblox.com/store/category/gameplay?creatorName=coffilhg>)** ~ **[GreatUIDrag](<https://create.roblox.com/store/asset/123456789/GreatUIDrag>)**-->

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
- Events for contact, start, release, completion and position changes (Click vs drag detection)

---

## Usage

Place the module and its dependencies somewhere accessible (e.g. `ReplicatedStorage`):
> Here's how it looks when you run `rojo serve test.project.json` of this repository
> 
> (you must have rojo, wally, wally-package-types and previously download dependencies (e.g. with `wally install && rojo sourcemap test.project.json --output sourcemap.json && wally-package-types -s sourcemap.json Packages/`))
```
Packages
├── _Index
├── CoffeeObjects
├── GUICompatibility
├── GreatUIDrag
│   └── _Spring
└── LemonSignal
```

Then require it:
```lua
local GreatUIDrag = require(path.To.GreatUIDrag)
```

---

## Quick Start

```lua
GreatUIDrag(
    Frame,          -- GuiObject to move
    Frame.Header    -- Drag handle (TextButton / ImageButton) -- Optional for V2.0.0+
)
```

or more explicit

```lua
local drag = GreatUIDrag(
    Frame,                  -- GuiObject to move
    Frame.Header,           -- Drag handle (TextButton / ImageButton)
    1,                      -- Damping (Less = more like jelly)
    27,                     -- Speed (More = faster interpolation)
    {UDim.new(0.04, 8)},    -- Padding (Top, Right, Bottom, Left)
    1,                      -- Sensibility (Useful for UI bigger than screen)
    0.24                    -- Drag Start Delay (Useful to ignore simple clicks)
)
```

---

## API

```lua
GreatUIDrag(
    dragElement: GuiObject,
    dragHandle: ( DragHandle | {DragHandle} )?,
    damping: number?,
    speed: number?,
    paddingOptions: ( number | UDim | {number | UDim} )?,
    sensibilityMultiplier: number?,
    dragStartDelay: number?
): DragElement
```

## Parameters

### `dragElement`
> The UI object that will move.

### `dragHandle` (optional for V2.0.0+)
> A `TextButton` or `ImageButton`
>
> OR an array (table) of them
>
> More can be added using `:AddHandle` for V2.0.0+

### `damping` (optional)
> Spring damping factor
> Default = `1`
>
> Lower = bouncier
> Higher = stiffer

### `speed` (optional)
> Spring speed
>
> Default = `27 / sensibilityMultiplier`

### `paddingOptions` (optional)
> CSS-like syntax:

| Input                      | Result                                                                       |
|----------------------------|------------------------------------------------------------------------------|
| Empty (`nil`) or `{}`      | Defaults to 30px padding on all sides                                        |
| `x` or `{x}`               | All sides have `x` padding                                                   |
| `{y, x}`                   | Horizontal (top+bottom) padding is `y`; Vertical (right+left) padding is `x` |
| `{y1, x, y2}`              | Top padding = `y1`, sides (right+left) padding = `x`, Bottom padding = `y2`  |
| `top, right, bottom, left` | full control                                                                 |

> Each value can be an UDim or a number, which will be converted into UDim.new(0, number) (pixels)

### `sensibilityMultiplier` (optional)
> Drag sensitivity
> 
> Default = `1`

### `dragStartDelay` (optional)
> Minimal Press & Hold time (Delay) for Drag to start
>
> `OnDragStarted` Fires once this time has passed, after the `OnDragContact`, which fires the instant the DragElement is Pressed
> 
> Default = `0.24`

## Returned Object (`DragElement`) Methods

```lua
local MyDragElement = GreatUIDrag(...)
```

### `MyDragElement:AddHandle(dragHandle: ( DragHandle | {DragHandle} )?)`
> "`type DragHandle = (TextButton | ImageButton | GuiButton)`"
>
> Adds a `TextButton` / `ImageButton` / `GuiButton`, or an array (table) of them, as additional drag handles (or the main one if none were added previously at creation).

### `MyDragElement:Destroy()`
> Cancels active drag on this `DragElement` and disconnects all signals involved (including all Event signals)
>
> It is silent, without `OnDragReleased` / `OnDragCompleted`
>
> Called automatically when the `dragElement` is destroyed (anything that triggers `dragElement.Destroying`)
>
> Does **not** destroy the `dragElement` or the handles themselves.
>
> (no arguments)

### `MyDragElement:InitDrag(triggerHandle: DragHandle)`
> Activates dragging (as if client started using one of the drag handles), if this `DragElement` isn't active already
> 
> `triggerHandle` is passed to the events

### `MyDragElement:IsDestroyed(): boolean`
> Returns a boolean on whether the `DragElement` is destroyed. If it is, it shall not be used and the reference shall be `nil`lified or overwritten
>
> (no arguments)

### `MyDragElement:Reposition()`
> Immediately repositions the element to the current spring state
>
> (no arguments)

### `MyDragElement:SetPosition(position: UDim2?)`
> Places the element immediately and resets the spring, without animating
> 
> If `typeof(position) ~= "UDim2"` (e.g. not given), it uses the mouse location

### `MyDragElement:Stop()`
> Stops active dragging (client input signals) but allows spring to reach the latest goal
>
> (no arguments)

## Returned Object (`DragElement`) Events (V2.0.0+)
All of the events are **Signal** Objects instantiated via **LemonSignal**
> (a new dependency introduced in v2.0.0)

| Event                  | Arguments                                | Fires                                                                 |
|------------------------|------------------------------------------|-----------------------------------------------------------------------|
| `OnDragContact`        | `triggerHandle`                          | A handle was pressed; First contact with the dragElement made                                                                                                                            |
| `OnDragStarted`        | `triggerHandle`                          | The pointer moved after `dragStartDelay` (a real drag); Fires after OnDragContact and dragStartDelay if not OnDragReleased                                                               |
| `OnDragReleased`       | `finalGoal, wasDragged, triggerHandle`   | Released, or another element started dragging; the spring keeps going; Fires after dragElement gets released or another dragElement is starting, continues moving towards the final goal |
| `OnDragCompleted`      | `finalGoal, wasDragged, triggerHandle`   | The spring settled at the final goal; Fires after the final goal was reached                                                                                                             |
| `OnPositionChanged`    | `currentAbsoluteX, currentAbsoluteY`     | The element was repositioned (the offsets written to `Position`); Fires on Reposition / UIS.InputChanged while used                                                                      |

`wasDragged` is `true` if `OnDragStarted` fired, otherwise `nil`, so you can tell a click from a drag:
> `wasDragged` is an alias for `IsDragStartFiredBeforeReleased` (how it is commented in the source)

Example usage:
```lua
MyDragElement.OnDragReleased:Connect(function(finalGoal, wasDragged, handle)
    if not wasDragged then
        print("just a click on", handle)
    end
end)
```

---

## Notes
- Only one active drag is allowed at a time (intentional)
    - Pressing another element's handle stops this one (its `OnDragReleased` fires)
- Uses `RunService.Heartbeat` only while active or on-the-way to complete the latest goal
- Automatically updates bounds based on:
    - Viewport resize (`game.Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize")`)
    - AnchorPoint change (`dragElement:GetPropertyChangedSignal("AnchorPoint")`)
    - GuiInset change (`GUICompatibility:GetGuiInsetSize().Value`)
- The element won't move unless it's inside a `ScreenGui`. This is re-checked when its parent changes
- To react to a `DragElement` being destroyed, connect to the `dragElement`'s own `Destroying` event. Check `:IsDestroyed()` if you need to know later
- Setting `dragElement.Parent = nil` is not `dragElement:Destroy()`, therefore it does not automatically call `DragElement:Destroy()`

---

## Dependencies
- [GUICompatibility](https://github.com/Coffilhg/Useful-Modules/tree/GUICompatibility)
- [CoffeeObjects](https://github.com/Coffilhg/Useful-Modules/tree/CoffeeObjects)
- [_Spring](https://create.roblox.com/store/asset/71132874095126/Spring-Module) (by @crusherfire | https://www.roblox.com/users/80102935/profile)
- [LemonSignal](<https://github.com/Data-Oriented-House/LemonSignal>)

## License & Attribution

This module is licensed under the **Mozilla Public License 2.0 (MPL-2.0)**.

#### What this means for Roblox Developers:
* **Use & Modify:** You can freely use this module in any public, private, or commercial Roblox game.
* **File-Level Copyleft:** If you modify the source code of this module itself, you must make your modified version of the module publicly available under the MPL 2.0.
* **No Viral Code Leakage:** Including this module in your game does **not** force you to open-source your other game scripts, UI layouts, or proprietary codebase. 

See the full terms in the [LICENSE](LICENSE) file.

Attribution to all dependencies is included in [Notice](NOTICE)

Copyright © 2026 @Coffilhg (Roblox UserId 517222346)