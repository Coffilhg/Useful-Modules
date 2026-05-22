# FirstPersonDetector
Detect whenever the Local Player enters/leaves First Person View: 
```lua
FirstPersonDetector.OnPersonViewChanged:Connect(function(isInFirstPersonView: boolean)
  print(`You have just {isInFirstPersonView and "entered" or "left"} the First Person View!`)
end)
```
or read the state anytime
```lua
print(`You are currently{FirstPersonDetector.IsInFirstPersonView and "" or " not"} in the First Person View!`)
```



## Available Here!
- **[This repository](src/init.luau) ~ [src/init.luau](src/init.luau)**
- **[Wally](<https://wally.run/package/coffilhg/firstpersondetector>)**

    ```toml
    FirstPersonDetector = "coffilhg/firstpersondetector@1.0.0"
    ```
- **Rotriever**

    ```toml
    FirstPersonDetector = "github.com/Coffilhg/Useful-Modules@FirstPersonDetector/1.0.0"
    ```

<!-- **[Creator Store](<https://create.roblox.com/store/category/gameplay?creatorName=coffilhg>)** ~ **[FirstPersonDetector](<https://create.roblox.com/store/asset/123456789/FirstPersonDetector>)**-->

---

## To-Do

- [ ] Expand the README

---

## DEPENDENCIES

- [PerfectSignal](<https://github.com/Coffilhg/PerfectSignal>)
- [HumanoidCameraOffsetController](<https://github.com/Coffilhg/Useful-Modules/tree/HumanoidCameraOffsetController>)

---

## License / License & Attribution

Licensed under the Apache License, Version 2.0.

You may use, modify, and redistribute this module freely, provided that the original copyright notice and license header at the top of the file are preserved.

See the [Apache License 2.0](LICENSE) for full terms.

Attribution to all dependencies is included in [Notice](NOTICE)

© 2026 Coffilhg