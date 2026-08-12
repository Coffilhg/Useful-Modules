# Arrangement

`Arrangement` is a lightweight utility for **assigning stable integer IDs to arbitrary keys** and resolving them back when needed.

At its core, it is a deterministic, key ↔ index mapper.

> index / indices / id / identifier - refer to the same concept - the return value of `Arrangement[key]`

---

## Available Here!
- **[This repository](src/init.luau) ~ [src/init.luau](src/init.luau)**
- **[Wally](<https://wally.run/package/coffilhg/arrangement>)**

    ```toml
    Arrangement = "coffilhg/arrangement@2.0.0"
    ```
- **[Rotriever](<https://github.com/Coffilhg/Useful-Modules/releases/tag/vArrangement/2.0.0>)**

    ```toml
    Arrangement = "github.com/Coffilhg/Useful-Modules@Arrangement/2.0.0"
    ```

## What It Does

- Any unique key is assigned a **monotonically increasing integer**
- The same key always resolves to the same index (as long as it is not removed by you)
- Indices can be reversed back into their original keys
- All internal state is protected from direct modification

This makes `Arrangement` suitable anywhere you want to:
- Replace repeated values with compact identifiers
- Cache or synchronize identifiers across systems
- Decouple *what something is* from *how it is transmitted or stored*

---

## Example Use Case (Server ↔ Client Replication)

One (of the many possible) practical use cases is **reducing high-frequency remote traffic**.

Instead of repeatedly sending long strings or table paths:

```luau
--- Server-side ---
--onValueChangedCallback(newValue)
local valuePath = "Currencies.Main" -- ~15 bytes (string) + roblox built in headers
ValueUpdateRemoteEvent:FireClient(player, valuePath, newValue)
```

Below is one possible example flow:

**Server**

* Resolves a path using `Arrangement[key]`
* Sends only the integer index + payload

```luau
local ValuePathArrangements = Arrangement.new()
--- your code ---
--onValueChangedCallback(newValue)
local valuePath = ValuePathArrangements["Currencies.Main"] -- fixed 8 bytes (number) + roblox built in headers
ValueUpdateRemoteEvent:FireClient(player, valuePath, newValue)
```

**Client**

* If the index is known → resolve instantly
* If unknown → request the decoded key once and cache it

```luau
--- Client-side ---
local ValuePathArrangementsCache = {}

ValueUpdateRemoteEvent.OnClientEvent:Connect(function(valuePathIndex, newValue)
    if not ValuePathArrangementsCache[valuePathIndex] then
        ValuePathArrangementsCache[valuePathIndex] = GetPathArrangementRemoteFunction:InvokeServer(valuePathIndex)
    end
    --- your logic to apply the newValue (or abort this call, if you received same valuePathIndex again, whilst waiting for Invocation result);
end)
```

```luau
--- Server-side ---
GetPathArrangementRemoteFunction.OnServerInvoke = function(player : Player, index : number)
    -- add your own logic to protect yourself from misinput index (not number type, inf, NaN)
    return ValuePathArrangements:GetKeyByIndex(index)
end
```

This turns variable-sized identifiers into **fixed-size integers** while keeping the mapping deterministic.
The same key will always resolve to the same index for the lifetime of the Arrangement instance.

---

## Why This Matters

* Integers are smaller and cheaper to transmit than most strings
* Repeated identifiers benefit the most
* Lookup cost is constant and predictable

---

`Arrangement` does **not** enforce a specific workflow.

You could use it for anything you come up with.

If you can benefit from **"assign once, reuse forever" ids**, it likely fits.

> **You can reuse an assigned id for as long as its key remains in the Arrangement. Removing the key invalidates its previous id**

---

## API

### `Arrangement.new() → Arrangement`

Creates a new Arrangement instance.

### `Arrangement[key] → number`

Returns the index for a key.

Creates a new one if it doesn’t exist. (Starts with 1)

`Arrangement[nil]` is an exception and always returns 0

### `Arrangement:GetKeyByIndex(index) → key?`

Resolves an index back to its original key.

`Arrangement:GetKeyByIndex(0) → nil` (since `nil` is an exception)

### `Arrangement:RemoveArrangementByKey(key)`

Removes the key from the Arrangement, invalidating its previous id

You should be careful, because using `Arrangement:GetKeyByIndex` with the previously valid index will now return `nil`, because the entry was removed.

Make sure nothing still references it before wiping

Can be achieved by doing `Arrangement[key] = nil`

**Removed ids are never reused.**

### `Arrangement:RemoveArrangementByIndex(index)`

Removes the key entry associated with the given index

Effectively the same as:
```lua
Arrangement:RemoveArrangementByKey(
    Arrangement:GetKeyByIndex(index)
)
```

---

## Compact test

```lua
local FruitArrangements = Arrangement.new()

local AppleId = FruitArrangements.Apple
print(AppleId) -- 1

local WatermelonId = FruitArrangements.Watermelon
print(WatermelonId) -- 2
print(FruitArrangements.Apple) -- 1

FruitArrangements:RemoveArrangementByKey("Apple") -- wipe Apple
print(FruitArrangements:GetKeyByIndex(AppleId)) -- nil (no longer there)
print(FruitArrangements.Apple) -- 3

FruitArrangements.Watermelon = nil -- same as FruitArrangements:RemoveArrangementByKey("Watermelon")
print(FruitArrangements.Watermelon) -- 4
print(FruitArrangements:GetKeyByIndex(4)) -- "Watermelon"

FruitArrangements:RemoveArrangementByIndex(4)
print(FruitArrangements:GetKeyByIndex(4)) -- nil



-- nil
print(FruitArrangements[nil]) -- 0
print(FruitArrangements:GetKeyByIndex(0)) -- nil

FruitArrangements:RemoveArrangementByKey(nil) -- the only case when these methods do nothing
FruitArrangements:RemoveArrangementByIndex(0) -- the only case when these methods do nothing

print(FruitArrangements[nil]) -- 0
print(FruitArrangements:GetKeyByIndex(0)) -- nil
```

---

## Notes

* Indexing starts at **1**
* Keys are stored exactly as provided
* Lifetime and synchronization strategy are intentionally left to the user
* `nil` is an exception, never an entry and always returns 0
    > Trying to remove it does nothing because it is never stored; it is handled as a special case
    ```lua
    Arrangement:RemoveArrangementByKey(nil) -- does nothing
    Arrangement:RemoveArrangementByIndex(0) -- does nothing
    ```
* Removed ids are never reused

---

## License

This module is licensed under the **Mozilla Public License 2.0 (MPL-2.0)**.

#### What this means for Roblox Developers:
* **Use & Modify:** You can freely use this module in any public, private, or commercial Roblox game.
* **File-Level Copyleft:** If you modify the source code of this module itself, you must make your modified version of the module publicly available under the MPL 2.0.
* **No Viral Code Leakage:** Including this module in your game does **not** force you to open-source your other game scripts, UI layouts, or proprietary codebase. 

See the full terms in the [LICENSE](LICENSE) file.

Copyright © 2026 @Coffilhg (Roblox UserId 517222346)