# Useful-Modules
All or most of the Modules here should also be available on **Wally** and/or **https://create.roblox.com/store/category/gameplay?creatorName=coffilhg**

Feel free to suggest changes or make them yourself!
Each branch is a separate module/collection, the LICENSE may vary (but is mostly Apache-2.0). Please make sure to look into README/NOTICE files before use. If the LICENSE requires attribution or whatsoever, don't miss out!

## Quick Module Lookup

- **[Arrangement](<https://github.com/Coffilhg/Useful-Modules/tree/Arrangement>)**
- **[CoffeeObjects](<https://github.com/Coffilhg/Useful-Modules/tree/CoffeeObjects>)**

	> **[Useful-Modules/CoffeeObjects](<https://github.com/Coffilhg/Useful-Modules/tree/CoffeeObjects>)**
    >
    > **[Wally](<https://wally.run/package/coffilhg/coffeeobjects>)**
    > ```toml
    >   CoffeeObjects="coffilhg/coffeeobjects@1.0.1"
    > ```
- **[CoffeeParser](<https://github.com/Coffilhg/Useful-Modules/tree/CoffeeParser>)**

	> **[Useful-Modules/CoffeeParser](<https://github.com/Coffilhg/Useful-Modules/tree/CoffeeParser>)**
    >
    > **[Wally](<https://wally.run/package/coffilhg/coffeeparser>)**
    > ```toml
    >   CoffeeParser="coffilhg/coffeeparser@1.0.1"
    > ```
- **[CoffeeRemotes](<https://github.com/Coffilhg/Useful-Modules/tree/CoffeeRemotes>)**
- **[Counter](<https://github.com/Coffilhg/Useful-Modules/tree/Counter>)**
- **[EasySmoothDamp](<https://github.com/Coffilhg/Useful-Modules/tree/EasySmoothDamp>)**

	> **[Useful-Modules/EasySmoothDamp](<https://github.com/Coffilhg/Useful-Modules/tree/EasySmoothDamp>)**
    >
    > **[Wally](<https://wally.run/package/coffilhg/easysmoothdamp>)**
    > ```toml
    >   EasySmoothDamp="coffilhg/easysmoothdamp@1.0.0"
    > ```
- **[GUICompatibility](<https://github.com/Coffilhg/Useful-Modules/tree/GUICompatibility>)**
- **[GreatUIDrag](<https://github.com/Coffilhg/Useful-Modules/tree/GreatUIDrag>)**
- **[ServerMessages](<https://github.com/Coffilhg/Useful-Modules/tree/ServerMessages>)**
---

**Main branch is a template branch!**

<!--
--- README's Template ---
# {Module Name}
PlaceholderDescription

---

## Available Here!
- **[This repository](src/init.luau) ~ [src/init.luau](src/init.luau)**
- **[Wally](<https://wally.run/package/coffilhg/modulenamelowercase>)**
```toml
ModuleName = "coffilhg/{modulenamelowercase}@{VERSION}"
```
<!-- - **[Creator Store](<https://create.roblox.com/store/category/gameplay?creatorName=coffilhg>)** ~ **[{Module Name}](<https://create.roblox.com/store/asset/114136223178149/CoffeeBaseValue>)**-->
<!--

---

-- common sections in order: FEATURES, INSTALLATION, BASIC USAGE, API, NOTES

---

-- a placeholder if im too busy to make a full on detail README

## To-Do

- [ ] Expand the README

---

## DEPENDENCIES (if any)

- [{Dependency Module Name}](<{LinkToGitHubOrWallyOrSource}>)

---

## License / License & Attribution

Licensed under the Apache License, Version 2.0.

You may use, modify, and redistribute this module freely, provided that the original copyright notice and license header at the top of the file are preserved.

See the [Apache License 2.0](LICENSE) for full terms.

Attribution to all dependencies is included in [Notice](NOTICE)

© 2026 Coffilhg-->


<!--
--!strict
-- Auto Generator to be used at https://play.luau.org/

local Branches = {
    [1] = {
       ["BranchName"] = "Arrangement",
       ["License"] = "Apache-2.0",
       ["ModuleName"] = "Arrangement"
    },
    [2] = {
       ["BranchName"] = "CoffeeObjects",
       ["License"] = "Apache-2.0",
       ["ModuleName"] = "CoffeeObjects",
       ["Wally"] = `CoffeeObjects="coffilhg/coffeeobjects@1.0.1"`
    },
    [3] = {
       ["BranchName"] = "CoffeeParser",
       ["License"] = "Apache-2.0",
       ["ModuleName"] = "CoffeeParser",
       ["Wally"] = `CoffeeParser="coffilhg/coffeeparser@1.0.1"`
    },
    [4] = {
       ["BranchName"] = "CoffeeRemotes",
       ["License"] = "Apache-2.0",
       ["ModuleName"] = "CoffeeRemotes"
    },
    [5] = {
       ["BranchName"] = "Counter",
       ["License"] = "Apache-2.0",
       ["ModuleName"] = "Counter"
    },
    [6] = {
       ["BranchName"] = "EasySmoothDamp",
       ["License"] = "Apache-2.0",
       ["ModuleName"] = "EasySmoothDamp",
       ["Wally"] = `EasySmoothDamp="coffilhg/easysmoothdamp@1.0.0"`
    },
    [7] = {
       ["BranchName"] = "GUICompatibility",
       ["License"] = "Apache-2.0",
       ["ModuleName"] = "GUICompatibility"
    },
    [8] = {
       ["BranchName"] = "GreatUIDrag",
       ["License"] = "Apache-2.0",
       ["ModuleName"] = "GreatUIDrag"
    },
    [9] = {
       ["BranchName"] = "ServerMessages",
       ["License"] = "Apache-2.0",
       ["ModuleName"] = "ServerMessages"
    }
}

-- Sort Alphabetically
table.sort(Branches, function(a, b)
  return a.ModuleName < b.ModuleName
end)

local result = {}
for _, branch in ipairs(Branches) do

  if not branch["BranchName"] then
    branch["BranchName"] = branch.ModuleName
  end
  
  local wallyLinking = branch["Wally"]
  if type(wallyLinking) ~= "string" or wallyLinking == "❌" then
    table.insert(result, `- **[{branch.ModuleName}](<https://github.com/Coffilhg/Useful-Modules/tree/{branch.BranchName}>)**`)
    continue
  end

  table.insert(result, [[- **[]]..branch.ModuleName..[[](<https://github.com/Coffilhg/Useful-Modules/tree/]]..branch.BranchName..[[>)**

	> **[Useful-Modules/]]..branch.BranchName..[[](<https://github.com/Coffilhg/Useful-Modules/tree/]]..branch.BranchName..[[>)**
    >
    > **[Wally](<https://wally.run/package/]]..( wallyLinking:match(`".+%@`) and wallyLinking:match(`".+%@`):sub(2, -2) or "coffilhg/"..branch.BranchName:lower())..[[>)**
    > ```toml
    >    ]]..wallyLinking..[[

    > ```]])
end

print(table.concat(result, "\n"))

-->