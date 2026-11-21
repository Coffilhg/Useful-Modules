# GUICompatibility

Useful for detecting GUI Insets



## Available Here!
- **[This repository](src/init.luau) ~ [src/init.luau](src/init.luau)**
- **[Wally](<https://wally.run/package/coffilhg/guicompatibility>)**

    ```toml
    GUICompatibility = "coffilhg/guicompatibility@2.0.0"
    ```
- **[Rotriever](<https://github.com/Coffilhg/Useful-Modules/releases/tag/vGUICompatibility/2.0.0>)**

    ```toml
    GUICompatibility = "github.com/Coffilhg/Useful-Modules@GUICompatibility/2.0.0"
    ```

<!-- **[Creator Store](<https://create.roblox.com/store/category/gameplay?creatorName=coffilhg>)** ~ **[GUICompatibility](<https://create.roblox.com/store/asset/123456789/GUICompatibility>)**-->

---

## Example place
The Example place is self explanatory: change a ScreenGui's properties from the panel on the left and watch the pointer stay under your mouse/finger (try it with Studio's Device Emulator too).

1. Clone this branch
    ```
    git clone -b GUICompatibility https://github.com/Coffilhg/Useful-Modules.git GUICompatibility
    cd GUICompatibility
    ```
2. Install the tools and packages (rokit required)
    ```
    rokit install
    wally install
    ```
3. Serve the example place
    ```
    rojo serve test.project.json
    ```
4. Open a new Baseplate in Roblox Studio, connect with the Rojo plugin and press Play

![The Example place on a Samsung Galaxy S25 Ultra in the Roblox Studio Device Emulator. A control panel on the left shows the Target ScreenGui, whose properties are changed by clicking the rows: ScreenInsets CoreUISafeInsets, IgnoreGuiInset false, SafeAreaCompatibility None and ClipToDeviceSafeArea false. Below them it reads the Target's own AbsolutePosition 0, 0 and AbsoluteSize 685, 280 (the area below the TopBar), "GuiInsetSize(): 58", the value of the V returned by GetGuiInsetSize, "Pointer offset: 465, 92", the Position of the pink pointer, which is the latest InputObject.Position plus TargetOffset, and "TargetOffset(): 0, 0", the V returned by TrackInputOffsetUDim2 for the Target, equal to minus its AbsolutePosition. A thin blue outline marks the Target ScreenGui's area, with a small yellow square at its center. A small pink square, the pointer, sits exactly under the mouse on the right, showing that input position plus TargetOffset is correct. At the top, a green frame covers the TopBar behind the Roblox buttons, its width is GuiService.TopbarInset.Min.X and it's placed with the Example ScreenGui's own TrackInputOffsetUDim2 offset. A black label at the top center reads "58 px", that's the GuiInsetSize from GetGuiInsetSize, the height of the TopBar. At the bottom, a purple bar labeled "Device safe area width (DeviceSafeInsets): 685 px" shows the X of GetFullscreenAbsoluteSize, the camera's ViewportSize. Behind it, a wider yellow bar labeled "Whole screen width (ScreenInsets.None): 779 px, unsafe margins: 94 px" sticks out on both sides by the (half of) unsafe margins, the X of GetSafeInsetsSize added to the viewport width. Below them, a black label reads "21 px", the Y of GetSafeInsetsSize, the unsafe height at the top and bottom of the device.](./images/example.png "Example Place Preview")

The script is in [tests/init.server.luau](tests/init.server.luau).

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