# Arrangement

`Arrangement` is a lightweight utility for **assigning stable integer IDs to arbitrary keys** and resolving them back when needed.

At its core, it is a deterministic, read-only key ↔ index mapper.

---

## What It Does

- Any unique key is assigned a **monotonically increasing integer**
- The same key always resolves to the same index
- Indices can be reversed back into their original keys
- All internal state is protected (read-only by design)

This makes `Arrangement` suitable anywhere you want to:
- Replace repeated values with compact identifiers
- Cache or synchronize identifiers across systems
- Decouple *what something is* from *how it is transmitted or stored*

---

## Example Use Case (Server ↔ Client Replication)

One (of the many possible) practical use case is **reducing high-frequency remote traffic**.

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

---

## API

### `Arrangement.new() → Arrangement`

Creates a new Arrangement instance.

### `Arrangement[key] → number`

Returns the index for a key.
Creates a new one if it doesn’t exist. (Starts with 0)

### `Arrangement:GetKeyByIndex(index) → key`

Resolves an index back to its original key.

---

## Notes

* Indexing starts at **0**
* Keys are stored exactly as provided
* Lifetime and synchronization strategy are intentionally left to the user

---

## License

Licensed under the Apache License, Version 2.0.

You may use, modify, and redistribute this module freely, provided that the original
copyright notice and license header at the top of the file are preserved.

See the [Apache License 2.0](LICENSE) for full terms.

© 2026 Coffilhg