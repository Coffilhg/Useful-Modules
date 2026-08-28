# NamespaceSync

Inspired by **[CoffeeRemotesRefined](<https://github.com/Coffilhg/Useful-Modules/tree/CoffeeRemotesRefined>)**, where similar approach was first invented and used.

This module is a great utility if you need "singleton-like" (deduplicated) Instances, e.g. your Client and Server modules need a shared folder for their Project state or your custom Plugin should always output in a predictable place.

This module will take care of this! **[Read below...](#basic-usage)**



## Available Here!
- **[This repository](src/init.luau) ~ [src/init.luau](src/init.luau)**
- **[Wally](<https://wally.run/package/coffilhg/namespacesync>)**

    ```toml
    NamespaceSync = "coffilhg/namespacesync@0.0.1"
    ```
- **[Rotriever](<https://github.com/Coffilhg/Useful-Modules/releases/tag/vNamespaceSync/0.0.1>)**

    ```toml
    NamespaceSync = "github.com/Coffilhg/Useful-Modules@NamespaceSync/0.0.1"
    ```

<!-- **[Creator Store](<https://create.roblox.com/store/category/gameplay?creatorName=coffilhg>)** ~ **[NamespaceSync](<https://create.roblox.com/store/asset/123456789/NamespaceSync>)**-->

---

## Basic Usage

### What is a [namespace](<https://en.wikipedia.org/wiki/Namespace>)
Click the link and find out.

In general this README and the module refer to namespace / descriptor as the following definition:
- Name + ClassName + metadata => the Instance identity
- `where` + `isRecursive` => search scope and strategy

where metadata is either the default one provided, or a custom set via Validator and Mutator modifiers. Such custom set metadata can also be none.

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

If multiple matching Instances are found, the first match`*` is returned, all further matches are parented to nil and scheduled for destruction via `Debris:AddItem()` in 180 seconds. And a warning function (by default it's Roblox' `warn`) is called with references to the destroyed Instances. You can overwrite the warning function callback via `NamespaceSync:SetWarnCallback`.

> "the first match`*`" - means the first encountered during `GetChildren` or `GetDescendants` iteration, not necessarily deterministic/ordered like oldest/newest/etc.  

> The module doesn't enforce a universal singleton. It deduplicates matching instances within the searched `where` instance, based on name/class + optional validation.

This describes the initial idea this served, on server-side you'd do
```lua
-- making a Folder
const MainFolder = NamespaceSync:mkdir(
    "1.2.3", -- projectVersion
	"ReplicationService", -- name
	-- where: Instance? -- this is where to search for the Instance with matching specifications and where a new one will be parented in case no matches are found; defaults to ReplicatedStorage
	-- isRecursive: boolean?, -- this is whether we should search all DESCENDANTS (:GetDescendants) of where, defaults to false and searches only the direct children (:GetChildren)
	-- debugPrefix: (string | any)? -- every warning emitted by the module starts with `{debugPrefix} `
)
```
and then on client-side you'd indefinitely await for the folder until server creates it (this yields similarly to `:WaitForChild`, while also supporting custom validation and recursive searches)
> the projectVersion and name must be matching
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
now parent any instances inside, you can be almost certain this never overlaps with modules or projects of other developers and different versions of your own module/project.

This is especially good if dependencies are not deduplicated: they get automatic isolation between versions, provided their namespace descriptors do not intentionally collide.

For a further example, see **[CoffeeRemotesRefined](<https://github.com/Coffilhg/Useful-Modules/tree/CoffeeRemotesRefined>)**, the server-side init.luau and client-side init.luau (the links are there at the top of its README)
> as of now, CoffeeRemotesRefined latest is not yet using NamespaceSync, but is using its prototype. This line will be removed once it is updated to use NamespaceSync.



And maybe you don't want a **Folder**, maybe you want a **Model** or an **ArcHandles** for whichever reason, sure, anything that **Instance.new** supports is supported, just use
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
> make sure everything is matching! (name, projectVersion, ClassName, how and where it's parented, i.e. matching `where` and `isRecursive`)
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

So you end up with name + ClassName + a tag + a specific attribute name with a specific value

Such combination makes it quite unique, but if that's not enough or too much (e.g. you only want the name + ClassName without tag & attribute metadata), this module still has you covered:

### Use it more

All GetOrCreate and Await variants (including mkdir and cd) always validate for name + ClassName.
> (And validate indirectly for the `where` parent + in some cases whether `isRecursive` is used, because these two define where and how the search is performed)

You can set custom modifiers or keep default of no modifiers to get name + ClassName, (where and how it's parented too, but) nothing else.

More in detail about modifiers below.

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

There are two types of modifiers. A validator and a mutator.

You can use none, either one of or both of them for `:GetOrCreateManual`.

You can use a validator or nothing for `:AwaitManual`.

The type definitions are as follows:

```lua
export type ValidatorModifier = (Instance) -> boolean
export type MutatorModifier = (Instance) -> ()
export type GetOrCreateModifiers = {
	Validator: ValidatorModifier?,
	Mutator: MutatorModifier?,
}
export type AwaitModifiers = {
	Validator: ValidatorModifier?,
}
```

- **Validator** callback
  Every time a match by name + ClassName is found, it is passed to the validator callback if given. A boolean return value is expected for the callback.

  `true` means "this instance matches all of our additional criteria on top of name + ClassName", `false` means "this isn't a match, keep searching".
  
  For an example of such you can see `:GetOrCreate` ([here](<https://github.com/Coffilhg/Useful-Modules/blob/NamespaceSync/src/init.luau#:~:text=const%20function%20GetOrCreate>)) and `:Await` ([here](<https://github.com/Coffilhg/Useful-Modules/blob/NamespaceSync/src/init.luau#:~:text=const%20function%20Await>)) methods, they implement tag + attribute metadata on top of name + ClassName

- **Mutator** callback
  It is the opposite of the **Validator**, this one is only used by `:GetOrCreate` methods, only in case there were no matches found.
  
  It is called with a newly created Instance, before the Instace is parented. Mutate the Instance in a way it passes your **Validator**.

  For an example of such you can see `:GetOrCreate` ([here](<https://github.com/Coffilhg/Useful-Modules/blob/NamespaceSync/src/init.luau#:~:text=const%20function%20GetOrCreate>))

---

## Notes

1. As already stated in **[Server Unit tests of CoffeeRemotesRefined](<https://github.com/Coffilhg/Useful-Modules/blob/CoffeeRemotesRefined/src/Test/ServerScriptService/ServerMain/init.server.luau>)**:
    > **things left untested**
    > 
    > "mkdir and mkremote tested for exact spoofing at runtime;
    > That would likely fail, unless we over-engineer and introduce scoring for folders and checks for usage in existing remote objects. ..."

    > (tldr: this module does not guarantee runtime stability if it is poorly used)

    i.e. if multiple scripts misuse (e.g. reuse same descriptors) or spoof the namespace metadata, the module does not guarantee logical correctness of "keep the actually used Instance", because
    
    A: that'll be overengineering

    B: it isn't CoffeeRemotesRefined with a clear structure of Folders that store RemoteInstances of a specific kind, since this module allows any Instances creatable via `Instance.new`, we also have no clarity over what exactly to count toward a match's score, even if we tried to implement a scoring based deduplication.



    NamespaceSync is primarily intended for startup-time creation and/or "one creates, everyone else awaits" pattern. Also this isn't a scary limitation:

    The following two are actually resolved silently
    - Same project, different versions? - each gets their own "Main" Instance
    - Different projects, same version? - if their names don't overlap, they're isolated. If they use the same name/class and search scope, they will resolve to the same matching Instance rather than NamespaceSync destroying one of them, the module doesn't know they're different projects, it simply sees identical descriptors. Well because, just read further...
    
    This is only a concern when you have Spoofed the Instances, so that there are multiple matches. The module itself will never produce such deduplication, it will however eliminate such, if detected during any of GetOrCreate variations (including mkdir)

2. It is advised, if you think your project name is commonly used, to include a UUID in either your project' name or projectVersion, although the latter is better kept SemVer / bare version string.

    **For example, using `{projectName}_{UUID}` as the name for created Instances makes accidental collisions with other projects using NamespaceSync extremely unlikely.** Deliberate spoofing is still possible. This module just [makes risky activities less risky, because you'd do it anyways](<https://medium.com/@sdboyer/so-you-want-to-write-a-package-manager-4ae9c17d9527#:~:text=People%20are%20going%20to%20do%20risky%20activities.%20Instead%20of%20saying%20YOU%E2%80%99RE%20WRONG%20TO%20DO%20THAT%20JUST%20DON%E2%80%99T%20DO%20THAT,%20we%20can%20choose%20to%20help%20make%20those%20activities%20less%20risky.>), you keep your freedom.

    This UUID idea comes from how Minecraft Bedrock Add-Ons are created.

### Why do default `:GetOrCreate` and `:Await` use the metadata they use

Having an instance have a distinct (1) **Name**, (2) **ClassName**, (3) **Tag** and (4 & 5) **Attribute**, with both highly specific name and value; (6) **Parent**`*` and in some cases even (7) **whether isRecursive is used**`*` - this is more than enough to give an Instance a highly specific identity within the selected search scope, making it "`*`*Unique*`*`". Magic!

> **Parent**`*` & **whether isRecursive is used**`*` aren't directly validated, but they define the scope and method of searching, which is important.

Why tag and attribute were chosen? They replicate with the Instance, making them useful for communicating the namespace identity between server-client and are unlikely to be changed/impacted by other scripts during runtime. If some obscure/usually-unused properties were chosen instead, there'd be a higher risk of them changing, making the initially "Unique" matching Instance, stop matching until the initial attributes of it's "Uniqueness" are fully recovered.

Feels like too much or too little? Use `:GetOrCreateManual` and `:AwaitManual` with custom modifier options, this is documented [above](#use-it-more)


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
