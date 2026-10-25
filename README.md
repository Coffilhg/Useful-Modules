# CreateInstance
A quicker way to use Instance.new

This module is inspired by **[this part of Vide](<https://github.com/centau/vide/blob/f3bfc65607834370ce84a6e16722282c4d30316c/src/create.luau>)**

This module shows ALL class names that exist in the autocomplete, although most of them are not creatable using `Instance.new`

`Parent` is given like any other prop, but it is set last (after all other props and children are applied) [as per official recommended way of using `Instance.new`](https://create.roblox.com/docs/en-us/reference/engine/datatypes/Instance#:~:text=Set%20new%20instance's%20parent%20last%20(recommended))

Parent will not be set if you leave it nil

If given, the `Parent` key is wiped from the props table you pass in. This is the only change ever made to your props table, so don't pass a frozen table that contains `Parent` and don't reuse the same props table without making sure you have a `Parent` indexed value in it - unless you want your Instance unparented

All **number indexed Instances** in props become children of the new Instance
> i.e. all values that are number indexed and are not *typeof Instance* are applied as if they were usual Properties

---

## Available Here (3 variations)!

### Base - Just Primitives & Roblox!
- **[This repository](src/Base/src/init.luau) ~ [src/Base/src/init.luau](src/Base/src/init.luau)**
- **[Wally](<https://wally.run/package/coffilhg/createinstance>)**

    ```toml
    CreateInstance = "coffilhg/createinstance@0.1.1"
    ```
- **[Rotriever](<https://github.com/Coffilhg/Useful-Modules/releases/tag/vCreateInstance/0.1.1>)**

    ```toml
    CreateInstance = "github.com/Coffilhg/Useful-Modules@CreateInstance/0.1.1"
    ```

<!-- **[Creator Store](<https://create.roblox.com/store/category/gameplay?creatorName=coffilhg>)** ~ **[CreateInstance](<https://create.roblox.com/store/asset/123456789/CreateInstance>)**-->

### Coffee ~ Base + CoffeeObjects Support!
- **[This repository](src/CoffeeObjects/src/init.luau) ~ [src/CoffeeObjects/src/init.luau](src/CoffeeObjects/src/init.luau)**
- **[Wally](<https://wally.run/package/coffilhg/createinstancecoffee>)**

    ```toml
    CreateInstanceCoffee = "coffilhg/createinstancecoffee@0.1.1"
    ```
- **[Rotriever](<https://github.com/Coffilhg/Useful-Modules/releases/tag/vCreateInstanceCoffee/0.1.1>)**

    ```toml
    CreateInstanceCoffee = "github.com/Coffilhg/Useful-Modules@CreateInstanceCoffee/0.1.1"
    ```

<!-- **[Creator Store](<https://create.roblox.com/store/category/gameplay?creatorName=coffilhg>)** ~ **[CreateInstanceCoffee](<https://create.roblox.com/store/asset/123456789/CreateInstanceCoffee>)**-->

### Reaction ~ Base + Reaction Support!
- **[This repository](src/Reaction/src/init.luau) ~ [src/Reaction/src/init.luau](src/Reaction/src/init.luau)**
- **[Wally](<https://wally.run/package/coffilhg/createinstancereaction>)**

    ```toml
    CreateInstanceReaction = "coffilhg/createinstancereaction@0.1.1"
    ```
- **[Rotriever](<https://github.com/Coffilhg/Useful-Modules/releases/tag/vCreateInstanceReaction/0.1.1>)**

    ```toml
    CreateInstanceReaction = "github.com/Coffilhg/Useful-Modules@CreateInstanceReaction/0.1.1"
    ```

<!-- **[Creator Store](<https://create.roblox.com/store/category/gameplay?creatorName=coffilhg>)** ~ **[CreateInstanceReaction](<https://create.roblox.com/store/asset/123456789/CreateInstanceReaction>)**-->

## Basic Usage

```lua
const CreateInstance = require(`@game/ReplicatedStorage/Packages/CreateInstance`)
const Create, CreateMissing = CreateInstance:Unpack()

-- this does
-- Instance.new("Part")
-- apply properties
-- parent the Attachment (number indexed Instance) to the Part
-- parent the Part to workspace (always last)
const part = Create "Part" {
  Size = Vector3.new(10, 10, 10),
  Position = Vector3.new(0, 10, 0),
  Create "Attachment" {
    Name = "Center",
  },
  Parent = workspace,
}

-- if existingInstance is an Instance with the same ClassName,
-- it is returned as is (props are ignored);
-- otherwise this is the same as Create
const existingPart = workspace:FindFirstChild("SomePart")
const somePart = CreateMissing(existingPart) "Part" {
  Anchored = true,
  Parent = workspace,
}
```

just read the code, it's about 150 lines

---

## DEPENDENCIES (if any)

- **[ClassNameTypePairs](<https://github.com/Coffilhg/ClassNameTypePairs>)**

### Additional Dependencies (if using either extension version)

- **[CoffeeObjects](<>)**
- **[Reaction](<>)**

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