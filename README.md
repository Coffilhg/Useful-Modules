# Reaction
Simple lightweight reactivity core balancing memory and speed. Just Source (V), Effect (O) and Derive (C). No complicated graphs or scheduling.

The aim is to run with no dependencies and with as little implementation as possible so it can be used everywhere. This doesn't guarantee it's the best choice for every use case.

Since V1.1.0 it uses the Roblox' `task` library and doesn't replace it automatically if ran with, for example **lune**. The "everywhere" statement above was meant as in "everywhere inside of Roblox Studio", like without having to root, scope, mount or do whatsoever kind of complicated sorcery around the usage.

## Available Here!
- **[This repository](src/init.luau) ~ [src/init.luau](src/init.luau)**
- **[Wally](<https://wally.run/package/coffilhg/reaction>)**

    ```toml
    Reaction = "coffilhg/reaction@1.1.0"
    ```
- **[Rotriever](<https://github.com/Coffilhg/Useful-Modules/releases/tag/vReaction/1.1.0>)**

    ```toml
    Reaction = "github.com/Coffilhg/Useful-Modules@Reaction/1.1.0"
    ```

<!-- **[Creator Store](<https://create.roblox.com/store/category/gameplay?creatorName=coffilhg>)** ~ **[Reaction](<https://create.roblox.com/store/asset/123456789/Reaction>)**-->

---

## Features

- Generalized Reactive core - Source, Effect and Derive
- Easy to use (no root, mount or other sorcery required)
- Easy to modify, it's isn't hard to read the docs (this README) and a script less than 300 lines long. (And no dependencies too)

---

## Basic Usage

```luau
const Reaction = require(`./`)
const V, O, C, rmV, ifV, fiV = Reaction:Unpack()

-- Source (Value - V)
const BalanceUSD = V(10)
const RateUSDEUR = V(0.89)
-- Derive (Copy - C)
const BalanceEUR = C(function()
	return BalanceUSD() * RateUSDEUR()
end)
-- Effect (Observe - O)
local UpdateUSD: Reaction.Ou
UpdateUSD = O(BalanceUSD, function(value, isDestroyed)
	if isDestroyed then
		UpdateUSD() -- Disconnect from Updates
		print(`USD Balance unlinked; No further updates will be received.`)
		return
	end
	print(`USD Balance changed to {value}`)
end)
const UpdateEUR = O(BalanceEUR, function(value, isDestroyed)
	if isDestroyed then
		print(`EUR Balance unlinked; No further updates will be received.`)
		return
	end
	print(`EUR balance recomputed to {value}`)
end)

-- Earn 2 USD
BalanceUSD(BalanceUSD()+2)
-- USD Updated -> Triggers all USD observers in
-- original order, including internal Observers of C
-- BalanceEUR C was created before O(BalanceUSD, ...)
-- So we'll first see BalanceEUR recompute which will
-- trigger UpdateEUR O, then BalanceUSD O;
-- Output:
-- EUR balance recomputed to 10.68
-- USD Balance changed to 12

-- Destroy the Value
rmV(BalanceUSD)
-- All internal C observers will be disconnected
-- All further O(BalanceUSD, ...) will be ignored and return a dummy function that does nothing
-- All previously connected O' will however be able to listen to the changes
-- Recommended: Disconnect all explicit O's automatically when receiving isDestroying as true
print(BalanceUSD(123))
-- Output:
-- ~~USD Balance changed to 123~~ -- Won't show up because of UpdateUSD() on IsDestroyed (see above)
-- 123

-- So now BalanceEUR will only recompute whenever
-- other dependencies change, i.e. RateUSDEUR in this example
RateUSDEUR(RateUSDEUR() * 1.01)
-- EUR balance recomputed to 110.5647

-- If we destroy all of the Values a Copy (Derived Value) relies on,
-- The Copy (Derived Value) becomes a constant (though you can still use it as any usual V)
rmV(RateUSDEUR)

RateUSDEUR(1000) -- no effect on BalanceEUR

-- Using BalanceEUR as a usual Value
print("BalanceEUR:", BalanceEUR())
BalanceEUR(396)
print("Destroying BalanceEUR")
rmV(BalanceEUR)
print("Remember old O's can still get updates?")
BalanceEUR(1)
print("So disconnect them too!")
UpdateEUR()
BalanceEUR(3)
print(`Done :{BalanceEUR()}`)
```

---

## API

### **``Reaction:Unpack()``**
Returns all of the API as ordered below, example usage:
```luau
const V, O, C, rmV, ifV, fiV = Reaction:Unpack()
```

### **Value / "*Source*" ~ ``V<T>(val: T): V<T>``**
**val** is the initial value. Returns a function, that always returns the current value of the Value.

``type V<T> = (T?) -> (T)``

Provide a any kind of value or **nil** as the first argument to write. Leave empty to read.

The return is typed to always be T, but in reality there's no type equality, equality and nil checks. The return is just typed as T, because it's easier to use this way.

Every change fires all observers regerdless of equality. The value can be anything. Changes to mutable values stay undetected as long as you don't re-assign them.

Example usage:
```luau
const Health = V(100)

Health(90) -- write -- 90
print(Health()) -- read -- 90
print(Health(50)) -- write -- 50 -- writes return the current value too!

print(Health(Health()/2)) -- writes Health to be half of the previous value and prints the result
```

### **Observer / "*Effect*" ~ ``O<T>(V: V<T>, e: E<T>): Ou``**
**V** - the Value to be observed; **e** - callback firing on every change with the current value of **V** and ``true`` if it was destroyed by **rmV** (``type E<T> = (T, true?) -> ()``)

Returns the function to stop observing - "*Observer: unsee*"; You can call it multiple times, it only takes effect the first time, then does nothing.

If the given **V** was already destroyed by **rmV**, returns a dummy function that does nothing.

The callback **e** must never error/throw. If you need a pcall, you know it. This module aims for speed, so there's no pcall internally, you won't need it in most cases anyways, and when you do, you can do it inside the callback without sacrificing the speed for ordinary derivations.

You can add / remove Observers during such **e** callback, it's safe because the Observers of a Value are first snapshotted, then fired synchronously.

If you have already started observing the **V** and it gets destroyed by **rmV**, the second argument will be ``true``. This happens only once per the lifetime of a **V**, only the first time you destroy it using **rmV**, every subsequent call of **rmV(V)** doesn not fire the Observer, beause this data was already wiped during the first use of **rmV** on the module side - the only thing preventing the observer from being garbage collected is your own connection, so it is very recommended you disconnect them, however you still have the freedom of choice.

current value of **V** is auto-inferred as unknown; when you try to type it, the first autocomplete option is correct

Example usage:
```luau
const Health = V(100)

local HealthObserver
HealthObserver = O(Health, function(currentHealth: number, isDestroyed: true?)
    if isDestroyed then
        print(`HP Value destroyed, disconnecting from further updates.`)
        HealthObserver() -- Disconnects the observer
    end
    print(`HP = {currentHealth}`)
end)

for i = 1, 10 do
    Health(Health() - i)
end
rmV(Health)
rmV(Health) -- Nothing happens
rmV(Health) -- Nothing happens
Health(90) -- prints "HP = 90" only if you comment out ``HealthObserver() -- Disconnects the observer``
```

### **Copy "*Derive*" ~ ``C<T>(c: () -> (T)): V<T>``**
**c** - callback that determines the derived value. This callback is called on creation (**c** is an IIFE) and on every change of an active dependency. Reconciles the active dependencies on every recompute. Tracks dependencies automatically and dynamically.

The callback must never depend on task.spawn'ed (or alike) results unless you yield them and return synchronously (e.g. you can safely use RemoteFunctions, because they yield!)

The callback **c** must never error/throw. If you need a pcall, you know it. This module aims for speed, so there's no pcall internally, you won't need it in most cases anyways, and when you do, you can do it inside the callback without sacrificing the speed for ordinary derivations.

> i.e. Errors are not caught internally; use pcall inside the callback when necessary.

> Manages Observers for the dependencies automatically internally, this can alter the firing order of Observers for some or all of the dependencies, this depends on the setup, read **Notes** section below.

Example usage:
```luau
const ValueOne = V(3)
const ValueTwo = V(11)

const ValueThree = C(function()
	return ValueOne() * ValueTwo()
end)

print(ValueThree()) -- 33
ValueOne(5)
print(ValueThree()) -- 55

-- Technically possible, not recommended:
ValueThree(1) -- is not the result of the given function' return value
print(ValueThree()) -- 1
```

**Dependencies are resolved automatically and dynamically, so Dynamic dependency switching is supported!** e.g.:
```luau
local UseA = V(true)
local A = V(10)
local B = V(20)

local Selected = C(function()
    return if UseA() then A() else B()
end)

UseA(false) -- Selected now depends on UseA plus B, not UseA plus A
```

### **rmV ~ ``rmV<T>(V: V<T>)``**
Remove Value ("*``:Destroy()`` Source*")

Can be called many times on the same **V** value, only the first time makes reasonable changes, every further use only reads and wipes the internal tables regarding **V** value again.

"Destroys" the given **V** value
- Calls the cleanup, if it was a **C** kind of value
- Wipes the ``Cleanups[``**V**``]`` entry
- If ``Reactions[``**V**``]`` exists it contains all of the Observers for this **V**, a snapshot is taken and each Observer is notified with ``(``**V**``(), true)``
- Wipes the ``Reactions[``**V**``]`` entry and then also the ``Cells[``**V**``]`` roght after

After the given **V** value is already "Destroyed"
- You can still use the **V** value, read and write to it.
- Previously created Observers for the **V** value receive a one time notice "isDestroyed" (second argument) is ``true`` (it's recommended you disconnect it so it's garbage collected), afterwards you can still receive changes, but you will never receive the "isDestroyed" notice again.
- You can still use the **V** value as a dependency for **C**, but **V**'s updates will not trigger **C** to recompute, only if **C** recomputes because of another dependency change, will it intake the newest value of **V**

### **ifV ~ ``ifV<T>(V: V<T>): boolean``**
"if Value" returns whether you can still use (add new) observers on the value. Answer the question: "Was the value **V** never **rmV**'ed?"

### **fiV ~ ``fiV<T>(V: V<T>): boolean``**
"fi Value" the counterpart to **ifV**. Returns whether the value was removed ("Destroyed") using **rmV**

---

## Notes

- If anything. This module was designed as a Reactive core with aim for Speed, Simplicity and Versatlity. It works exactly as I designed it to, mostly for my own use, but it's fairly easy to read into it and make your own changes ~ have fun!
> *"exactly as I designed it to"* ~ the way of how I'd expect any Reactive core to work, like I don't get the ``Vide.effect`` - isn't that almost the same as ``Vide.derive``, in my opinion an effect should react to a single source, etc. etc. personal opinions

- Observer order is deterministic, however, every disconnected Observer switches places with the last (top) one to keep the speed and preserve the order. Here's an example of that:
```lua
-- Ordering documentation
-- Example of how the deterministic order works
const N = V(0)
const A = O(N, function(v, is)
    print(`A: {v}; Destroyed: {is};`)
end)
const B = O(N, function(v, is)
    print(`B: {v}; Destroyed: {is};`)
end)
const C = O(N, function(v, is)
    print(`C: {v}; Destroyed: {is};`)
end)
const D = O(N, function(v, is)
    print(`D: {v}; Destroyed: {is};`)
end)

print(`Expect ABCD`)
N(N() + 1)
-- ABCD order expected
A() -- Switches places with the last connected O
-- The order becomes DBCA (and A is removed) so
-- new order is DBC
print(`Expect DBC`)
N(N() + 1)
-- Current order -> switch disconnected with last -> last erased
B() -- DBC -> DCB -> DC
print(`Expect DC`)
N(N() + 1)

-- cleanup
-- btw cleaning up C, then D might be faster than D, then C
C()
D()
print(`Ordering learned!`)
```

---

## Benchmarks
Benchmark results can be seen **[here at Benchmarks/Results.md](Benchmarks/Results.md)**. ~~Currently they only cover **Reaction**'s own speed. Benchmarks for comparison are planned with Vision, Vide, Fluid and Seam.~~

Benchmarks now cover Vide and Vision too. They were ai-generated, then human-audited and slightly edited. The initial Benchmark for Reaction was human made.

Looks like it's better to only compare Reaction, Vide and Vision.

---

## DEPENDENCIES (if any)

- None `:3`

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