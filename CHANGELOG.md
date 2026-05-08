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