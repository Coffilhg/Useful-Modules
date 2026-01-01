# ☕ CoffeeRemotes

CoffeeRemotes multiplexes events through **one shared Remote per type**, keyed by `eventName`. It is **not** a wrapper around Instances per event.

---

## Features

* **Chainable API** (`:SetCooldown():Connect()`)
* **Legacy-compatible API surface**
* **Supports UnreliableRemoteEvent**

---

## Installation

1. Place **CoffeeRemotesServer** in `ServerScriptService`
2. Place **CoffeeRemotesClient** where needed on the client
3. Ensure **GoodSignal** ([https://github.com/stravant/goodsignal](https://github.com/stravant/goodsignal)) is available as a dependency
4. Require the server module **once** on startup (required for client to load successfully)

```lua
-- Server
local CoffeeRemotes = require(path.to.CoffeeRemotesServer)
```

This automatically creates the shared remotes in `ReplicatedStorage`:

* `CoffeeRemotes_Event`
* `CoffeeRemotes_Function`
* `CoffeeRemotes_Unreliable`

Now you can load the client side.

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

## Replacing Legacy RemoteEvents

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

It's just as simple as replacing `RS:WaitForChild("ExampleRemoteEvent")` to a corresponding remote type .new (e.g. `CoffeeRemotes.RemoteEvent.new("ExampleRemoteEvent")`). All of the other old code is supported by the API.

**Important:**
You must migrate **both server and client** to CoffeeRemotes.

Legacy Instances are no longer used.

---

## Legacy Compatibility Notes

To ease migration, CoffeeRemotes exposes legacy-like fields:

* `RemoteEvent.OnServerEvent`
* `RemoteEvent.OnClientEvent`
* `RemoteFunction.OnServerInvoke`
* `RemoteFunction.OnClientInvoke`

These exist **only for autocomplete and migration**. They point back to the object itself (**self**).

⚠️ **Do not use them in new code.**
They forward internally but can cause confusing autocomplete.

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

Only two return values are expected: a success boolean and a single result value.
So if you were to setup something like:

```lua
CoffeeRemotes.RemoteFunction
	.new("Example")
	.OnServerInvoke = function(player : Player)
		return true, player.UserId, player.DisplayName
	end
```
then the following
``print(CoffeeRemotes.RemoteFunction.new("Example"):InvokeServer())``
would only print **true, player.UserId**; **player.DisplayName** wouldn't be received.

---

## Cooldowns

Cooldowns are **per eventName per player**.

Defaults:

* `RemoteEvent` → `0.03s`
* `RemoteFunction` → `0.03s`
* `UnreliableRemoteEvent` → `0.01s`

```lua
CoffeeRemotes.RemoteEvent
	.new("JumpRequest")
	:SetCooldown(0.25) -- this does a warning, because no :Connect was called yet.
	-- :Connect returns a Connection, so you can't chain further. Just ignore the
	-- warning, since you've created the Remote already. If this gets annoying, just
	-- set DoWarningForSettingCooldownToNonexistentEvent to false on Server side.
```

Setting cooldowns on nonexistent/not connected events:

* warns in Studio
* silent in production

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

## 📜 License & Attribution

This project is licensed under **Apache License 2.0**.

It uses **GoodSignal** by Mark Langen (Stravant), which is MIT-licensed.

Attribution is preserved in the NOTICE file.

---

CoffeeRemotes is for developers who dislike Remote clutter.
**CoffeeRemotes** - fewer Instances, more control.