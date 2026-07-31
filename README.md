# CoffeeParser

A module created specifically for the purpose of storing unsupported datatypes into datastores easier and more effective than just tables - string values!

Encode tables full of Roblox Datatypes into primitive tables and Decode primitive tables back into those full of Roblox Datatypes.

Created with the idea that we have only 4MiB per key in datastores and no native support for Roblox specific datatypes, such as Color3, UDim2, Vector3 and more ([see full SupportedTypesList](src/init.luau#L88)).

---

## Available Here!
- **[This repository](src/init.luau) ~ [src/init.luau](src/init.luau)**
- **[Wally](<https://wally.run/package/coffilhg/coffeeparser>)**

    ```toml
    CoffeeParser = "coffilhg/coffeeparser@1.0.5"
    ```
- **Rotriever**

    ```toml
    CoffeeParser = "github.com/Coffilhg/Useful-Modules@CoffeeParser/1.0.5"
    ```

<!-- **[Creator Store](<https://create.roblox.com/store/category/gameplay?creatorName=coffilhg>)** ~ **[CoffeeParser](<https://create.roblox.com/store/asset/114136223178149/CoffeeBaseValue>)**-->

## To-Do

- [x] Minify the datatype prefix codes.
- [ ] Add support to allow SupportedTypes act as table keys/indexing
- [ ] Add handlers for types (if possible): Axes, Faces, Region3, Region3int16, Vector2int16, Vector3int16, PhysicalProperties, DateTime, FloatCurveKey, RotationCurveKey, ValueCurveKey, TweenInfo, CatalogSearchParams
- [ ] Expand the README

---

## License / License & Attribution

Licensed under the Apache License, Version 2.0.

You may use, modify, and redistribute this module freely, provided that the original copyright notice and license header at the top of the file are preserved.

See the [Apache License 2.0](LICENSE) for full terms.

© 2025 Coffilhg