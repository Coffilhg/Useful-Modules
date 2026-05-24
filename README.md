# Useful-Modules
All or most of the Modules here should also be available on **Wally** and/or **https://create.roblox.com/store/category/gameplay?creatorName=coffilhg**

Feel free to suggest changes or make them yourself!
Each branch is a separate module/collection, the LICENSE may vary (but is mostly Apache-2.0). Please make sure to look into README/NOTICE files before use. If the LICENSE requires attribution or whatsoever, don't miss out!

## Quick Module Lookup

- **[Arrangement](<https://github.com/Coffilhg/Useful-Modules/tree/Arrangement>)**
- **[CoffeeObjects](<https://github.com/Coffilhg/Useful-Modules/tree/CoffeeObjects>)**

	> **[Useful-Modules/CoffeeObjects](<https://github.com/Coffilhg/Useful-Modules/tree/CoffeeObjects>)**
	> 
	> **Rotriever**        
	> ```toml        
	> CoffeeObjects = "github.com/Coffilhg/Useful-Modules@CoffeeObjects/2.3.0"        
	> ```
	> **[Wally](<https://wally.run/package/coffilhg/coffeeobjects>)**        
	> ```toml        
	> CoffeeObjects = "coffilhg/coffeeobjects@2.3.2"        
	> ```
- **[CoffeeParser](<https://github.com/Coffilhg/Useful-Modules/tree/CoffeeParser>)**

	> **[Useful-Modules/CoffeeParser](<https://github.com/Coffilhg/Useful-Modules/tree/CoffeeParser>)**
	> 
	> **Rotriever**        
	> ```toml        
	> CoffeeParser = "github.com/Coffilhg/Useful-Modules@CoffeeParser/1.0.2"        
	> ```
	> **[Wally](<https://wally.run/package/coffilhg/coffeeparser>)**        
	> ```toml        
	> CoffeeParser = "coffilhg/coffeeparser@1.0.2"        
	> ```
- **[CoffeeRemotes](<https://github.com/Coffilhg/Useful-Modules/tree/CoffeeRemotes>)**
- **[Counter](<https://github.com/Coffilhg/Useful-Modules/tree/Counter>)**
- **[EasySmoothDamp](<https://github.com/Coffilhg/Useful-Modules/tree/EasySmoothDamp>)**

	> **[Useful-Modules/EasySmoothDamp](<https://github.com/Coffilhg/Useful-Modules/tree/EasySmoothDamp>)**
	> 
	> **[Wally](<https://wally.run/package/coffilhg/easysmoothdamp>)**        
	> ```toml        
	> EasySmoothDamp = "coffilhg/easysmoothdamp@1.0.0"        
	> ```
- **[FirstPersonDetector](<https://github.com/Coffilhg/Useful-Modules/tree/FirstPersonDetector>)**

	> **[Useful-Modules/FirstPersonDetector](<https://github.com/Coffilhg/Useful-Modules/tree/FirstPersonDetector>)**
	> 
	> **Rotriever**        
	> ```toml        
	> FirstPersonDetector = "github.com/Coffilhg/Useful-Modules@FirstPersonDetector/1.0.0"        
	> ```
	> **[Wally](<https://wally.run/package/coffilhg/firstpersondetector>)**        
	> ```toml        
	> FirstPersonDetector = "coffilhg/firstpersondetector@1.0.0"        
	> ```
- **[GUICompatibility](<https://github.com/Coffilhg/Useful-Modules/tree/GUICompatibility>)**
- **[GreatUIDrag](<https://github.com/Coffilhg/Useful-Modules/tree/GreatUIDrag>)**
- **[HumanoidCameraOffsetController](<https://github.com/Coffilhg/Useful-Modules/tree/HumanoidCameraOffsetController>)**

	> **[Useful-Modules/HumanoidCameraOffsetController](<https://github.com/Coffilhg/Useful-Modules/tree/HumanoidCameraOffsetController>)**
	> 
	> **Rotriever**        
	> ```toml        
	> HumanoidCameraOffsetController = "github.com/Coffilhg/Useful-Modules@HumanoidCameraOffsetController/1.0.1"        
	> ```
	> **[Wally](<https://wally.run/package/coffilhg/humanoidcameraoffsetcontroller>)**        
	> ```toml        
	> HumanoidCameraOffsetController = "coffilhg/humanoidcameraoffsetcontroller@1.0.1"        
	> ```
- **[ServerMessages](<https://github.com/Coffilhg/Useful-Modules/tree/ServerMessages>)**

---

# Main branch is a template branch!

<!--
--- README's Template ---
# PascalCasedModuleName
ModuleDescription



## Available Here!
- **[This repository](src/init.luau) ~ [src/init.luau](src/init.luau)**
- **[Wally](<https://wally.run/package/coffilhg/modulenamelowercase>)**

    ```toml
    PascalCasedModuleName = "coffilhg/modulenamelowercase@ModuleVersion"
    ```
- **Rotriever**

    ```toml
    PascalCasedModuleName = "github.com/Coffilhg/Useful-Modules@PascalCasedModuleName/ModuleVersion"
    ```

<!-- **[Creator Store](<https://create.roblox.com/store/category/gameplay?creatorName=coffilhg>)** ~ **[PascalCasedModuleName](<https://create.roblox.com/store/asset/123456789/PascalCasedModuleName>)**-->
<!--

---

-- common sections in order: FEATURES, INSTALLATION, BASIC USAGE, API, NOTES

---

-- a placeholder if im too busy to make a full on detail README

## To-Do

- [ ] Expand the README

---

## DEPENDENCIES (if any)

- [Dependency Module Name PascalCase](<LinkToGitHubOrWallyOrSource>)

---

## License / License & Attribution

Licensed under the Apache License, Version 2.0.

You may use, modify, and redistribute this module freely, provided that the original copyright notice and license header at the top of the file are preserved.

See the [Apache License 2.0](LICENSE) for full terms.

Attribution to all dependencies is included in [Notice](NOTICE)

© 2026 Coffilhg
-->

<!--

--!strict
-- Auto Quick Module Lookup Generator to be used at https://play.luau.org/

type BranchInfo = {
  ["ModuleNamePascalCase"]: string,
  ["BranchName"]: string?, -- defaults to self.ModuleNamePascalCase
  ["License"]: string?, -- defaults to "Apache-2.0"
  ["Links"]: {
    [string]: { -- string is the ServiceName
      ["ServiceLink"]: string?, -- link for the ServiceName; Defaults to `https://wally.run/package/coffilhg/{modulenamelowercase}` for Wally; None for everything else.
      ["Format"]: string?, -- format for the codeblock: ```{Format}```; Defaults to toml
      ["Content"]: string?, -- content for the codeblock; Defaults to nil; If no Format and no Content is given - codeblock won't be generated.
      -- Link is invalidated if none of the available properties are specified.
    },
  }?,
}

local Branches: {[number]: BranchInfo} = {
    {
       ModuleNamePascalCase = "Arrangement"
    },
    {
       ModuleNamePascalCase = "CoffeeObjects",
       Links = {
        Wally = {
            Content = `CoffeeObjects = "coffilhg/coffeeobjects@2.3.2"`,
        },
        Rotriever = {
            Content = `CoffeeObjects = "github.com/Coffilhg/Useful-Modules@CoffeeObjects/2.3.0"`
        },
       },
    },
    {
       ModuleNamePascalCase = "CoffeeParser",
       Links = {
        Wally = {
            Content = `CoffeeParser = "coffilhg/coffeeparser@1.0.2"`,
        },
        Rotriever = {
          Content = `CoffeeParser = "github.com/Coffilhg/Useful-Modules@CoffeeParser/1.0.2"`
        },
       },
    },
    {
       ModuleNamePascalCase = "CoffeeRemotes"
    },
    {
       ModuleNamePascalCase = "Counter"
    },
    {
       ModuleNamePascalCase = "EasySmoothDamp",
       Links = {
        Wally = {
            Content = `EasySmoothDamp = "coffilhg/easysmoothdamp@1.0.0"`,
        },
       },
    },
    {
       ModuleNamePascalCase = "GUICompatibility"
    },
    {
       ModuleNamePascalCase = "GreatUIDrag"
    },
    {
       ModuleNamePascalCase = "ServerMessages"
    },
    {
      ModuleNamePascalCase = "HumanoidCameraOffsetController",
      Links = {
        Wally = {
            Content = `HumanoidCameraOffsetController = "coffilhg/humanoidcameraoffsetcontroller@1.0.1"`,
        },
        Rotriever = {
          Content = `HumanoidCameraOffsetController = "github.com/Coffilhg/Useful-Modules@HumanoidCameraOffsetController/1.0.1"`
        },
       },
    },
    {
      ModuleNamePascalCase = "FirstPersonDetector",
      Links = {
        Wally = {
            Content = `FirstPersonDetector = "coffilhg/firstpersondetector@1.0.0"`,
        },
        Rotriever = {
          Content = `FirstPersonDetector = "github.com/Coffilhg/Useful-Modules@FirstPersonDetector/1.0.0"`
        },
       },
    },
}

-- Sort Alphabetically
table.sort(Branches, function(a: BranchInfo, b: BranchInfo)
  return a.ModuleNamePascalCase < b.ModuleNamePascalCase
end)

local result = {}
local function Shorthand(moduleName: string, gitHubRepositoryLink: string)
  table.insert(result, `- **[{moduleName}](<{gitHubRepositoryLink}>)**`)
end

for _, branch in ipairs(Branches) do
  local moduleName: string = branch.ModuleNamePascalCase
  local moduleNameLowercase: string = moduleName:lower()
  local branchName: string = type(branch["BranchName"]) == "string" and branch["BranchName"] or moduleName
  
  local gitHubRepositoryLink = `https://github.com/Coffilhg/Useful-Modules/tree/{branchName}`

  local links = branch["Links"]
  if not links then
    Shorthand(moduleName, gitHubRepositoryLink)
    continue
  end

  local serviceLinks: {[number]: string} = {}
  for serviceName: string, details in pairs(links) do

    local serviceLink = details["ServiceLink"]
    if not serviceLink then
      if serviceName == "Wally" then
        serviceLink = `[Wally](<https://wally.run/package/coffilhg/{moduleNameLowercase}>)`
      end
    end

    local format = details["Format"] or "toml"
    local content = details["Content"]

    local serviceString = serviceLink and `	> **{serviceLink}**` or `	> **{serviceName}**`

    if content then
      serviceString = serviceString..[[
        
	> ```]]..`{format}`..[[
        
	> ]]..`{type(content) == "string" and content:gsub("\n", "\n	> ") or content}`..[[
        
	> ```]]
    end

    if not (serviceLink or content) then
      continue
    end
    table.insert(serviceLinks, serviceString)
  end

  table.insert(result, `- **[{moduleName}](<{gitHubRepositoryLink}>)**\n`)
  if #serviceLinks > 0 then
    table.insert(result, `	> **[Useful-Modules/{branchName}](<https://github.com/Coffilhg/Useful-Modules/tree/{branchName}>)**\n	> `)
  end
  table.insert(result, table.concat(serviceLinks, "\n"))
  
end

print(table.concat(result, "\n"))

print(table.concat(table.create(2, "\n"), "\n"))
-->