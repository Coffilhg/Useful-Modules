# ☕ CoffeeObjects

**CoffeeObjects** is a lightweight, in-memory data tree that mimics Roblox’s
`Folder` and `BaseValue` instances **without creating any Instances**.

It is designed for:

* datastore / ProfileStore–style data
* predictable change signals
* zero Workspace or Instance overhead

This library intentionally favors **explicitness, performance, and Roblox semantics** over abstraction.

---

## Available Here!
- **[This repository](src/init.luau) ~ [src/init.luau](src/init.luau)**
- **[Wally](<https://wally.run/package/coffilhg/coffeeobjects>)**

    ```toml
    CoffeeObjects = "coffilhg/coffeeobjects@2.3.5"
    ```
- **Rotriever**

    ```toml
    CoffeeObjects = "github.com/Coffilhg/Useful-Modules@CoffeeObjects/2.3.5"
    ```
<!-- **[Creator Store](<https://create.roblox.com/store/category/gameplay?creatorName=coffilhg>)** ~ **[CoffeeObjects](<https://create.roblox.com/store/asset/1234567890/CoffeeObjects>)**-->

---

## Features

* `CoffeeFolder` - virtual equivalent of `Folder`
* `CoffeeBaseValue` - virtual equivalent of `BaseValue`
* Supports most Roblox primitive datatypes (`CFrame`, `Color3`, `Vector3`, etc.)
* `ChildAdded`, `ChildRemoved`, `Destroying` and `Changed` signals (via GoodSignal by Stravant)
* Automatic wrapping:

  * primitives → `CoffeeBaseValue`
  * tables → `CoffeeFolder`
* Deterministic tree paths via `GetPath()`
* Deterministic recursive destruction

---

## Installation

1. Copy the module into your project
2. Include **GoodSignal**
   [https://github.com/stravant/goodsignal](https://github.com/stravant/goodsignal)
3. Require the module:

```luau
local CoffeeObjects = require(path.To.CoffeeObjects)
```

---

## Basic Usage

### Creating folders and values

```luau
local CoffeeFolder = CoffeeObjects.CoffeeFolder
local CoffeeBaseValue = CoffeeObjects.CoffeeBaseValue

local data = CoffeeFolder.new({
	Stats = {
		Honey = 0,
		Level = 5,
	},
	Inventory = {
		"Sword",
		"Shield",
	},
})
```

Everything is wrapped automatically.

---

### Reading & writing values

```luau
print(data.Stats.Honey.Value) -- number: 0

data.Stats.Honey.Value = 10
```

### Listening for changes

```luau
data.Stats.Honey.Changed:Connect(function(old, new)
	print(old, "→", new)
end)
```

---

## Internal Fields (`_` prefixed)

> **The underscore (`_`) prefix is a convention, that such fields are private to the object itself and shall not be used by any other means.**

Fields prefixed with `_` are internal runtime state and are not part of the public API. Although you can use them, it is NOT recommended to - only use if you really know what you're doing!

The internal fields have an export type definition if you ever truly need those. Can be used via type intersections, e.g.: `CoffeeBaseValue & CoffeeBaseValueInternals<SupportedTypesList>`

---

### Child signals

```luau
data.ChildAdded:Connect(function(key, child)
	print("Added:", key)
end)

data.ChildRemoved:Connect(function(key)
	print("Removed:", key)
end)
```

---

## Paths

Every object knows where it lives in the tree:

```luau
print(data.Stats.Honey:GetPath())
-- { "Stats", "Honey" }
```

Paths are reconstructed via parent references - no global registry.
Keep that in mind when making a DeepCopy() - ignore "_parent" key when it's a CoffeeBaseValue or CoffeeFolder. Use `.validateClass(CoffeeObject)` and `validateUnlinkedClass(CoffeeObject)` methods for checking!

---

## Arrays vs Dictionaries

`CoffeeFolder` distinguishes **array-like** folders from dictionaries using Roblox semantics:

```luau
print(#data.Inventory, data.Inventory:_IsArrayORTuple())
-- 2, true

print(#data.Stats, data.Stats:_IsArrayORTuple())
-- 0, false
```

### Inserting into arrays

```luau
data.Inventory:Insert("Potion")
```

Attempting to insert into a dictionary will warn and do nothing.

---

## ⚠️ Important Behavior Notes

### Overwriting keys now ALWAYS fires signals by default

When you overwrite an existing key or index in a `CoffeeFolder`:

```luau
data.Stats.Honey = 25
```

* First the `ChildRemoved` **fires**
* Then the `ChildAdded` **fires**
* The old object **is destroyed**

This behavior is **intentional and NOT configurable**.
**If you want to avoid such behavior**, do this:

```luau
-- instead of overwriting the index as in example above (data.Stats.Honey = 25)
-- use the API!
data.Stats.Honey.Value = 25
```

---

### `validateUnlinkedClass` is intentionally permissive

Functions like:

```luau
CoffeeBaseValue.validateUnlinkedClass(v)
CoffeeFolder.validateUnlinkedClass(v)
```

exist to support:

* deep copies
* reconciliation
* lost metatables

⚠️ **They are easy to spoof by design.**

If you want stricter validation, you can add a marker:

```luau
rawset(self, "__coffee", "BaseValue")
-- or
rawset(self, "__coffee", "Folder")
```

...and update `validateUnlinkedClass` accordingly.

This is left to the consumer on purpose to avoid opinionated constraints.

### Internal `_Destroying` signal

CoffeeObjects now uses (Folders now listen to) an internal `_Destroying` signal to ensure safe unlinking
from parent structures before the public `Destroying` signal fires.

This guarantees:
- no stale references in `CoffeeFolder` if `:DisconnectAll()` was called on `Destroying`
- safe `:DisconnectAll()` behavior
- consistent destruction ordering

---

## Destruction

Destroying a folder:

* `_Destroying` fires before `Destroying` (internal use for safe unlinking)
* disconnects all signals
* destroys all children recursively
* clears parent links
* removes the metatable

```luau
data:Destroy()
```

After destruction, the object is inert.

If you understand Roblox' `Folder` and `BaseValue`, you already understand this library.

---

## 📜 License & Attribution

This project is licensed under **Apache License 2.0**.

It uses **GoodSignal** by Mark Langen (Stravant), which is MIT-licensed.

Attribution is preserved in the NOTICE file.