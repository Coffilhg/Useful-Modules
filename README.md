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
    CoffeeObjects = "coffilhg/coffeeobjects@2.3.6"
    ```
- **Rotriever**

    ```toml
    CoffeeObjects = "github.com/Coffilhg/Useful-Modules@CoffeeObjects/2.3.6"
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

```lua
local CoffeeObjects = require(path.To.CoffeeObjects)
```

---

## Basic Usage

### Creating folders and values

```lua
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

```lua
print(data.Stats.Honey.Value) -- number: 0

data.Stats.Honey.Value = 10
```

### Listening for changes

```lua
data.Stats.Honey.Changed:Connect(function(old, new)
	print(old, "→", new)
end)
```

### Mutable value changes are not detected

**`.Changed` only fires when the `.Value` property is assigned. Mutating the object currently stored in `.Value` does not fire `.Changed`.**

Assignments to `.Value` fire `.Changed`, including compound assignments such as `+=`, `*=`, `/=`, `-=`.

You can manually fire `.Changed` after mutating a value, but be aware that `old == new` may still be true if both arguments reference the same mutable object or the arguments you've passed to `.Changed:Fire(old, new)` are the same value.

<details>

<summary><strong>Example with buffer</strong></summary>

```lua
local function ReadBinary(bufferToRead: buffer, startBit: number, endBit: number): string
	if startBit == endBit then
		return `{buffer.readbits(bufferToRead, startBit, 1)}`
	end
	if startBit > endBit then
		local originalEnd: number = endBit
		endBit = startBit
		startBit = originalEnd
	end

	local result = {}

	for i = startBit, endBit do
		table.insert(result, buffer.readbits(bufferToRead, i, 1))
	end

	return table.concat(result, "")
end

local function ReadAllBinary(bufferToRead: buffer): string
	return ReadBinary(
		bufferToRead,
		0,
		buffer.len(bufferToRead)*8 - 1 -- buffers are 0-indexed
	)
end

-- type is automatically CoffeeObjects.CoffeeBaseValueStrict<buffer>
-- because we are using the strictNew
local BufferValue = CoffeeBaseValue.strictNew(buffer.create(3))

BufferValue.Changed:Connect(function(old, new)
	local isTheSame = old == new -- this will always be true with approach #1
	local oldBinary = ReadAllBinary(old)
	local newBinary = ReadAllBinary(new)
	
	print(`{isTheSame}\nOld: {oldBinary}\n |\n\\ /\nNew: {newBinary}`)
end)

-- approach #1: you could change the buffer and Fire the signal!
buffer.writeu8(BufferValue.Value, 1, 255)
BufferValue.Changed:Fire(BufferValue.Value, BufferValue.Value)

-- approach #2: you could make a copy and change the .Value
local old = BufferValue.Value
local new = buffer.create(buffer.len(old))
buffer.copy(new, 0, old) -- make copy
buffer.writeu8(new, 2, 5) -- modify copy

BufferValue.Value = new -- update
```

if you run this, you'll see the following output for both approaches
```lua
  true
Old: 000000001111111100000000
 |
\ /
New: 000000001111111100000000
  false
Old: 000000001111111100000000
 |
\ /
New: 000000001111111110100000
```

</details>

<details>

<summary><strong>Example with CFrame</strong></summary>

```lua
local CFrameValue = CoffeeBaseValue.strictNew(CFrame.identity)

CFrameValue.Changed:Connect(function(old, new)
	print("Change detected:", old, "\t->\t", new)
end)

CFrameValue.Value:Lerp(CFrame.new(1, 0, 1), 0.5) -- stays undetected
print(CFrameValue.Value) -- although the CFrame changes

-- that is detected
CFrameValue.Value = CFrameValue.Value:Lerp(CFrame.new(0, 0, 0), 0.5)
```

</details>

<details>

<summary><strong>Example with Vector3</strong></summary>

```lua
local Vector3Value = CoffeeBaseValue.strictNew(Vector3.zero)

Vector3Value.Changed:Connect(function(old, new)
	print("Change detected:", old, "\t->\t", new)
end)

Vector3Value.Value += Vector3.new(1, 2, 3) -- detected --   Change detected: 0, 0, 0 	->	 1, 2, 3
Vector3Value.Value *= 3 -- detected --   Change detected: 1, 2, 3 	->	 3, 6, 9
Vector3Value.Value /= 2 -- detected --   Change detected: 3, 6, 9 	->	 1.5, 3, 4.5
Vector3Value.Value -= Vector3.new(5, 5, 5) -- detected --   Change detected: 1.5, 3, 4.5 	->	 -3.5, -2, -0.5
```

</details>

---

## Internal Fields (`_` prefixed)

> **The underscore (`_`) prefix is a convention, that such fields are private to the object itself and shall not be used by any other means.**

Fields prefixed with `_` are internal runtime state and are not part of the public API. Although you can use them, it is NOT recommended to - only use if you really know what you're doing!

The internal fields have an export type definition if you ever truly need those. Can be used via type intersections, e.g.: `CoffeeBaseValue & CoffeeBaseValueInternals<SupportedTypesList>`

---

### Child signals

```lua
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

```lua
print(data.Stats.Honey:GetPath())
-- { "Stats", "Honey" }
```

Paths are reconstructed via parent references - no global registry.
Keep that in mind when making a DeepCopy() - ignore "_parent" key when it's a CoffeeBaseValue or CoffeeFolder. Use `.validateClass(CoffeeObject)` and `validateUnlinkedClass(CoffeeObject)` methods for checking!

---

## Arrays vs Dictionaries

`CoffeeFolder` distinguishes **array-like** folders from dictionaries using Roblox semantics:

```lua
print(#data.Inventory, data.Inventory:_IsArrayORTuple())
-- 2, true

print(#data.Stats, data.Stats:_IsArrayORTuple())
-- 0, false
```

### Inserting into arrays

```lua
data.Inventory:Insert("Potion")
```

Attempting to insert into a dictionary will warn and do nothing.

---

## ⚠️ Important Behavior Notes

### Overwriting keys now ALWAYS fires signals by default

When you overwrite an existing key or index in a `CoffeeFolder`:

```lua
data.Stats.Honey = 25
```

* First the `ChildRemoved` **fires**
* Then the `ChildAdded` **fires**
* The old object **is destroyed**

This behavior is **intentional and NOT configurable**.
**If you want to avoid such behavior**, do this:

```lua
-- instead of overwriting the index as in example above (data.Stats.Honey = 25)
-- use the API!
data.Stats.Honey.Value = 25
```

---

### `validateUnlinkedClass` is intentionally permissive

Functions like:

```lua
CoffeeBaseValue.validateUnlinkedClass(v)
CoffeeFolder.validateUnlinkedClass(v)
```

exist to support:

* deep copies
* reconciliation
* lost metatables

⚠️ **They are easy to spoof by design.**

If you want stricter validation, you can add a marker:

```lua
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

```lua
data:Destroy()
```

After destruction, the object is inert.

If you understand Roblox' `Folder` and `BaseValue`, you already understand this library.

---

## DEPENDENCIES

- **[LemonSignal](<https://github.com/Data-Oriented-House/LemonSignal>)**
- **[CoffeeParser](<https://github.com/Coffilhg/Useful-Modules/tree/CoffeeParser>)**

---

## 📜 License & Attribution

This project is licensed under **Apache License 2.0**.

See the full terms in the [LICENSE](LICENSE) file.

Attribution is preserved in the [NOTICE](NOTICE) file.

Copyright © 2025 @Coffilhg (Roblox UserId 517222346)