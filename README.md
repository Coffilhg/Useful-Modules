# ☕ CoffeeObjects

**CoffeeObjects** is a lightweight, in-memory data tree that mimics Roblox’s
`Folder` and `BaseValue` instances **without creating any Instances**.

It is designed for:

* datastore / ProfileStore–style data
* predictable change signals
* zero Workspace or Instance overhead

This library intentionally favors **explicitness, performance, and Roblox semantics** over abstraction.

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

---

## Destruction

Destroying a folder:

* disconnects all signals
* destroys all children recursively
* clears parent links
* removes the metatable

```luau
data:Destroy()
```

After destruction, the object is inert.

---

## 📜 License & Attribution

This project is licensed under **Apache License 2.0**.

It uses **GoodSignal** by Mark Langen (Stravant), which is MIT-licensed.

Attribution is preserved in the NOTICE file.

---

## Design Philosophy

* No observers
* No global update loop
* No hidden magic
* Roblox semantics first
* Explicit over clever

If you understand Roblox `Folder` + `BaseValue`, you already understand this library.