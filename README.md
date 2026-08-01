# ☕ CoffeeRemotes (Refined)

CoffeeRemotes (**Refined**) is a lightweight QoL wrapper for Remote Instances - RemoteEvent, RemoteFunction and UnreliableRemoteEvent Instances;

Adds easily configurable Cooldowns for the Client -> Server traffic;

No more path defitions needed, simply do `CoffeeRemotes.[RemoteEvent | RemoteFunction | UnreliableRemoteEvent].new("Example")` on both the server and client side to enable communication thereof, the wrapper will automatically find the Remote Instance;

This erases the need to write the full path to remote or even keep track of how to organize it, the module will warn you if you've used the same name for a remote of the same kind already.+

Please make sure you're using both the Server-Side part of CoffeeRemotes (Refined) AND Client-Side part of CoffeeRemotes (Refined), otherwise it's useless!

All tests have passed. You can see the summary in the [LatestTestSummary.md](<LatestTestSummary.md>). There are some cases left untested, please see the **`### Known Limitations`** section.

---

## Some history

> (The original Description)
~~CoffeeRemotes multiplexes events through **one shared Remote per type**, keyed by `eventName`. It is **not** a wrapper around Instances per event.~~

**This is derived/forked from CoffeeRemotes;**

**Legacy CoffeeRemotes will not be published on wally or anywhere else, it will simply remain public [here](<https://github.com/Coffilhg/Useful-Modules/tree/CoffeeRemotes>)**

Reason for the change: unnecessary additional per-call bandwidth data cost. Previously there were just three Instances: `CoffeeRemotes_Event`, `CoffeeRemotes_Function` and `CoffeeRemotes_Unreliable`; Everything was fired through them, and the first argument passed would always be the `eventName`;

Since it is a *string*, it's usual cost, with words around 10 Characters long would be `10 bytes + type header` **additional cost per-call**, it simply scales like `#string * byte`, so with words around 20 characters, we'd get `20 bytes + type header` **additional cost per-call** and so on.

**No Rotriever support is planned for CoffeeRemotes (Refined)** - though feel free to suggest on how to implement it.

Even if we used *numbers* instead, that'd usually land around `8 bytes + type header`

---

Now with a new approach we will create a new Instance per `eventName`.

Limitations apply: if `eventName` is taken by any remote Instance type X, it can not be used again for another remote Instance type X.

i.e. if there's already a `HelloWorld` RemoteFunction, creating a new RemoteFunction with name `HelloWorld` will simply return the already existing one and yield a warning, because it's a bad practice, however you can still have a RemoteEvent and an UnreliableRemoteEvent named `HelloWorld` at the same time.

Client will yield WaitForChild like as long as the remote is not there, if it yields for too long, a dedicated warning will be output. This will protect you from typos silently failing!

---

But I mean, you could still use Legacy CoffeeRemotes - they make it harder for exploiters to figure out what's out there at all - they can see no actual Remote Names, except those they've fired and were able to intercept with a dedicated Remote Spy script.

---

## Features

* **Chainable API** (`:SetCooldown():Connect()`)
* **Legacy-compatible API surface**
* **Supports UnreliableRemoteEvent**

---

## Installation

1. Place **CoffeeRemotesRefined (Server-Side)** in `ServerScriptService`
> **Get CoffeeRemotesRefined (Server-Side) at**
> - **[This repository (src/Server/scr/init.luau)](<src/Server/src/init.luau>)**
> - **[Wally](<https://wally.run/package/coffilhg/coffeeremotes-server>)**
>	>	```toml
>	>	CoffeeRemotesServer = "coffilhg/coffeeremotes-server@1.0.1"
>	>	```

2. Place **CoffeeRemotesRefined (Client-Side)** where needed on the client
> **Get CoffeeRemotesRefined (Client-Side) at**
> - **[This repository (src/Client/src/init.luau)](<src/Client/src/init.luau>)**
> - **[Wally](<https://wally.run/package/coffilhg/coffeeremotes-client>)**
>	>	```toml
>	>	CoffeeRemotesClient = "coffilhg/coffeeremotes-client@1.0.1"
>	>	```
3. Ensure [**LemonSignal** ( https://github.com/Data-Oriented-House/LemonSignal )](<https://github.com/Data-Oriented-House/LemonSignal>) is available as a dependency
4. Require **CoffeeRemotesRefined (Server-Side)** module **once** on startup (required for **CoffeeRemotesRefined (Client-Side)** to load)

*Wally Release 0.0.0 for CoffeeRemotesClient is not stable (and misconfigured) and should not be used.*

```lua
-- Server
local CoffeeRemotes = require(path.to.CoffeeRemotesServer)
```

This automatically creates the directories (folders) for Remote Instances in `ReplicatedStorage`:

![Example image showcases new Folder Instances created in ReplicatedStorage after running the example code in the Roblox Studio Explorer Tab. THe main Folder is named with a concatenation result of the current Prefix defined in the CoffeeRemotesRefined (Server-Side) with a literal "RemotesFolder", in the example image this happens to be "CoffeeRemotesRefined". The main Folder is a parent to a Folder for each Kind of Remote Instances, named "Events" for RemoteEvent Instances, "Functions" for RemoteFunction Instances and "UnreliableEvents" for UnreliableRemoteFunction Instances respectfully](./images/example.png "Folders")

Now you can load the client-side. Client-side yields (waits) forever until you load the server-side.

```lua
-- Client
local CoffeeRemotes = require(path.to.CoffeeRemotesClient)
```

---

## Chainability

Most methods return `self`, allowing fluent usage:

```lua
CoffeeRemotes.RemoteEvent
	.new("JumpRequest") -- client fires this every time player clicks the jump button
	:SetCooldown(0.25) -- players can spam jump, but it will only trigger the
	:Connect(function(player : Player, ...) -- function once per Set cooldown
		...
	end)
```

Chainability is intentional and consistent across:

* `RemoteEvent`
* `RemoteFunction`
* `UnreliableRemoteEvent`

---

## Replacing Legacy RemoteEvents, RemoteFunctions and UnreliableRemoteEvents

### Old (Legacy)

```lua
local RS = game:GetService("ReplicatedStorage")
local exampleEvent = RS:WaitForChild("ExampleRemoteEvent")

exampleEvent.OnServerEvent:Connect(function(player : Player, value)
	print(value)
end)
```

### New (CoffeeRemotes)

```lua
local exampleEvent = CoffeeRemotes.RemoteEvent.new("ExampleRemoteEvent")
	-- optional: :SetCooldown(0.05)

exampleEvent.OnServerEvent:Connect(function(player : Player, value)
	print(value)
end)
```

It's just as simple as replacing `RS:WaitForChild("ExampleRemoteEvent")` to a corresponding remote type .new (e.g. `CoffeeRemotes.RemoteEvent.new("ExampleRemoteEvent")`). All of the other old code is supported by the API. Only the `:ConnectParallel()` method is missing, because it is not implemented in **LemonSignal** used by this module.

**Important:**
If you're replacing legacy remotes. You must migrate **both server and client** to CoffeeRemotes in order for the replacement to work.

Legacy Instances are no longer used.
> (They are but under the hood, by the module, you get to enjoy faster typing)

---

## Legacy Compatibility Notes

To ease migration, CoffeeRemotes exposes legacy-like fields:

**Server-Side**
* `RemoteEvent.OnServerEvent`
* `RemoteFunction.OnServerInvoke`
* `UnreliableRemoteEvent.OnServerEvent`

**Client-Side**
* `RemoteEvent.OnClientEvent`
* `RemoteFunction.OnClientInvoke`
* `UnreliableRemoteEvent.OnClientEvent`

These exist **only for autocomplete and migration**. They point back to the object itself (**self**) for RemoteEvent and UnreliableRemoteEvent.

⚠️ **Do not use them in new code.**

They forward internally but can cause confusing autocomplete. And this is also a table access, if you care about micro-optimizing your scripts, forget about using those!

---

## RemoteFunction Behavior

RemoteFunction callbacks should return:

```lua
(success : boolean, result : table | value)
```

Example:

```lua
CoffeeRemotes.RemoteFunction
	.new("Example")
	.OnServerInvoke = function(player : Player)
		return true, { "Example" }
	end
```

Only two return values are expected for consistency: a success status boolean and a single result value.

However you can drop that principle, just remember that failed requests such as cooldown throttles or unregistered callbacks return false and an array/tuple with the exit reason.

---

## Cooldowns

Cooldowns are **per CoffeeRemotesObject per Player**.

Hardcoded Defaults:

* `RemoteEvent` → `0.03s`
* `RemoteFunction` → `0.03s`
* `UnreliableRemoteEvent` → `0.01s`

```lua
CoffeeRemotes.RemoteEvent
	.new("JumpRequest")
	:SetCooldown(0.25)
```

**Passing nil or nothing fallbacks to 0, it doesn't revert to the default value**
```lua
CoffeeRemotes.RemoteEvent
	.new("HelloWorld")
	:SetCooldown() -- now the cooldown is 0
```

**The defaults can be adjusted via**
```lua
-- export type KindOf = "RemoteEvent" | "RemoteFunction" | "UnreliableRemoteEvent"
CoffeeRemotes:SetDefaultCooldown(kindOf: KindOf, newDefault: number?)
-- all CoffeeRemoteObjects of the given kind created after this call
-- will have the given newDefault cooldown time by default
-- if given newDefault is nil or type(newDefault) ~= `number`, it will
-- default to the hardcoded defaults (see above)
```

---

## Destruction Semantics

Calling `:Destroy()`:

* disconnects all signals
* removes cooldown data
* removes registry references
* invalidates the object

Any further access throws errors.

This is **intentional**.

---

## `CoffeeRemotes:Unpack()`

Exists on both the Server and Client-Side of the module, solely as a QoL method, so that instead of scripting
```lua
local RemoteEvent, RemoteFunction, URemoteEvent =
	CoffeeRemotes.RemoteEvent,
	CoffeeRemotes.RemoteFunction,
	CoffeeRemotes.UnreliableRemoteEvent
```

you would simply use `:Unpack()`

```lua
local RemoteEvent, RemoteFunction, URemoteEvent = CoffeeRemotes:Unpack()
```

---

## Infinite Wait (Yield) Warning [Client-Side]

On CoffeeRemotesRefinedClient when creating a CoffeeRemoteObject, it will wait indefinitely until the matching RemoteInstance is found using a custom implementation (without using `:WaitForChild()`); Folders are queried likewise on first require.

If a matching Folder/RemoteInstance is not found after `YieldWarningTime` seconds, a warning will be output and it will continue waiting for a match.

You can adjust `YieldWarningTime` via `CoffeeRemotesRefinedClient:SetYieldWarningTime(newYieldWarningTime)`

Defaults to 15 whenever newYieldWarningTime is NaN, math.huge (inf) or it's type() ~= `number`

While this does change the `YieldWarningTime` for every further `.new` creation of a CoffeeRemotesObject, it does not affect folder querying, because it happens on require, not afterwards.

---

## Notes & Architectural Decisions

### Installation & Versioning
- **CoffeeRemotesRefined Client-Side** yields (waits) indefinitely until **CoffeeRemotesRefined Server-Side** is initialized.
- **Server and Client versions must match.** Both have hardcoded `ModuleVersion = "V1_0_0"`, `MainFolderName`, `ModuleFoldersTag` and the three subfolder names (`Events`, `Functions`, `UnreliableEvents`). If they differ, the client will hang waiting for folders that never get tagged correctly. As long as you don't change those - good to go!
- Requiring **Server-Side of the module via Client-Sided scripts yields an error** and vice-versa.

### Cooldowns

**Cooldown timestamps are only recorded while cooldown > 0**; If a remote runs at 0 cooldown for a while and is later raised, the first call after the raise is *not* rate-limited (there's no prior timestamp to compare against). The first post-change (e.g. from 0 -> 0.3 seconds cooldown) call is not throttled.

This is needed to do no additional table allocations for CoffeeRemoteObjects with Cooldown of 0!



Cooldowns are tracked **per player, per CoffeeRemoteObject name, per kind** using `os.clock()`;

You can access them via `CoffeeRemotes.PlayerCooldowns` on Server-Side. Whenever a Player leaves (`Players.PlayerRemoving`), their cooldowns will be cleaned, but with a backup available via connecting to the `CoffeeRemotes.BackUpPlayerCooldowns` signal. If it is important to throttle a player even after they rejoin, this is useful. This wasn't implemented in the module, because then we'd have to handle sharing those coldowns across all servers.

Cooldowns only exist for the incoming traffic to the Server-Side - anything that clients send to the server. Client-Side doesn't have anything built-in to throttle traffic sent by server.

### Remote Function Exit Reasons (RFER)

Whenever a client does `:InvokeServer()`, there's three built-in cases that will return `(false, RFER)`:
- RFER_TooQuick = `{"Sending Requests Too Quickly!"}`
- RFER_NotFound = `{'OnServerInvoke/OnInvoke Callback for name="{name}" doesn't exist; Object and it's RemoteFunction Instance:', object, rawget(object :: any, "_RI")}`
- RFER_PlayerLeft `{"Player Has Left"}`
You should not rely on those messages in production, because for security reasons all of them will be replaced with **RFER_TooQuick** outside of Studio.

### Object Lifecycle & API Surface
- `.Remote` and `.Destroying` are **read-only** public fields on all CoffeeRemoteObjects. Any attempted write is intercepted by `__newindex`, produces a warning (`"Nothing should be stored inside a..."`), and is silently ignored, it does not error and does not change the value.
- CoffeeRemoteObjects do not self-destroy automatically when the RemoteInstance is **destroyed** or **reparented** elsewhere.
- `Remote` field shall be used to detect the **destruction** and **reparenting** of the RemoteInstance via `.Destroying` and `.AncestryChanged` signals.
- `CoffeeRemoteObject.Destroying` is fired whenever you call `CoffeeRemoteObject:Destroy()`, `CoffeeRemoteObject.Remote.Destroying` is fired whenever the RemoteInstance is Destroyed.
- `RemoteFunction.OnInvoke` and `RemoteFunction.[OnServerInvoke | OnClientInvoke]` are **aliases for the same underlying storage** - setting one immediately "updates" what the other reads. Only a `function` or `nil` is accepted; anything else warns and the write is ignored (value stays unchanged).

### Known Limitations
- Client receiving `(false, RFER_PlayerLeft)` from `:InvokeServer` is **not covered by the automated tests**
- `mkdir`/`mkremote` are only tested against spoofing that happens **at startup** (before the real module runs). These are not over-engineered to handle such cases based on which instances are already at use, because this safety is likely never to be used. This only happens if you initialize the module, make remotes, then some time later make a copy of the already used folders, copy of the module and require that copy.
- Tables with **cyclic references cannot be sent as remote payloads**, Roblox itself raises `"tables cannot be cyclic"`; CoffeeRemotesRefined does not detect or strip cyclic table references for you by design, to avoid paying a per-call recursive-scan cost on every fire/invoke. Same goes for all other **[unsupported types by RemoteInstances as listed on the documentation here](<https://create.roblox.com/docs/en-us/scripting/events/remote#argument-limitations>)**.
- Creation of a new CoffeeRemoteObject automatically creates a connection on the RemoteInstance (`.On[Server | Client]Event` for BaseRemoteEvent Subtypes and `.On[Server | Client]Invoke` for RemoteFunctions). This connection is not exposed and is not explicitly cleaned by the script, rather by Roblox whenever the RemoteInstance is Destroyed.

---

## Dependencies

- [LemonSignal](<https://github.com/Data-Oriented-House/LemonSignal>)
- Please note: CoffeeRemotesRefined consists of two modules, one for Server-Side and one for Client-Side, both require the other one in order to work properly / be useful!

---

## 📜 License & Attribution

This module is licensed under the **Mozilla Public License 2.0 (MPL-2.0)**.

#### What this means for Roblox Developers:
* **Use & Modify:** You can freely use this module in any public, private, or commercial Roblox game.
* **File-Level Copyleft:** If you modify the source code of this module itself, you must make your modified version of the module publicly available under the MPL 2.0.
* **No Viral Code Leakage:** Including this module in your game does **not** force you to open-source your other game scripts, UI layouts, or proprietary codebase. 

See the full terms in the [LICENSE](LICENSE) file.

Attribution to all dependencies is included in [Notice](NOTICE)

Copyright © 2026 @Coffilhg (Roblox UserId 517222346)
