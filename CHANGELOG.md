# v2.3.5
- Patch `script.Parent.Packages.{DepenedencyModuleName}` -> `script.Parent.{DepenedencyModuleName}`

# v2.3.4
- Dependencies:
    - Swap **[PerfectSignal](<https://github.com/Coffilhg/PerfectSignal>)** for **[LemonSignal](<https://github.com/Data-Oriented-House/LemonSignal>)**
    - Update `CoffeeParser = "coffilhg/coffeeparser@1.0.3"` to `CoffeeParser = "coffilhg/coffeeparser@1.0.*"`
- Optimizations:
    - Switch all `pairs()` to generalized iteration
    - Ditch assert
    - Reverse via `table.insert(path, 1, ...)` in `GetPathMethod` O(n²) changed to a custom implementation of reverse O(n)
    - Instead of firing `__iter` by `for _ in self do` in `IsArrayORTupleMethod` now using `next(rawget(self, "_data"))` instead
    - Fixed Double-indexing on the Destroy checks
- **Architectural Decision Note:**:
    > Tried to achieve reduced memory usage by moving all previously rawset methods onto the metatables. However dispatching the methods will now be 2x-3x slower.
    > to achieve that `Folder.__index` was changed, it'll now first evaluate the metatable
    > **Verdict:** Not worth it. 0.8% less memory usage, but 2.8x slower method dispatch. Reverted.
    > **[Benchmarks and a backup can be found here](<https://github.com/Coffilhg/Useful-Modules/tree/CoffeeObjects/src/Tests/Memory234>)**

# v2.3.3
- `SupportedTypes` lookup table and `SupportedTypesDebugMessage` are now provided by CoffeeParser, just like the SupportedTypesList type previously
- Added internal `_Destroying` Signal, this now allows you to use `Destroying` however you want to - you can now `:DisconnectAll` and there'll be no dead reference to this object in a CoffeeFolder once it's destroyed, bcause it's now handled by `_Destroying` instead!
- Split type definitions into Public (default) and Private (internal) to remove internal fields from the autocomplete.

# v2.3.1 and v2.3.2

## Wally Re-Publish
- v2.3.0 wally.toml was misconfigured, the published version contains no init.luau

# v2.3.0

## Wally Compatible Again
- New Wally release
- Supported types are now directly inherited from CoffeeParser
- Using PerfectSignal - successor of previously used GoodSignal

# v2.2.2

## `__len` Rollback to default Roblox Luau `#` proxy
- `Folder:__len` is back to using `#` - acting as a proxy for the inner Folder' `_data`. Looks like the attempts to fix quirks of the default `#` might be incompatible if you want to use CoffeeObjects into some system you're using already; - Previous `__len` implementation wasn't perfect either.
- If you'd like to experiment with having a truly "perfect" `__len` behavior, here:
```lua
function Folder:__len()
    local data = rawget(self, "_data")
    
    if next(data) == nil then
        -- skip empty tables
        return 0
    end
    
    local count = 0
    local maxInt = 0
    
    for k in pairs(data) do
        if type(k) ~= "number" or k % 1 ~= 0 or k < 1 then
            return 0 -- non-integer or non-positive key → definitely a dictionary
        end
        count += 1
        if k > maxInt then maxInt = k end
    end

    if count ~= maxInt then
        return 0 -- sparse array, decide whether this should return 0
    end
    
    return count
end
```