# NamespaceSync

Inspired by **[CoffeeRemotesRefined](<https://github.com/Coffilhg/Useful-Modules/tree/CoffeeRemotesRefined>)**, where similar approach was first invented and used.

This module is a great utility if you need "singletone" Instances, e.g. your Client and Server modules need a shared folder for their Project state or your custom Plugin should always output in a predictable place.

This module will take care of this! **[Read below...](#basic-usage)**



## Available Here!
- **[This repository](src/init.luau) ~ [src/init.luau](src/init.luau)**
- **[Wally](<https://wally.run/package/coffilhg/namespacesync>)**

    ```toml
    NamespaceSync = "coffilhg/namespacesync@0.0.0"
    ```
- **[Rotriever](<https://github.com/Coffilhg/Useful-Modules/releases/tag/vNamespaceSync/0.0.0>)**

    ```toml
    NamespaceSync = "github.com/Coffilhg/Useful-Modules@NamespaceSync/0.0.0"
    ```

<!-- **[Creator Store](<https://create.roblox.com/store/category/gameplay?creatorName=coffilhg>)** ~ **[NamespaceSync](<https://create.roblox.com/store/asset/123456789/NamespaceSync>)**-->

---

## Basic Usage

### Require the module
> all uses of `NamespaceSync` in code examples below refer to this
```luau
const NamespaceSync = require(`@game/ReplicatedStorage/Packages/NamespaceSync`)
```

### Use the module
Provided a name and project version string, it will find an existing or create a new Folder (or instance of a given ClassName) with the following:
- Name = input name
- ClassName = Folder or whichever was input
- Tag = `{name}_{projectVersion}`
- Attribute `{name}V` = `{name}_{projectVersion}`
> The attribute name will be made safe automatically to comply with [these Limits](<https://create.roblox.com/docs/en-us/reference/engine/classes/Instance#SetAttribute>)

This describes the initial idea this served, on server-side you'd do
```lua
-- making a Folder
const MainFolder = NamespaceSync:mkdir(
    "1.2.3", -- projectVersion
	"ReplicationService", -- name
	-- where: Instance? -- this is where to parent if there was no ReplicationService Folder with matching metadata; defaults to ReplicatedStorage
	-- isRecursive: boolean?, -- this is whether we should search all DESCENDANTS (:GetDescendants) of where, defaults to false and searches onle the direct children (:GetChildren)
	-- debugPrefix: (string | any)? -- every warning emitted by the module starts with `{debugPrefix} `
)
```
and then on client-side you'd indefinitely await for the folder until server creates it
```lua
-- awaiting a Folder
const MainFolder = NamespaceSync:cd(
    "1.2.3", -- projectVersion
	"ReplicationService", -- name
	-- where: Instance? -- same as above
	-- isRecursive: boolean?, -- same as above + it also determines `:FindFirstX` and `.XAdded:Connect` usage. The point is the same: if isRecursive - search and await a matching descendant of where, otherwise (false or default) - search and await a matching child of where
	-- debugPrefix: (string | any)? -- same as above
    -- yieldWarningTime: number? -- imagine you made a typo somewhere and now it silently yields (waits) indefinitely (forever),
    -- yieldWarningTime got you covered, if nothing is found in yieldWarningTime seconds, a warning is emitted, defaults to 15
)
```
now parent any instances inside, you can be almost certain this never overlaps with modules or projects of other developers and different versions of your own module/project. This is especially good if dependencies are intentionally not deduplicated, but use this, achieving foolproof isolation.

And maybe you don't want a **Folder**, maybe you want a **Model** or an **ArcHandles** for whichever reason, sure, anything that **Instance.new** supports, just use
```lua
-- making your whatever ClassName
const MainWhatever = NamespaceSync:GetOrCreate(
    className, -- any class name supported by Instance.new
    -- everything else as in :mkdir above, i.e.
    projectVersion, -- obligatory, same as above
    name, -- obligatory, same as above
    where, -- optional, same as above
    isRecursive, -- optional, same as above
    debugPrefix -- optional, same as above
)
```
and in a different script
```lua
-- awaiting for your whatever ClassName
const MainWhatever = NamespaceSync:Await(
    className, -- value .ClassName property of the object you created using :GetOrCreate
    -- everything else as in :cd above, i.e.
    projectVersion, -- obligatory, same as above
    name, -- obligatory, same as above
    where, -- optional, same as above
    isRecursive, -- optional, same as above
    debugPrefix, -- optional, same as above
    yieldWarningTime -- optional, same as above
)
```

So you end up with name + ClassName + a tag + a specific attribute name with a specfic value

Such combination makes it quite unique, but if that's not enough or too much (e.g. you only want the name + ClassName without tag & attribute metadata), this module still has you covered:

### Use it more

GetOrCreateManual always validates for name + ClassName.

You can set custom modifiers or keep no modifiers - you only have name + ClassName, nothing else.

```lua
const YouNameIt = NamespaceSync:GetOrCreateManual(
    className,
    name,
    where,
    modifiers,
    isRecursive,
    debugPrefix
)
```

```lua
const YouNameIt = NamespaceSync:AwaitManual(
    className,
    name,
    where,
    modifiers,
    isRecursive,
    debugPrefix,
    yieldWarningTime
)
```

---

## To-Do

- [ ] Expand the README

---

## DEPENDENCIES

- [ClassNameTypePairs](<https://github.com/Coffilhg/ClassNameTypePairs>)
- [LemonSignal](<https://github.com/Data-Oriented-House/LemonSignal>)

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